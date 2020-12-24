class CreateProducts < ActiveRecord::Migration[6.0]
  def change
    create_table :products do |t|
      t.string :store_name
      t.string :shopify_domain, null: false
      t.string :api_key, null: false
      t.string :api_password, null: false
      t.belongs_to :shop
      t.timestamps
    end
  end
end
