# Allow direct uploads to Amazon S3. Uploads are segmented by the
# Everything is uploaded into an separate paths based on the current user
# so that files are not overwritten when multiple people upload different
# files with the same name.
#
# In order to use this helper you must have the following environment
# variables set:
#
#   aws_access_key_id
#   aws_secret_access_key
#   aws_bucket
#
# Configure the AWS bucket with the following CORS policy
#
#   <CORSConfiguration>
#     <CORSRule>
#       <AllowedOrigin>http://0.0.0.0:3000</AllowedOrigin>
#       <AllowedOrigin><%= ENV['domain'] %></AllowedOrigin>
#       <AllowedMethod>GET</AllowedMethod>
#       <AllowedMethod>POST</AllowedMethod>
#       <AllowedMethod>PUT</AllowedMethod>
#       <MaxAgeSeconds>3600</MaxAgeSeconds>
#       <AllowedHeader>*</AllowedHeader>
#     </CORSRule>
#   </CORSConfiguration>
#
module UploadHelper

  # Use this as part of the XHR data params for the upload form
  # Options include:
  #
  #   expires_at: defaults to 1 hour from now
  #   max_file_size: defaults to 5GB (not currently used)
  #   acl: defaults to authenticated-read
  #   starts_with: defaults to "uploads/#{h(current_user.to_param)}/#{SecureRandom.hex}"
  #
  def aws_upload_params(options={})
    expires_at = options[:expires_at] || 1.hours.from_now
    max_file_size = options[:max_file_size] || 5.gigabyte
    acl = options[:acl] || 'authenticated-read'
    hash = "#{SecureRandom.hex}"
    starts_with = options[:starts_with] || "uploads/#{hash}"
    bucket = ENV['aws_bucket']
    # This used to include , but it threw Server IO errors
    policy = Base64.encode64(
      "{'expiration': '#{expires_at.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')}',
        'conditions': [
          ['starts-with', '$key', '#{starts_with}'],
          ['starts-with', '$hash', '#{hash}'],
          ['starts-with', '$utf8', ''],
          ['starts-with', '$x-requested-with', ''],
          ['eq', '$success_action_status', '201'],
          ['content-length-range', 0, #{max_file_size}],
          {'bucket': '#{bucket}'},
          {'acl': '#{acl}'},
          {'success_action_status': '201'}
        ]
      }").gsub(/\n|\r/, '')

    signature = Base64.encode64(
                  OpenSSL::HMAC.digest(
                    OpenSSL::Digest::Digest.new('sha1'),
                    ENV['aws_secret_access_key'], policy)).gsub("\n","")

    return {
      "key" => "#{starts_with}/${filename}",
      "hash" => "#{hash}",
      "utf8" => "",
      "x-requested-with" => "",
      "AWSAccessKeyId" => "#{ENV['aws_access_key_id']}",
      "acl" => "#{acl}",
      "policy" => "#{policy}",
      "signature" => "#{signature}",
      "success_action_status" => "201"
    }
  end

  # Use aws_upload_tags when embedding the upload params in a form.
  # For example:
  #
  #   <form action="<%= aws_upload_url %>" method="post" enctype="multipart/form-data" id="avatar_form">
  #     <input type="file" name="file" id="avatar_attachment">
  #     <%= aws_upload_tags %>
  #   </form>
  #
  def aws_upload_tags
    aws_upload_params.each do |name, value|
      concat text_field_tag(name, value)
    end
    nil
  end

  # The destination host for the upload always uses https even though it can be slower.
  # Safe and sure wins the race
  def aws_bucket_url
    UploadHelper.aws_bucket_url
  end

  def self.aws_bucket_url
    "https://#{ENV['aws_bucket']}.#{ENV['aws_region'] || 's3'}.amazonaws.com"
  end

  # Authenticated url for S3 objects with expiration. By default the URL will expire in
  # 1 day. The path should not include the bucket name.
  def aws_url_for(path, expires=nil)
    UploadHelper.aws_url_for(path, expires)
  end

  def self.aws_url_for(path, expires=nil)
    path = "/#{path}" unless path =~ /\A\//
    path = URI.encode(path)
    expires ||= 1.day.from_now
    string_to_sign = "GET\n\n\n#{expires.to_i}\n/#{ENV['aws_bucket']}#{path}"
    signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), ENV['aws_secret_access_key'], string_to_sign)).gsub("\n","")
    query_string = URI.encode_www_form("AWSAccessKeyId" => ENV['aws_access_key_id'], "Signature" => signature, "Expires" => expires.to_i)
    "#{aws_bucket_url}#{path}?#{query_string}"
  end
end
