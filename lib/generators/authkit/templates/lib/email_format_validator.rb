class EmailFormatValidator < ActiveModel::EachValidator
  def validate_each(object, attribute, value)
    unless EmailFormatValidator::is_valid_email(value)
      object.errors[attribute] << (options[:message] || "is not a valid email address")
    end
  end

  def self.is_valid_email(value)
    value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  end
end
