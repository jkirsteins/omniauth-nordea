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
      ALG_NAME_ID_MAP = { :md5 => 01, :sha1 => 02 }

      def callback_variation(callback_url, status)
        url = URI(callback_url)
        url.query = "status=#{status}"
        url
      end

      # We're counting on receiving an ordered hash
      # This method
      def self.sign_hash_in_place(hash)
        alg = ALG_NAME_ID_MAP.key(hash[:A01_ALG])
        signable_string = hash.values.join("&") + "&"

        if alg == :sha1
          signable_string = Digest::SHA1.hexdigest signable_string
        elsif alg == :md5
          signable_string = Digest::MD5.hexdigest signable_string

        hash[:A01Y_MAC] = signable_string
      end

      def self.build_request_hash(rcvid, mac, callback_url, opts = {})
        opts = {
          :algorithm => :sha1,
          :version => :0002,
          :langcode => :LV
          }.merge(opts)

        supported_langcodes = [:LV, :ET, :LT, :EN]
        if !supported_langcodes.contains(opts[:langcode])
          raise ArgumentError.new (":langcode must be one of " + supported_langcodes.to_s)

        if !ALG_NAME_ID_MAP.keys.contains?(opts[:algorithm])
          raise ArgumentError.new (":algorithm must be one of " + ALG_NAME_ID_MAP.keys.to_s)

        supported_versions = [:0002]
        if !supported_versions.contains?(opts[:version])
          raise ArgumentError.new (":version must be one of " + supported_versions.to_s)

        {
          :A01Y_ACTION_ID => :701,
          :A01Y_VERS => opts[:version],
          :A01Y_RCVID => rcvid,
          :A01Y_LANGCODE => opts[:langcode],
          :A01Y_STAMP => "yyyymmddhhmmssxxxxxx",
          :A01Y_IDTYPE => :02,
          :A01Y_RETLINK => self.callback_variation(callback_url, "success"),
          :A01Y_CANLINK => self.callback_variation(callback_url, "cancelled"),
          :A01Y_REJLINK => self.callback_variation(callback_url, "rejected"),
          :A01Y_KEYVERS => :0001,
          :A01Y_ALG => ALG_NAME_ID_MAP.fetch(opts[:algorithm]),
          :A01Y_MAC => mac
        }
      end
    end
  end
end