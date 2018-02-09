FactoryBot.define do
  factory :params, class: Hash do
    initialize_with { attributes }
  end

  factory :params_create_order, parent: :params do
    gateway_id { create(:gateway).hashed_id }
    amount 1

    trait :negative_amount do
      amount -1
    end

    trait :no_amount do
      amount ''
    end

    trait :with_data do
      data(hello: 'world')
    end

    trait :with_callback_data do
      callback_data 'some random data'
    end
  end

  factory :gateway, class: StraightServer::Gateway do
    to_create &:save
    name 'A'
    pubkey 'xpub6AH1Ymkkrwk3TaMrVrXBCpcGajKc9a1dAJBTKr1i4GwYLgLk7WDvPtN1o1cAqS5DZ9CYzn3gZtT7BHEP4Qpsz24UELTncPY1Zsscsm3ajmX'
    test_pubkey 'tpubDCzMzH5R7dvZAN7jNyZRUXxuo8XdRmMd7gmzvHs9LYG4w2EBvEjQ1Drm8ZXv4uwxrtUh3MqCZQJaq56oPMghsbtFnoLi9JBfG7vRLXLH21r'
    secret 'secret'
    order_class 'StraightServer::Order'
    default_currency 'BTC'
    exchange_rate_adapters %w[Bitpay Coinbase Bitstamp]
    confirmations_required 0
    orders_expiration_period 300
    active true
    test_mode true
    check_signature false
  end

  factory :order, class: StraightServer::Order do
    to_create &:save
    initialize_with { gateway.create_order(attributes.except(:gateway)) }
    gateway
    sequence :keychain_id
    amount 1
    # FIXME: why it gets mainnet address?

    trait :paid do
      after(:create) { |order|
        order.update status: 2, amount_paid: order.amount
      }
    end
  end
end