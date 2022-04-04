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

# -*- encoding : ascii-8bit -*-

# Provides the {Eth} module.
module Eth

  # Provides a Ruby implementation of the Ethereum Applicatoin Binary Interface (ABI).
  module Abi

    # Provides a class to handle and parse ABI functions.
    # Inspired by ethereum.rb
    class Function
      attr_reader :name, :inputs, :outputs, :contract, :stateMutability

      def initialize(_contract,data)
        @contract = _contract
        @name = data['name']
        @inputs = data['inputs']
        @outputs = data['outputs']
        @stateMutability = data['stateMutability']
      end

      def input_types
        inputs.map {|i| i['type']}
      end

      def signature
        "#{name}(#{input_types.join(",")})"
      end

      def signature_digest
        Digest::Keccak.hexdigest(signature, 256)[0..7]
      end

      def execute(*args)
        encoded_args = if args.empty?
          "0" * 64
        else
          ::Eth::Util.bin_to_hex ::Eth::Abi.encode(input_types, args)
        end

        payload = '0x' + signature_digest + encoded_args
        if ['view', 'pure'].include?(stateMutability)
          result = contract.call(payload)
          decoded = ::Eth::Abi.decode(outputs.map {|o| o['type']}, result)
          if outputs.count == 1
            return decoded.first
          else
            return decoded
          end
        else
          contract.transact(payload)
        end
      end
    end
  end
end