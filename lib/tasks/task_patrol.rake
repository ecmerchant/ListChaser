namespace :task_patrol do
  desc "楽天商品の監視"

  task :operate => :environment do |task|
    ItemPatrolJob.perform_later()
  end

end
