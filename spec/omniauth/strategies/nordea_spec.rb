require 'spec_helper'

describe OmniAuth::Strategies::Nordea do
  RCVID = '87654321LV'
  MAC   = 'LEHTI'

  let(:app){ Rack::Builder.new do |b|
    b.use Rack::Session::Cookie, {:secret => "abc123"}
    b.use OmniAuth::Strategies::Nordea, RCVID, MAC, hash_algorithm: :md5
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
      "A01Y_ALG" => "01",
      "A01Y_MAC" => "5EF7613AA29E659456C47D0F9C471470"
    }

    EXPECTED_VALUES.each_pair do |k,v|
      it "has hidden input field #{k} => #{v}" do
        expect(last_response.body).to include(
          "<input type=\"hidden\" name=\"#{k}\" value=\"#{v}\""
        )
      end
    end

  end

  context "callback phase" do
    let(:auth_hash){ last_request.env['omniauth.auth'] }

    context "with valid response" do
      before do
        post '/auth/nordea/callback',
          "B02K_ALG": "01",
          "B02K_CUSTID": "37404280367",
          "B02K_CUSTNAME": "RAITUMS ARNIS",
          "B02K_CUSTTYPE": "01",
          "B02K_IDNBR": "87654321LV",
          "B02K_KEYVERS": "0001",
          "B02K_MAC": "B2B82821F6EB9CA28E4D67F343914363",
          "B02K_STAMP": "yyyymmddhhmmssxxxxxx",
          "B02K_TIMESTMP": "20020170329134514398",
          "B02K_VERS": "0002"
      end

      it "sets the correct uid value in the auth hash" do
        expect(auth_hash.uid).to eq("374042-80367")
      end

      it "sets the correct info.full_name value in the auth hash" do
        expect(auth_hash.info.full_name).to eq("ARNIS RAITUMS")
      end
    end

    context "with invalid MAC" do
      before do
        post '/auth/nordea/callback',
          "B02K_ALG": "01",
          "B02K_CUSTID": "37404280367",
          "B02K_CUSTNAME": "RAITUMS ARNIS",
          "B02K_CUSTTYPE": "01",
          "B02K_IDNBR": "87654321LV",
          "B02K_KEYVERS": "0001",
          "B02K_MAC": "B9CA28E4D67F343914B2B82821F6E363",
          "B02K_STAMP": "yyyymmddhhmmssxxxxxx",
          "B02K_TIMESTMP": "20020170329134514398",
          "B02K_VERS": "0002"
      end

      it "fails with invalid_mac error" do
        expect(auth_hash).to eq(nil)
        expect(last_request.env['omniauth.error.type']).to eq(:invalid_mac)
      end
    end

  end

end
