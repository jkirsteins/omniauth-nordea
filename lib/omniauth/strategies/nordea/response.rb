module OmniAuth
  module Strategies
    class Nordea
      class Response < Message
        SIGNED_KEYS = [
          'B02K_VERS',      # 0002 (standard), 0003 (with additional data) or 0004.
          'B02K_TIMESTMP',
          'B02K_IDNBR',
          'B02K_STAMP',
          'B02K_CUSTNAME',
          'B02K_KEYVERS',
          'B02K_ALG',       # 01 for md5, 02 for sha1
          'B02K_CUSTID',
          'B02K_CUSTTYPE',
          'B02K_MAC'
        ]

        def validate!(mac)
          received_digest = @hash['B02K_MAC']

          h = @hash.dup
          h['B02K_MAC'] = mac

          digester = find_digester(ALGORITHM_NAMES[h['B02K_ALG']])
          signable_string = SIGNED_KEYS.map { |k| CGI.escape(h[k]) }.join("&") + '&'
          expected_digest = digester.hexdigest(signable_string).upcase

          if expected_digest != received_digest
            raise ValidationError, "Digest mismatch"
          end

          self
        end
      end
    end
  end
end
