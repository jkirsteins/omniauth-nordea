require 'spec_helper'

describe OmniAuth::Strategies::Nordea do

  RCVID = '11111111111'
  MAC = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'

  let(:app){ Rack::Builder.new do |b|
    b.use Rack::Session::Cookie, {:secret => "abc123"}
    b.use OmniAuth::Strategies::Nordea, RCVID, MAC
    b.run lambda{|env| [404, {}, ['Not Found']]}
  end.to_app }

  context "request phase" do
    before(:each) do
      get "/auth/nordea"
    end

    it "displays a single form" do
      expect(last_response.status).to eq(200)
      expect(last_response.body.scan('<form').size).to eq(1)
    end

    it "has JavaScript code to submit the form after it's created" do
      expect(last_response.body).to be_include("</form><script type=\"text/javascript\">document.forms[0].submit();</script>")
    end

    EXPECTED_VALUES = {}
    EXPECTED_VALUES.each_pair do |k,v|
      it "has hidden input field #{k} => #{v}" do
        expect(last_response.body.scan(
          "<input type=\"hidden\" name=\"#{k}\" value=\"#{v}\"").size).to eq(1)
      end
    end

  end

  context "callback phase" do
  end

end
