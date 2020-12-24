module ProductSyncHelper
  include BaseHelper
  # include SlackHelper
  # def sync_bzr_brand_product(source, source_product)
  #   bzr_relation = ProductRelation.where(brand: source, brand_product_id: source_product.id).take
  #   if bzr_relation.nil?
  #     if source_product.published_at.nil?
  #       return false
  #     else
  #       create_product_from_source(source, source_product)
  #     end
  #   else
  #     puts bzr_relation.id
  #     @product = product_by_id(bzr_relation.bzr_product_id)
  #     if @product.present?
  #       update_product_from_source(source, source_product)
  #     else
  #       puts bzr_relation.errors.full_messages unless bzr_relation.destroyed?
  #     end
  #   end
  # end

  def create_product_from_source(source, source_product)
    @product = ShopifyAPI::Product.new
    set_product_properties_for_create(source, source_product)

    sleep_api_call # sleep to avoid hitting API limit
    unless product_by_handle(source_product.handle).present?
      if @product.save
        sleep_api_call
        set_variant_images(source, source_product)
        upsert_product_relations(source, source_product, @product)
        check_and_update_product_options
        update_inventories(brand: source, brand_product: source_product)

        # Metafield syncing is disabled
        # if source.sync_product_metafields
        #   set_metafields source_product._metafields
        # end
        message = "New #{source.store_name} product added: #{source_product.title}\n<#{ENV['SHOPIFY_URL']}/admin/products/#{@product.id}|View in Shopify>"
        slack_notify_product message
        puts "bzr-log-success:product-sync:created #{source_product.handle} from #{source.shopify_domain} as the product id of #{@product.id}"
      else
        puts "bzr-log-error:product-sync: product failed to save - #{ @product.errors.full_messages }"
      end
    end
  rescue Exception => e
    puts "bzr-log-error:product-sync:#{e.to_json} for #{source_product.handle}"
    raise
  end

  def update_product_from_source(source, source_product)
    updates = []

    if @product.title != source_product.title
      updates.push("Title")
    end

    description_changed = @product.body_html != source_product.body_html
    should_sync_description = @product.tags.downcase.include?("description:sync")

    if description_changed && should_sync_description
      updates.push("Description")
    end

    product_json = @product.as_json
    source_product_json = source_product.as_json

    variant_prices = {}

    product_json["variants"].each do |variant|
      variant_prices[variant.title] = variant.price
    end

    source_product_json["variants"].each do |variant|
      title = variant.title

      puts "OG Title: #{title}"
      # This confusing block of code flips color and size because thats how things be -rohail
      color_option = source_product.options.find { |option| option.name.downcase.include?("color") }
      size_option = source_product.options.find { |option| option.name.downcase.include?("size") }

      if color_option.present? && size_option.present?
        puts "Size and Color Present"
        color_position = color_option.position
        size_position = size_option.position
        puts "Color position #{color_position}"
        puts "Size position #{size_position}"
        if size_position < color_position
          title = "#{variant.option2} / #{variant.option1}"
          puts "New Title: #{title}"
        end
      end
      # End confusing block

      price = variant.price

      if variant_prices[title] != price
        puts "okay lets see whats happening"
        puts variant_prices
        puts product_json
        puts "title in block: #{title}"
        puts "variant price: #{variant_prices[title]}"
        updates.push("Variant #{title} Price from #{variant_prices[title]} to #{price}")
      end
    end
    set_product_properties_for_updates(source, source_product)

    sleep_api_call # sleep to avoid hitting API limit

    if @product.save
      sleep_api_call
      if @product.tags.downcase.include?("image:sync")
        set_variant_images_for_update
        set_variant_images(source, source_product)
      end
      check_and_update_product_options
      update_inventories(brand: source, brand_product: source_product)
      upsert_product_relations(source, source_product, @product)

      # Metafield syncing is disabled
      # if source.sync_product_metafields
      #   set_metafields source_product._metafields
      # end

      message = "#{source_product.title} by #{source.store_name} updated\nWhat changed: #{updates.join(", ")}\n<#{ENV['SHOPIFY_URL']}/admin/products/#{@product.id}|View in Shopify>"

      slack_notify_product message unless updates.length == 0

      puts "bzr-log-success:product-sync:updated #{source_product.handle} from #{source.shopify_domain} as the product id of #{@product.id}"
    else
      puts @product.errors.full_messages
    end
  rescue Exception => e
    puts "bzr-log-error:product-sync:#{e.to_json} for #{source_product.handle}"
    raise
  end

  def set_metafields(metafields)
    current_metafields = @product.metafields

    begin
      if current_metafields.length == 0
        @product.metafields = metafields
        @product.save
      else
        product_metafields = Array.new

        brand_metafields = metafields.map { |e| { namespace: e.namespace, key: e.key, value: e.value, value_type: e.value_type, description: e.description } }
        current_metafields.each do |metafield|
          tmp = brand_metafields.find { |e| e[:namespace] == metafield.namespace && e[:key] == metafield.key }
          if tmp.present?
            if metafield.value != tmp[:value]
              metafield.value = tmp[:value]
              metafield.save
              sleep_api_call
            end
          end

          product_metafields << { namespace: metafield.namespace, key: metafield.key }
        end

        new_metafields = brand_metafields.select { |e| product_metafields.select { |f| e[:namespace] == f[:namespace] && e[:key] == f[:key] }.length == 0 }
        @product.metafields = new_metafields if new_metafields.length > 0
        @product.save
        sleep_api_call
      end

      puts "bzr-log-success:metafields-sync: updated product metafields for #{@product.title}"
    rescue Exception => e
      puts e.to_json
      raise
    end
  end

  def set_product_properties_for_create(source, source_product)
    @product.title = source_product.title
    @product.body_html = source_product.body_html
    @product.images = source_product.images # moved to create logic. sync images only when products are creating.
    @product.tags = refactor_tags(source_product.tags, source, source_product.tags)
    @product.vendor = source.store_name
    @product.handle = source_product.handle
    @product.published_scope = source_product.published_scope
    @product.published_at = source_product.published_at
    @product.product_type = source_product.product_type
    @product.variants = refactor_variants(source_product.variants)
    if refactor_tags(source_product.tags, source, source_product.tags).include?("bundle:") && source.store_name.downcase == "andie"
      @product.template_suffix = "bundle-#{source.store_name.downcase.gsub(/ /, "-")}"
    else
      @product.template_suffix = source.store_name.downcase.gsub(/ /, "-")
    end
    @product.options = source_product.options
  end

  def set_product_properties_for_updates(source, source_product)
    unless @product.tags.downcase.include?("bzr:unavailable")
      @product.published_scope = source_product.published_scope
      @product.published_at = source_product.published_at
    end
    @product.title = source_product.title
    if @product.tags.downcase.include?("description:sync")
      @product.body_html = source_product.body_html
    end
    @product.handle = source_product.handle
    @product.options = source_product.options
    if @product.tags.downcase.include?("image:sync")
      @product.images = source_product.images # moved to create logic. sync images only when products are creating.
    end
    @product.vendor = source.store_name
    @product.variants = refactor_variants(source_product.variants)
    @product.tags = refactor_tags(source_product.tags, source, source_product.tags)
    if refactor_tags(source_product.tags, source, source_product.tags).include?("bundle:") && source.store_name.downcase == "andie"
      @product.template_suffix = "bundle-#{source.store_name.downcase.gsub(/ /, "-")}"
    else
      @product.template_suffix = source.store_name.downcase.gsub(/ /, "-")
    end
  end

  def set_variant_images(_source, source_product)
    source_product.images.each do |source_image|
      dest_image = @product.images.find { |img| img.position == source_image.position }
      next if dest_image.nil?

      if source_image.variant_ids.empty?
        if source_image.alt.present? && source_product.options.map { |e| e.values.join(";") }.join(";").downcase.split(";").include?(source_image.alt.downcase)
          dest_image.alt = source_image.alt
        else
          dest_image.alt = nil
        end
      else
        variant_positions = source_product.variants.select { |v| source_image.variant_ids.include?(v.id) }.map(&:position)
        dest_variants = @product.variants.select { |v| variant_positions.include?(v.position) }
        color_option = @product.options.find { |opt| opt.name.downcase == "color" }
        dest_image.alt = if color_option.present?
                           case color_option.position
                           when 1
                             dest_variants.first.option1
                           when 2
                             dest_variants.first.option2
                           when 3
                             dest_variants.first.option3
                           else
                             dest_variants.first.option1
                           end
                         end
        dest_image.variant_ids = dest_variants.map(&:id)
      end
      puts dest_image.errors.full_messages unless dest_image.save
      sleep_api_call
    end
  end

  def refactor_variants(variants)
    refactored_variants = variants.map { |variant| jsonized_variant(variant) }
    refactored_variants.sort_by! { |v| v[:position] || 0 }
  end

  def refactor_tags(tags, source, source_tags)
    new_tags = "#{@product.id.present? && @product.tags.present? ? @product.tags : ''},#{tags}".split(/,/)
                                                                                               .map(&:strip)
                                                                                               .reject { |hash| (hash.downcase.include?("source:") || hash.downcase.include?("bzr:")) && (hash.downcase != "bzr:unavailable") }
    new_tags << "#{source.origin.upcase}:#{source.shopify_domain}"
    colorspace_tags = tags.split(/,/).map(&:strip).find { |tag| tag.downcase.include?("colorspace") && tag.downcase.include?("=>") }

    if colorspace_tags.present?
      new_tags = new_tags.reject { |hash| hash.downcase.include?("colorspace") && hash.downcase.include?("=>") }
      colorspace_tags = tags.split(/,/).map(&:strip).find { |tag| tag.downcase.include?("colorspace") && tag.downcase.include?("=>") }
      new_tags << colorspace_tags
    end

    if tags.include?("andie::master")
      master_tag = tags.split(/,/).map(&:strip).find { |tag| tag.downcase.include?("andie::master") && tag.downcase.include?("=>") }
      master_tag = master_tag.split("=>").map(&:strip).last
      new_tags << "bundle:#{master_tag}"
    end

    unless @product.id.nil?
      option_related_tags = @product.options.map { |e| e.values.map { |v| "#{e.name.downcase}:#{v.split('/').map(&:strip).join(' / ')}" }.join(",")  }.join(",").split(",")
      new_tags = new_tags + option_related_tags
    end

    new_tags = new_tags.reject { |hash| hash.include?("andie::") } + source_tags.split(/,/).map(&:strip).select { |hash| hash.include?("andie::") }

    new_tags.uniq!
    new_tags.join(",")
  end

  def jsonized_variant(variant)
    original_variant = @product.respond_to?(:variants) ? @product.variants.find { |v| v.title.split(" / ").sort.join(" / ") == variant.title.split(" / ").sort.join(" / ") } : nil
    json_object = {
      title: variant.title,
      price: variant.price,
      sku: variant.sku,
      inventory_policy: variant.inventory_policy,
      compare_at_price: variant.compare_at_price,
      fulfillment_service: variant.fulfillment_service,
      inventory_management: variant.inventory_management,
      option1: variant.option1,
      option2: (variant.option2 if variant.option2.present?),
      option3: (variant.option3 if variant.option3.present?),
      taxable: variant.taxable,
      barcode: variant.barcode,
      grams: variant.grams,
      weight: variant.weight,
      weight_unit: variant.weight_unit,
      # inventory_quantity: variant.inventory_quantity,
      # old_inventory_quantity: variant.old_inventory_quantity,
      cost: (variant.cost if variant.respond_to?(:cost) && variant.cost.present?),
      tax_code: (if variant.respond_to?(:tax_code) && variant.tax_code.present?
                   variant.tax_code
                 end),
      requires_shipping: variant.requires_shipping
    }
    json_object[:id] = original_variant.id if original_variant.present?
    json_object[:position] = original_variant.position if original_variant.present?
    json_object
  end

  def map_image_variants
    @image_variants_relation = @product.images.map do |image|
      {
        image_id: image.id,
        variant_positions: @product.variants.select { |variant| image.variant_ids.include?(variant.id) }.map(&:position)
      }
    end
  end

  def set_variant_images_for_update
    map_image_variants
    @product.images.each do |image|
      relation = @image_variants_relation.find { |r| r[:image_id] == image.id }
      if relation[:variant_positions].count == 0
        image.alt = nil
      else
        variants = @product.variants.select { |variant| relation[:variant_positions].include?(variant.position) }
        variant_ids = variants.map(&:id)
        color_option = @product.options.find { |opt| opt.name.downcase == "color" }
        image.alt = if color_option.present?
                      case color_option.position
                      when 1
                        variants.first.option1
                      when 2
                        variants.first.option2
                      when 3
                        variants.first.option3
                      else
                        variants.first.option1
                      end
                    end
        image.variant_ids = variant_ids
      end
      puts image.errors.full_messages unless image.save
      sleep_api_call
    end
  end

  def upsert_product_relations(source_shop, source_product, dest_product)
    if source_shop.origin == "brand"
      ProductRelation.where(brand: source_shop, brand_product_id: source_product.id).first_or_initialize.tap do |relation|
        relation.bzr_product_id = dest_product.id
        relation.save
      end
    end
  end

  def sync_product_delete(source_shop, source_id)
    if source_shop.origin == "brand"
      bzr_shop = Shop.find_by_shopify_domain(source_shop.shop.shopify_domain)
      bzr_brand_relation = ProductRelation.where(brand_product_id: source_id).where(brand: source_shop).take
      if bzr_brand_relation.present? && bzr_shop.present?
        bzr_shop.connect
        bzr_product = product_by_id(bzr_brand_relation.bzr_product_id)
        if bzr_product.present?
          bzr_product.published_at = nil
          puts bzr_product.errors.full_messages unless bzr_product.save
          sleep_api_call
        end
      end
    end
  end

  def check_and_update_product_options
    color_option = @product.options.find { |option| option.name.downcase.include?("color") }
    size_option = @product.options.find { |option| option.name.downcase.include?("size") }
    if color_option.present? && size_option.present?
      color_position = color_option.position
      size_position = size_option.position
      if size_position < color_position
        puts "check and update product options when size < color options"
        # swap positions for color & size of product
        color_option.position = size_position
        size_option.position = color_position
        options = @product.options.reject { |option| %w[color size].include?(option.name.downcase) }
        options = [color_option, size_option] + options
        @product.options = options
        # swap positions for color & size of variant
        @product.variants.each do |variant|
          color_option_val = variant.send("option#{color_position}")
          size_option_val = variant.send("option#{size_position}")
          variant.option1 = color_option_val
          variant.option2 = size_option_val
        end
        puts @product.errors.to_json unless @product.save
        sleep_api_call
      end
    end
  end

  def update_inventories(brand:, brand_product:)
    begin
      brand_product.variants.each do |brand_variant|
        bzr_variant = @product.variants.find { |bzr_v| bzr_v.title.split(" / ").sort.join(" / ") == brand_variant.title.split(" / ").sort.join(" / ") }
        # bzr_variant = @product.variants.find { |bzr_v| bzr_v.position == brand_variant.position }
        if bzr_variant.nil?
          puts "bzr-log-warning:inventory-sync: couldn't find variant #{ brand_variant.title } for product #{ @product.title }"
          return
        end

        # Defer inventory syncing to asynchronous job
        SyncInventoryLevelsWorker.perform_in(
          1.second,
          brand.id,
          bzr_variant.inventory_item_id,
          brand_variant.inventory_quantity.to_i
        )
      end
    end
  rescue Exception => e
    puts e.to_json
    raise
  end
end
