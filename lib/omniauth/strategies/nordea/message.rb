require 'digest/sha1'
require 'digest/md5'

module OmniAuth
  module Strategies
    class Nordea
      class Message
        ALGORITHM_NAMES = { "01" => :md5, "02" => :sha1 }

        def initialize(hash)
          @hash = hash
        end

        def to_hash
          @hash
        end

        def each_pair(&block)
          @hash.each_pair(&block)
        end

        private

        def find_digester(hash_algorithm)
          case hash_algorithm
          when :sha1
            Digest::SHA1
          when :md5
            Digest::MD5
          end
        end
      end
    end
  end
end
