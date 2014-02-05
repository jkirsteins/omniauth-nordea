require 'digest/sha1'
require 'digest/md5'

module OmniAuth
  module Strategies
    class Nordea
      class ArgumentError < StandardError; end

      # 'A01Y_ACTION_ID',
      # 'A01Y_VERS', # 0002 (standard), 0003 (with additional data) or 0004.
      # => Only 0002 supported
      # 'A01Y_RCVID',
      # 'A01Y_LANGCODE', # ET, LV, LT, EN
      # 'A01Y_STAMP', # yyyymmddhhmmssxxxxxx
      # 'A01Y_IDTYPE',
      # 'A01Y_RETLINK',
      # 'A01Y_CANLINK',
      # 'A01Y_REJLINK',
      # 'A01Y_KEYVERS',
      # 'A01Y_ALG',     01 for md5, 02 for sha1
      # 'A01Y_MAC',

      ALGORITHM_NAMES = { "01" => :md5, "02" => :sha1 }
      SUPPORTED_LANG_CODES = [ :LV, :ET, :LT, :EN ]
      SUPPORTED_VERSIONS = [ "0002" ]

      class << self

        def callback_variation(callback_url, status)
          url = URI(callback_url)
          url.query = "omniauth_status=#{status}"
          url
        end

        # We're counting on receiving an ordered hash
        # This method
        def sign_hash_in_place(hash)

          signable_string = hash.values.join("&") + "&"

          digest_class =
            case ALGORITHM_NAMES[ hash["A01Y_ALG"] ]
            when :sha1
              Digest::SHA1
            when :md5
              Digest::MD5
          end

          hash["A01Y_MAC"] = digest_class.send(:hexdigest, signable_string)
        end

        def build_request_hash(rcvid, mac, callback_url, opts = {})
          opts = {
            algorithm: :sha1,
            version:   "0002",
            langcode:  :LV
          }.merge(opts)

          if !SUPPORTED_LANG_CODES.include?(opts[:langcode])
            raise ArgumentError.new (":langcode must be one of " + SUPPORTED_LANG_CODES.to_s)
          end

          if !ALGORITHM_NAMES.values.include?(opts[:algorithm])
            raise ArgumentError.new (":algorithm must be one of " + ALGORITHM_NAMES.values.to_s)
          end

          if !SUPPORTED_VERSIONS.include?(opts[:version])
            raise ArgumentError.new (":version must be one of " + SUPPORTED_VERSIONS.to_s)
          end

          {
            "A01Y_ACTION_ID" =>   "701",
            "A01Y_VERS" =>        opts[:version],
            "A01Y_RCVID" =>       rcvid,
            "A01Y_LANGCODE" =>    opts[:langcode],
            "A01Y_STAMP" =>       "yyyymmddhhmmssxxxxxx",
            "A01Y_IDTYPE" =>      "02",
            "A01Y_RETLINK" =>     self.callback_variation(callback_url, "success"),
            "A01Y_CANLINK" =>     self.callback_variation(callback_url, "cancelled"),
            "A01Y_REJLINK" =>     self.callback_variation(callback_url, "rejected"),
            "A01Y_KEYVERS" =>     "0001",
            "A01Y_ALG" =>         ALGORITHM_NAMES.key(opts[:algorithm]),
            "A01Y_MAC" =>         mac
          }
        end
      end
    end
  end
end