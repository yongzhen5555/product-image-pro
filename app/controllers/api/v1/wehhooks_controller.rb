require 'json'

class Api::V1::WehhooksController < ApplicationController
  include Sync::WebhookAuthentication

  def create
    head :ok, content_type: "application/json"
  end

  def products_create
    head :ok, content_type: "application/json"
    params.permit!
    ProductSyncWorker.perform_async(sync_params)
  end

  def products_delete
    head :ok, content_type: "application/json"
    params.permit!
    ProductSyncWorker.perform_in(4.seconds, sync_params)
  end

  def products_update
    head :ok, content_type: "application/json"
    params.permit!
    ProductSyncWorker.perform_in(4.seconds, sync_params)
  end
end
