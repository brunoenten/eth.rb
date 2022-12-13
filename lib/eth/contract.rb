# Copyright (c) 2016-2022 The Ruby-Eth Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Provides the {Eth} module.
module Eth
  # The {Eth::Contract} class to handle smart contracts
  class Contract
    attr_reader :abi, :address, :client

    def initialize(_name, _abi, _address, _client, _sender)
      @abi = _abi
      @name = _name
      @address = _address
      @client = _client
      @sender = _sender
    end

    def functions
      @functions ||= abi.select {|e| e['type'] == 'function' and !e['name'].empty? }.map { |f| ::Eth::Abi::Function.new(self, f) }
    end

    def events
      @events ||= abi.select {|e| e['type'] == 'event' and !e['name'].empty? }.map { |f| ::Eth::Abi::Event.new(self, f['name'], f['inputs']) }
    end

    def method_missing(m, *args)
      function = functions.detect { |f| f.name == m.to_s}
      return super if function.nil?
      function.execute(*args)
    end

    def call(payload)
      client.call(@sender, self.address, payload)
    end

    def transact(payload)
      txHash = client.transact(@sender, self.address, payload)
      client.wait_for_tx(txHash)
      client.eth_get_transaction_receipt(txHash)['result']['status'] == '0x1' rescue true
    end

    def subscribe_to_event(event_name, fromBlock='latest', toBlock='latest')
      event = events.detect { |e| e.name == event_name.to_s}
      return false unless event

      client.eth_new_filter({
        fromBlock: fromBlock,
        toBlock: toBlock,
        address: Eth::Address.new(address),
        topics: [event.signature_digest]
      })['result']
    end

    def subscription_new_events(filter_id)
      client.eth_get_filter_changes(filter_id)['result'].map { |result| parse_event(result)}.compact
    end

    def subscription_all_events(filter_id)
      client.eth_get_filter_logs(filter_id)['result'].map { |result| parse_event(result)}.compact
    end

    def fetch_events(event_name, fromBlock='latest', toBlock='latest')
      event = events.detect { |e| e.name == event_name.to_s}
      return false unless event

      client.eth_get_logs({
        fromBlock: fromBlock,
        toBlock: toBlock,
        address: Eth::Address.new(address),
        topics: [event.signature_digest]
      })['result'].map { |result| parse_event(result)}.compact
    end

    def parse_event(event_hash)
      event = events.detect { |e| e.signature_digest == event_hash['topics'].first }
      return nil unless event

      event.transaction = event_hash
      event
    end
  end
end
