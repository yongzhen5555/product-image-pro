
require "json"

class Product < ApplicationRecord
    include Aws
    belongs_to :shop

    validates_presence_of :api_key, :api_password, :shopify_domain
    validates_uniqueness_of :shopify_domain

    attribute :access_token, :string

    def get_access_token
        client = Aws::SecretsManager::Client.new(
            region: ENV.fetch("AWS_REGION")
        )
        secret = client.get_secret_value({
            secret_id: ENV.fetch("BZR_LINK_SHOPIFY_ACCESS_TOKEN_SECRET")
        })
        access_token = JSON.parse(secret[:secret_string])
        access_token[shopify_domain] || nil
    end

    def product_url
        URI("https://#{api_key}:#{api_password}@#{shopify_domain}/admin")
    end

    def origin
        "product"
    end

    def connect
        unless self.access_token.present?
            self.access_token = get_access_token
        end

        ShopifyAPI::Base.clear_session
        ShopifyAPI::Base.api_version = ShopifyAPI.configuration.api_version

        if self.access_token.present?
            shopify_session = ShopifyAPI::Session.new(domain: shopify_domain, token: self.access_token, api_version: ShopifyAPI.configuration.api_version)
            ShopifyAPI::Base.activate_session(shopify_session)
        else
            ShopifyAPI::Base.site = product_url
        end
    end

    def is_product?
        true
    end

    def base64_encode
        "Basic " + Base64.strict_encode64("#{api_key}:#{api_password}")
    end

    def with_product_shopify_session
        unless self.access_token.present?
            self.access_token = get_access_token
        end

        if self.access_token.present?
            ShopifyAPI::Session.temp(domain: shopify_domain, token: access_token, api_version: ShopifyAPI.configuration.api_version) do
                yield
            end
        else
            ShopifyAPI::Session.temp(domain: shopify_domain, token: api_password, api_version: ShopifyAPI.configuration.api_version) do
                yield
            end
        end
    end

end
