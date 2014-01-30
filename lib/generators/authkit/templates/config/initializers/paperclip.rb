# By default attachments are stored on S3. The path of the file is unique
# (based on the hash which is calculated at the time of upload). We expect
# that hash to be predictable so we set the :default_url (which usually
# points to a missing.png) to a calculated interpolation called
# :s3_default_url. When uploading directly we expect the signed params
# to include the ${filename} key for Amazon uploads. This prevents
# a variety of JavaScript filename vulnerabilities (though doesn't
# entirely prevent bad filenames). Given that, we actually prefer to
# use the uploaded filename in the resulting path (without escaping).
Paperclip::Attachment.default_options.merge!(
  storage:               :s3,
  default_url:           ':s3_default_url',
  url:                   ':s3_domain_url',
  path:                  '/system/:class/:style/:hash/:filename',
  hash_data:             ':class/:attachment/:id/:style/:uploaded_at',
  hash_secret:           ENV['aws_hash_secret'],
  s3_permissions:        :private,
  s3_protocol:           'https',
  s3_credentials:        {
    bucket:              ENV['aws_bucket'],
    access_key_id:       ENV['aws_access_key_id'],
    secret_access_key:   ENV['aws_secret_access_key']
  },
  restricted_characters: nil,
  escape_url:            false
)

# By default, the :hash interpolation includes the :updated_at interpolation.
# This way, every time the model changes the hash is also changed and the
# content is expired. This can break if the same file is uploaded at the
# same second with different contents, but in such a case there are a number
# of other coordinated pieces (transactions, background jobs, etc) that
# might break and it could be expected.
#
# When importing, however, the updated_at key changes when the attachment_import_url is
# actually imported into the attachment, which changes the hash. This makes
# it impossible to predict what the ultimate URL will be because you cannot
# know what the future updated_at will be. Instead, if you record the time
# that the attachment_import_url was set and use that to calculate the hash the
# hash won't change when the contents of attachment_import_url are actually imported.
Paperclip.interpolates :uploaded_at do |attachment, style_name|
  return attachment.instance.attachment_uploaded_at.to_i.to_s
end

# When importing, the attachment_import_url is set, but not the attachment information.
# In order to poll for the completed processed styles (like thumb) we need
# to know what the ultimate url will be. This interpolation is used as the
# default_url and, if the attachment_import_url is set can assume the eventual path.
Paperclip.interpolates :s3_default_url do |attachment, style_name|
  return nil if attachment.instance.blank? || attachment.instance.attachment_import_url.blank?
  uri = URI.parse(attachment.instance.attachment_import_url) rescue nil
  return nil unless uri
  # Currently, Paperclip doesn't pass the style to the default, it always uses 'original'
  style_name = "thumb"
  classname = plural_cache.underscore_and_pluralize(attachment.instance.class.to_s)
  original_filename = File.basename(URI.decode(uri.path))
  basename = original_filename.gsub(/#{Regexp.escape(File.extname(original_filename))}$/, "")
  extension = ((style = attachment.styles[style_name.to_s.to_sym]) && style[:format]) || File.extname(original_filename).gsub(/^\.+/, "")
  filename = [basename, extension].reject(&:blank?).join(".")
  hash = attachment.hash_key(style_name)
  path = "system/#{classname}/#{style_name}/#{hash}/#{filename}"
  if attachment.s3_permissions(style_name) == "public-read"
    UploadHelper.aws_bucket_url + "/" + path
  else
    # We still get an authenticated url for the path, it is just based on the destination rather than the current
    UploadHelper.aws_url_for(path)
  end
end
