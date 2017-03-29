require 'omniauth'
require_relative 'nordea/message'
require_relative 'nordea/request'
require_relative 'nordea/response'

module OmniAuth
  module Strategies
    class Nordea
      class ValidationError < StandardError; end

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

      uid do
        request.params["B02K_CUSTID"].dup.insert(6, "-")
      end

      info do
        {
          full_name: request.params["B02K_CUSTNAME"].split(" ").reverse.join(" ")
        }
      end

      extra do
        { raw_info: request.params }
      end

      def callback_phase
        if request.params["B02K_CUSTID"] && !request.params["B02K_CUSTID"].empty?
          message = OmniAuth::Strategies::Nordea::Response.new(request.params)
          message.validate!(options.mac)
          super
        else
          fail!(:invalid_credentials)
        end
      rescue ValidationError => e
        fail!(:invalid_mac, e)
      end

      def request_phase
        message = OmniAuth::Strategies::Nordea::Request.new(
          "A01Y_ACTION_ID" => "701",
          "A01Y_VERS"      => "0002",
          "A01Y_RCVID"     => options.rcvid,
          "A01Y_LANGCODE"  => "LV",
          "A01Y_STAMP"     => "yyyymmddhhmmssxxxxxx",
          "A01Y_IDTYPE"    => "02",
          "A01Y_RETLINK"   => callback_with_status_url("success"),
          "A01Y_CANLINK"   => callback_with_status_url("cancelled"),
          "A01Y_REJLINK"   => callback_with_status_url("rejected")
        )
        message.sign!(options.mac, options.hash_algorithm)

        # Build redirect form
        form = OmniAuth::Form.new(title: I18n.t("omniauth.nordea.please_wait"), url: options.endpoint)

        message.each_pair do |k,v|
          form.html "<input type=\"hidden\" name=\"#{k}\" value=\"#{v}\" />"
        end

        form.button I18n.t("omniauth.nordea.click_here_if_not_redirected")

        form.instance_variable_set("@html",
          form.to_html.gsub("</form>", "</form><script type=\"text/javascript\">document.forms[0].submit();</script>"))
        form.to_response
      end

      private

      def callback_with_status_url(status)
        url = URI(callback_url)
        url.query = "omniauth_status=#{status}"
        url
      end
    end
  end
end
