require 'spec_helper'

RSpec.describe Straight::Order do

  class Straight::Order

    def status=(new_value)
      # we later make sure this method also gets called
      @original_status_setter_called = true
    end

  end

  before(:each) do
    @gateway = double("Straight Gateway mock")
    @order   = Straight::Order.new
    @order.amount      = 10
    @order.gateway     = @gateway
    @order.address     = 'address'
    @order.keychain_id = 1
    allow(@gateway).to receive(:order_status_changed).with(@order)
    allow(@gateway).to receive(:fetch_transactions_for).with(@order.address).and_return([{ tid: 'xxx'}])
  end

  it "follows status check schedule" do
    allow(@gateway).to receive(:fetch_transactions_for).with('address').and_return([])
    allow(@gateway).to receive(:status_check_schedule).and_return(Straight::Gateway::DEFAULT_STATUS_CHECK_SCHEDULE)
    [10, 20, 40, 80, 160, 320, 640].each do |i|
      expect(@order).to receive(:sleep).with(i).exactly(6).times
    end
    @order.check_status_on_schedule
  end

  it "gets the last transaction for the current address, caches the request" do
    expect(@gateway).to receive(:fetch_transactions_for).with(@order.address).once.and_return(true)
    @order.transactions
    @order.transactions
  end

  it "gets all transactions for the current address, caches the request" do
    expect(@gateway).to receive(:fetch_transactions_for).with(@order.address).once.and_return(['t1', 't2'])
    expect(@order.transaction).to eq('t1')
    expect(@order.transaction).to eq('t1')
  end

  it "sets transaction id when the status is changed from 0" do
    @order.status = 2
    expect(@order.tid).to eq('xxx') # xxx because that's what we set in the allow() in before(:each) block
  end

  describe "assigning statuses" do

    before(:each) do
      allow(@gateway).to receive(:confirmations_required).and_return(1)
    end

    it "doesn't reload the transaction unless forced" do
      @order.instance_variable_set(:@status, 2)
      expect(@order).to_not receive(:transaction)
      @order.status
    end

    it "sets status to :new if no transaction issued" do
      expect(@order).to receive(:transaction).at_most(3).times.and_return(nil)
      expect(@order.status(reload: true)).to eq(0)
    end

    it "sets status to :unconfirmed if transaction doesn't have enough confirmations" do
      transaction = { confirmations: 0 }
      expect(@order).to receive(:transaction).at_most(3).times.and_return(transaction)
      expect(@order.status(reload: true)).to eq(1)
    end

    it "sets status to :paid if transaction has enough confirmations and the amount is correct" do
      transaction = { confirmations: 1, total_amount: @order.amount }
      expect(@order).to receive(:transaction).at_most(3).times.and_return(transaction)
      expect(@order.status(reload: true)).to eq(2)
    end

    it "sets status to :underpaid if the total amount in a transaction is less than the amount of order" do
      transaction = { confirmations: 1, total_amount: @order.amount-1 }
      expect(@order).to receive(:transaction).at_most(3).times.and_return(transaction)
      expect(@order.status(reload: true)).to eq(3)
    end

    it "sets status to :overderpaid if the total amount in a transaction is more than the amount of order" do
      transaction = { confirmations: 1, total_amount: @order.amount+1 }
      expect(@order).to receive(:transaction).at_most(3).times.and_return(transaction)
      expect(@order.status(reload: true)).to eq(4)
    end

    it "invokes a callback on the gateway when status changes" do
      transaction = { confirmations: 1, total_amount: @order.amount }
      allow(@order).to receive(:transaction).and_return(transaction)
      expect(@gateway).to receive(:order_status_changed).with(@order)
      @order.status(reload: true)
    end

    it "calls the original status setter of the class that the module is included into" do
      expect(@order.instance_variable_get(:@original_status_setter_called)).to be_falsy
      @order.status = 1
      expect(@order.instance_variable_get(:@original_status_setter_called)).to be_truthy
    end

  end

end
