class Avatar < ActiveRecord::Base
  # Avatar images are publicly available (you can share the URL and it won't
  # expire, but you probably can't guess it). Also, the images should be
  # cached on the client side as the path name includes a hash.
  has_attached_file :attachment,
    styles: {thumb: "200x200#"},
    s3_permissions: 'public-read',
    s3_headers: {"Cache-Control" => "max-age=#{1.year.to_i}", "Expires" => 1.year.from_now.httpdate}

  before_validation :prepare_import
  validates :attachment, attachment_presence: true, unless: :attachment_importing?
  after_save :async_import

  def as_json(options = {})
    super({
      methods: [:url]
    }.merge(options))
  end

  def url
    self.attachment.url(:thumb)
  end

  def import!
    return false unless self.attachment_importing?
    self.attachment_importing = false
    if self.remote_url.present?
      uri = URI.parse(self.remote_url)
      self.attachment = uri
      self.attachment_file_name = File.basename(URI.decode(uri.path))
    end
    self.save
  end

  protected

  def prepare_import
    return unless self.remote_url.present? && self.remote_url_changed?
    self.attachment_importing = true
  end

  def async_import
    AvatarImportWorker.perform_async(self.id) if self.attachment_importing?
  end
end
