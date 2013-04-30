require 'omniauth'
require 'base64'
require 'omniauth/strategies/nordea/request_helpers'

module OmniAuth
  module Strategies
    class Nordea
      PRODUCTION_ENDPOINT = "https://netbank.nordea.com/pnbeid/eidn.jsp"
      TEST_ENDPOINT = "https://netbank.nordea.com/pnbeidtest/eidn.jsp"

      include OmniAuth::Strategy

      args [:rcvid, :mac]

      option :rcvid, nil
      option :mac, nil

      # Supported algorithms: :sha1 and :md5
      option :hash_algorithm, :sha1

      option :name, "nordea"
      option :endpoint, PRODUCTION_ENDPOINT

      def callback_phase
        super
      rescue Exception => e
        fail!(:unknown_callback_err, e)
      end

      def request_phase

        param_hash = OmniAuth::Strategies::Nordea.build_request_hash(options.rcvid, options.mac,
          full_host + script_name + callback_path)
        OmniAuth::Strategies::Nordea.sign_hash_in_place(param_hash)

        # Build redirect form
        OmniAuth.config.form_css = nil
        form = OmniAuth::Form.new(:title => "Please wait ...", :url => options.endpoint)

        param_hash.each_pair do |k,v|
          form.html "<input type=\"hidden\" name=\"#{k}\" value=\"#{v}\" />"
        end

        form.button "Click here if not redirected automatically ..."

        # form.instance_variable_set("@html",
        #   form.to_html.gsub("</form>", "</form><script type=\"text/javascript\">document.forms[0].submit();</script>"))
        form.to_response
      rescue Exception => e
        fail!(:unknown_request_err, e)
      end
    end
  end
end