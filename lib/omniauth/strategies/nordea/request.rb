module OmniAuth
  module Strategies
    class Nordea
      class Request < Message
        SIGNED_KEYS = [
          'A01Y_ACTION_ID',
          'A01Y_VERS',      # 0002 (standard), 0003 (with additional data) or 0004.
          'A01Y_RCVID',
          'A01Y_LANGCODE',  # ET, LV, LT, EN
          'A01Y_STAMP',     # yyyymmddhhmmssxxxxxx
          'A01Y_IDTYPE',
          'A01Y_RETLINK',
          'A01Y_CANLINK',
          'A01Y_REJLINK',
          'A01Y_KEYVERS',
          'A01Y_ALG',       # 01 for md5, 02 for sha1
          'A01Y_MAC',
        ]

        def sign!(mac, hash_algorithm)
          @hash["A01Y_KEYVERS"] = "0001"
          @hash["A01Y_ALG"]     = ALGORITHM_NAMES.key(hash_algorithm)
          @hash["A01Y_MAC"]     = mac

          digester = find_digester(hash_algorithm)
          signable_string = SIGNED_KEYS.map { |k| @hash[k] }.join("&") + "&"
          @hash["A01Y_MAC"] = digester.hexdigest(signable_string).upcase

          self
        end
      end
    end
  end
end
