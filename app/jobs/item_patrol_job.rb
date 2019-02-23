class ItemPatrolJob < ApplicationJob
  queue_as :item_patrol

  rescue_from(StandardError) do |exception|
    logger.debug("===== Standard Error Escape Active Job =====")
    logger.error exception
  end

  def perform()
    Item.patrol
  end

end
