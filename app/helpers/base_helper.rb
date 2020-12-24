module BaseHelper
  included ConstantsHelper
  def product_by_handle(handle)
    ShopifyAPI::Product.find(:first, params: { handle: handle })
  end

  def product_by_id(id)
    ShopifyAPI::Product.find(:first, params: { ids: id })
  end

  def products_by_ids(ids, fields)
    ShopifyAPI::Product.find(:all, params: { ids: ids.join(","), fields: fields })
  end

  def products_by_handles(handles, fields)
    ShopifyAPI::Product.find(:all, params: { handle: handles.join(","), fields: fields })
  end
  def sleep_api_call(duration = SHOPIFY_API_SLEEP)
    sleep(duration)
  end
end
