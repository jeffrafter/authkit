class AvatarImportWorker
  include Sidekiq::Worker

  sidekiq_options queue: "default"
  sidekiq_options retry: false

  def perform(avatar_id)
    avatar = Avatar.find(avatar_id)
    avatar.import!
  end
end

