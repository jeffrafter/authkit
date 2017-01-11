# Shoulda matchers allow you to quickly verify validations and relationships
# The syntax methods give you inline matcher syntax
RSpec.configure do |config|
  config.include(Shoulda::Matchers::ActiveModel, type: :model)
  config.include(Shoulda::Matchers::ActiveRecord, type: :model)
end
