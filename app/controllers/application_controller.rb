class ApplicationController < ActionController::Base
    def create_product
        @product = Product.new(product_params)
        @product.shop = @shop
        if @product.save
            upsert_webhook_sets
            http_success_response(products: @product.products.order("store_name"))
        else
            puts @product.errors.full_messages
            http_error_response(messages: @product.errors.full_messages)
        end
    end

    def upsert_webhook_sets
        @product.with_product_shopify_session do
            topic_sets.each do |topic|
                upsert_webhook(topic, topic.gsub("/", "_"))
            end
        end
    end

    def http_success_response(hash)
        render json: hash, status: :ok
    end

    def http_error_response(error_hash)
        render json: error_hash, status: 400
    end

    private
        def product_params
            params.permit(
                :store_name,
                :shopify_domain,
                :api_key,
                :api_password,
                :sync_products,
            )
        end

        def address_endpoint
            "#{ENV['APP_URL']}/api/v1/webhooks/"
        end

        def topic_sets
            [
                "products/delete",
                "products/create",
                "products/update",
            ]
        end

        def upsert_webhook(topic, path)
            ShopifyAPI::Webhook.create(topic: topic, address: "#{address_endpoint}/#{path}")
        end

end
