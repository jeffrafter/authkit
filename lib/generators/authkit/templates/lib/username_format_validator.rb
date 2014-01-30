class UsernameFormatValidator < ActiveModel::EachValidator
  def validate_each(object, attribute, value)
    unless UsernameFormatValidator::is_valid_username(value)
      object.errors[attribute] << (options[:message] || "is not a valid username")
    end
  end

  def self.is_valid_username(value)
    value =~ /\A[0-9A-Za-z\-\_]+\z/
  end
end
