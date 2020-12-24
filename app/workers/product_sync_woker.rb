class ProductSyncWorker
  include Sidekiq::Worker
  include BaseHelper
  include ProductSyncHelper

  def perform(payload)
    # product sync from brand to bzr
    @origin_shop = Product.find_by_shopify_domain(payload["original_domain"])
    return if @origin_shop.nil?
    return if @origin_shop.sync_products == false

    @topic = payload["topic"]

    puts "origin shop: #{@origin_shop.shopify_domain}"
    @origin_shop.connect

    # TODO: move products/delete logic into its own worker
    if @topic == "delete"
      sync_product_delete(@origin_shop, payload["id"])
    else
      source_product = ShopifyAPI::Product.find(:first, params: { ids: payload["id"].to_i })
      if source_product.present?
        # Metafield syncing is disabled.
        # source_product._metafields = source_product.metafields

        @dest_shop = dest_shop(source_product.tags)
        puts "dest shop: #{@dest_shop.shopify_domain}"
        if @dest_shop.present?
          ShopifyAPI::Base.clear_session
          @dest_shop.connect
          sync_bzr_brand_product(@origin_shop, source_product)
        end
      end
    end
  end

  def shop_domain_by_product_tags(product_tags)
    tags = product_tags.split(/,/).map(&:strip).find { |hash| hash.downcase.include?("product:") }
    if tags.present?
      return tags.split(/:/).last
    else
      return nil
    end
  end

  def dest_shop(tags)
    if @origin_shop.origin == "product"
      shop = @origin_shop.shop
    else
      domain = shop_domain_by_product_tags(tags)
      shop = (Product.find_by_shopify_domain(domain) if domain.present?)
    end
    shop
  end
end