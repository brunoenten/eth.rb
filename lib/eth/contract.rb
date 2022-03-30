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
      client.eth_get_transaction_receipt(txHash)['result']['status'] == '0x1'
    end
  end
end
