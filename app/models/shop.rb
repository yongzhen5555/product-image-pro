# frozen_string_literal: true
class Shop < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorage
  has_many :products, dependent: :destroy

  def origin
    "bzr"
  end

  def is_product?
    false
  end

  def api_version
    ShopifyApp.configuration.api_version
  end

  def connect
    ShopifyAPI::Base.clear_session
    session = ShopifyAPI::Session.new(domain: shopify_domain, token: shopify_token, api_version: api_version)
    ShopifyAPI::Base.activate_session(session)
  end
end
