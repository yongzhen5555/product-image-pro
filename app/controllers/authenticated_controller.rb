# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  include ShopifyApp::Authenticated
  before_action :set_shop

  def set_shop
    @shop = Shop.where(shopify_domain: session[:shopify_domain]).take
  end
end
