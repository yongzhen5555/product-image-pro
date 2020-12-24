# frozen_string_literal: true

module Sync
  module WebhookAuthentication
    extend ActiveSupport::Concern
    included do
      before_action :validate_request
      skip_before_action :verify_authenticity_token

      private
      def validate_request
        domain = request.headers["HTTP_X_SHOPIFY_SHOP_DOMAIN"]
        hmac = request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"]
        @topic = request.headers["HTTP_X_SHOPIFY_TOPIC"]
        if domain.nil? || hmac.nil? || @topic.nil?
          render json: { error: "Invalid Request" }, status: 406
          return
        end

        @shop = Shop.find_by_shopify_domain(domain) || Product.find_by_shopify_domain(domain)
        if @shop.nil?
          render json: { error: "no solidus shopify service for #{domain} found" }, status: 404
          return
        end
        request.body.rewind
      end

      def verify_webhook(data, hmac_header)
        calculated_hmac = Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", @shop.secret, data))
        ActiveSupport::SecurityUtils.secure_compare(calculated_hmac, hmac_header)
      end
    end
  end
end