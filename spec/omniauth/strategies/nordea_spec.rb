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

    before(:each) { get "/auth/nordea" }

    it "displays a single form" do
      expect(last_response.status).to eq(200)
      expect(last_response.body.scan('<form').size).to eq(1)
    end

    it "has JavaScript code to submit the form after it's created" do
      expect(last_response.body).to be_include("</form><script type=\"text/javascript\">document.forms[0].submit();</script>")
    end

    EXPECTED_VALUES = {
      "A01Y_ACTION_ID" => "701",
      "A01Y_VERS" => "0002",
      "A01Y_RCVID" => RCVID,
      "A01Y_LANGCODE" => "LV",
      "A01Y_STAMP" => "yyyymmddhhmmssxxxxxx",
      "A01Y_IDTYPE" => "02",
      "A01Y_RETLINK" => "http://example.org/auth/nordea/callback?omniauth_status=success",
      "A01Y_CANLINK" => "http://example.org/auth/nordea/callback?omniauth_status=cancelled",
      "A01Y_REJLINK" => "http://example.org/auth/nordea/callback?omniauth_status=rejected",
      "A01Y_KEYVERS" => "0001",
      "A01Y_ALG" => "02",
      "A01Y_MAC" => "c2e09d42e0eaf565ba1b14074f3bdae341b35bce"
    }

    EXPECTED_VALUES.each_pair do |k,v|
      it "has hidden input field #{k} => #{v}" do
        expect(last_response.body.scan(
          "<input type=\"hidden\" name=\"#{k}\" value=\"#{v}\"").size).to eq(1)
      end
    end

  end

  context "callback phase" do
    let(:auth_hash){ last_request.env['omniauth.auth'] }

    context "with valid response" do
      before do
        post :'/auth/nordea/callback',
          "B02K_VERS" => "0002",
          "B02K_TIMESTMP" => "2002014020513320773",
          "B02K_IDNBR" => "f26402f2250340dba8b24c8498fd8c58",
          "B02K_STAMP" => "yyyymmddhhmmssxxxxxx",
          "B02K_CUSTNAME" => "Last First",
          "B02K_KEYVERS" => "0001",
          "B02K_ALG" => "02",
          "B02K_CUSTID" => "12345612345",
          "B02K_CUSTTYPE" => "01",
          "B02K_MAC" => "852E3207E143677B6E622DDF1D27B13979DB8C67"
      end

      it "sets the correct uid value in the auth hash" do
        expect(auth_hash.uid).to eq("123456-12345")
      end

      it "sets the correct info.full_name value in the auth hash" do
        expect(auth_hash.info.full_name).to eq("First Last")
      end
    end

  end

end
