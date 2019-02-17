class ItemSearchJob < ApplicationJob
  queue_as :item_search

  rescue_from(StandardError) do |exception|
    logger.debug("===== Standard Error Escape Active Job =====")
    logger.error exception
  end

  def perform(user, search_url, shop_id)
    Item.search(user, search_url, shop_id)
  end

end
