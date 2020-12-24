
require "remove_bg"

module Api
    module V1
        class ProductsController < AuthenticatedController
            include ApplicationHelper
            before_action :set_product, only: %i[destory update]
            def index
                # http_success_response(products: @shop.products.order("store_name"))
                # ShopifyAPI::Product.find("all")
                @products = ShopifyAPI::Product.find(:all)
            end

            def create
                create_product
            end

            def update
                _product_params = product_params
                if @product.update(_product_params)
                    upsert_webhook_sets
                    # if @product.sync_products
                    #     SyncProductScheduleBatchWorker.perform_in(1.second, @product.id)
                    # end
                    # if @product.sync_collections
                    #     SyncCollectionScheduleWorker.perform_in(1.second)
                    # end
                    http_success_response(products: @shop.products.order("store_name"))
                else
                    puts @product.errors.full_messages
                    http_error_response(messages: @product.errors.full_messages)
                end
            end
            def destroy
                if @product.destroy
                    http_success_response(products: @shop.products.order("store_name"))
                else
                    http_error_response(messages: @product.errors.full_messages)
                end
            end

            private
            def set_product
                @product = @shop.products.find(params[:id])
            end
        end     
    end
end
