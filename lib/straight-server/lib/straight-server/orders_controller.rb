require_relative 'throttler'

module StraightServer

  class OrdersController
    include Goliath::Constants

    attr_reader :response

    JSON_HEADER = { 'Content-Type': 'application/json'.freeze }.freeze

    def initialize(env)
      @env          = env
      @params       = env.params
      @method       = env['REQUEST_METHOD']
      @request_path = env['REQUEST_PATH'].split('/').delete_if { |s| s.nil? || s.empty? }
      @response     = dispatch
    end

    def create
      validate_signature || throttle

      begin

        # This is to inform users of previous version of a deprecated param
        # It will have to be removed at some point.
        if @params['order_id']
          return [409, {}, "Error: order_id is no longer a valid param. Use keychain_id instead and consult the documentation."]
        end

        order_data = {
          amount:                    @params['amount'], # this is satoshi
          currency:                  @params['currency'],
          btc_denomination:          @params['btc_denomination'],
          keychain_id:               @params['keychain_id'],
          callback_data:             @params['callback_data'],
          data:                      @params['data'],
          description:               @params['description'],
          after_payment_redirect_to: @params['after_payment_redirect_to'],
          auto_redirect:             @params['auto_redirect']
        }

        order = @gateway.create_order(order_data)
        StraightServer::Thread.new(label: order.payment_id) do
          # Because this is a new thread, we have to wrap the code inside in #watch_exceptions
          # once again. Otherwise, no watching is done. Oh, threads!
          StraightServer.logger.watch_exceptions do
            order.start_periodic_status_check
          end
        end
        [200, JSON_HEADER, add_callback_data_warning(order).to_json]
      rescue Sequel::ValidationFailed => e
        StraightServer.logger.debug(
          "VALIDATION ERRORS in order, cannot create it:\n" +
            "#{e.message.split(",").each_with_index.map { |e, i| "#{i+1}. #{e.lstrip}" }.join("\n") }\n" +
            "Order data: #{order_data.inspect}\n"
        )
        [409, {}, "Invalid order: #{e.message}"]
      rescue Straight::Gateway::OrderAmountInvalid => e
        [409, {}, "Invalid order: #{e.message}"]
      rescue StraightServer::GatewayModule::GatewayInactive
        StraightServer.logger.debug "Order creation attempt on inactive gateway #{@gateway.id}"
        [503, {}, "The gateway is inactive, you cannot create order with it"]
      end
    end

    def show
      validate_signature(if_unforced: false)

      order = find_order

      if order
        order.status(reload: true)
        order.save if order.status_changed?
        [200, JSON_HEADER, order.to_json]
      end
    end

    def websocket
      ws = Faye::WebSocket.new(@env)

      if (order = find_order)
        if order.status >= 2
          ws.send order.to_json
          ws.close
        else
          @gateway.add_websocket_for_order(ws, order)
        end
      else
        ws.send('error: order not found')
        ws.close
      end

      ws.rack_response
    end

    def cancel
      validate_signature(if_unforced: false)

      if (order = find_order)
        order.status(reload: true)
        order.save if order.status_changed?
        if order.cancelable?
          order.cancel
          [204, { 'Content-Type': 'text/html' }, ' ']
        else
          [409, {}, "Order is not cancelable"]
        end
      end
    end

    def last_keychain_id
      [200, {}, { gateway_id: @gateway.id, last_keychain_id: @gateway.get_last_keychain_id }.to_json]
    end

    def invoice
      order = find_order
      if order
        payment_request = Bip70::PaymentRequest.new(order: order).to_s

        headers = {
          'Content-Type':              'application/bitcoin-paymentrequest',
          'Content-Disposition':       "inline; filename=i#{Time.now.to_i}.bitcoinpaymentrequest",
          'Content-Transfer-Encoding': 'binary',
          'Expires':                   '0',
          'Cache-Control':             'must-revalidate, post-check=0, pre-check=0',
          'Content-Length':            payment_request.length.to_s
        }

        [200, headers, payment_request]
      end
    end

    def reprocess
      validate_signature || throttle

      if (order = find_order)
        before = order.to_json
        begin
          order.reprocess!
        rescue => ex
          return [409, JSON_HEADER, %({"error":#{ex.message.inspect}})]
        end
        after = order.to_json
        [200, JSON_HEADER, %({"before":#{before},"after":#{after}})]
      end
    end

    private

      # Refactoring proposed: https://github.com/AlexanderPavlenko/straight-server/commit/49ea6e3732a9564c04d8dfecaee6d0ebaa462042
      def dispatch
        StraightServer.logger.blank_lines
        StraightServer.logger.info "#{@method} #{@env['REQUEST_PATH']}#{@params && !@params.empty? ? "\n#{@params.inspect}" : nil}"

        @gateway = StraightServer::Gateway.find_by_hashed_id(@request_path[1])
        raise Gateway::RecordNotFound if @gateway.nil?

        response =

          case "#{@method} #{@env['REQUEST_PATH']}"

            # POST /gateways/:gateway_hashed_id/orders
            #
            when %r{\APOST /gateways/([^/]+)/orders\Z}
              create

            # GET /gateways/:gateway_hashed_id/orders/:order_id
            # GET /gateways/:gateway_hashed_id/orders/:order_payment_id
            #
            when %r{\AGET /gateways/([^/]+)/orders/([^/]+)\Z}
              show

            # GET /gateways/:gateway_hashed_id/orders/:order_id/websocket
            # GET /gateways/:gateway_hashed_id/orders/:order_payment_id/websocket
            #
            when %r{\AGET /gateways/([^/]+)/orders/([^/]+)/websocket\Z}
              websocket

            # POST /gateways/:gateway_hashed_id/orders/:order_id/cancel
            # POST /gateways/:gateway_hashed_id/orders/:order_payment_id/cancel
            #
            when %r{\APOST /gateways/([^/]+)/orders/([^/]+)/cancel\Z}
              cancel

            # POST /gateways/:gateway_hashed_id/orders/:order_id/reprocess
            # POST /gateways/:gateway_hashed_id/orders/:order_payment_id/reprocess
            #
            when %r{\APOST /gateways/([^/]+)/orders/([^/]+)/reprocess\Z}
              reprocess

            # GET /gateways/:gateway_hashed_id/last_keychain_id
            #
            when %r{\AGET /gateways/([^/]+)/last_keychain_id\Z}
              last_keychain_id

            # GET /gateways/:gateway_hashed_id/orders/:order_id/invoice
            # GET /gateways/:gateway_hashed_id/orders/:order_payment_id/invoice
            #
            when %r{\AGET /gateways/([^/]+)/orders/([^/]+)/invoice\Z}
              invoice

            else
              raise RoutingError.new(@method, @env['REQUEST_PATH'])

          end

        # TODO: Remove it and use RecordNotFound for Order
        raise RoutingError.new(@method, @env['REQUEST_PATH']) if response.nil?

        response

      rescue RoutingError, Gateway::RecordNotFound => e
        StraightServer.logger.debug e.message
        [404, {}, e.message]
      rescue SignatureValidator::InvalidNonce
        message = "X-Nonce is invalid: #{@env["#{HTTP_PREFIX}X_NONCE"].inspect}"
        StraightServer.logger.debug "Gateway #{@gateway.id}, #{message}"
        [409, {}, message]
      rescue SignatureValidator::InvalidSignature
        message = "X-Signature is invalid: #{@env["#{HTTP_PREFIX}X_SIGNATURE"].inspect}"
        StraightServer.logger.debug "Gateway #{@gateway.id}, #{message}"
        [409, {}, message]
      rescue Throttler::RequestDenied => ex
        StraightServer.logger.debug ex.message
        [429, {}, "Too many requests, please try again later"]
      end

      def find_order
        id = @request_path[3]
        id =~ /\A\d+\Z/ ? Order[id.to_i] : Order[:payment_id => id]
      end

      def add_callback_data_warning(order)
        o = order.to_h
        if @params['data'].kind_of?(String) && @params['callback_data'].nil?
          o[:WARNING] = "Maybe you meant to use callback_data? The API has changed now. Consult the documentation."
        end
        o
      end

      def validate_signature(if_unforced: true)
        if @gateway.check_signature
          SignatureValidator.new(@gateway, @env).validate!
        elsif if_unforced
          SignatureValidator.new(@gateway, @env).valid_signature?
        end
      end

      def throttle
        ip = @env['HTTP_X_FORWARDED_FOR'].to_s
        ip = @env['REMOTE_ADDR'] if ip.empty?
        Throttler.new(@gateway.id).check!(ip)
      end
  end
end
