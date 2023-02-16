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
    # Provides a class to handle and parse ABI events.
    # Inspired by ethereum.rb
    class Event
      attr_reader :contract, :name, :inputs
      attr_accessor :transaction

      def initialize(*args)
        @contract, @name, @inputs, *extra = args
        raise "Too many arguments" unless extra.empty?
      end

      def input_types
        inputs.map { |i| i['type'] }
      end

      def signature
        "#{name}(#{input_types.join(',')})"
      end

      def signature_digest
        '0x' + Digest::Keccak.hexdigest(signature, 256)
      end

      def decoded_args
        @decoded_args ||= decode_args
      end

      def decode_args
        decoded_arr = []
        index = 1
        inputs.select {|i| i['indexed']}.each do |input|
          decoded_arr << ::Eth::Abi.decode([input['type']], transaction['topics'][index])
          index +=1
        end

        data = transaction['data']
        if data
          decoded_arr += ::Eth::Abi.decode(inputs.reject {|i| i['indexed']}.map { |i| i['type'] }, data)
        end

        args_hash = {}
        inputs.each { |i|args_hash[i['name']] = decoded_arr.shift } unless decoded_arr.empty?
        args_hash
      end
    end
  end
end
