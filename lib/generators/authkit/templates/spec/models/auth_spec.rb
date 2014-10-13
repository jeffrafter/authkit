require 'rails_helper'

describe Auth do
  let(:auth_params) { attributes_for(:auth) }

  it "finds the full name"
  it "returns the provider name if there is no full name"
  it "finds the first name"
  it "finds the last name"
  it "finds the image url"
  it "finds the image for a tumblr url"
  it "finds the username"
  it "does not find a username for google"
  it "has provider specific tests"
  it "knows how to refresh google tokens"
  it "returns a formatted provider name"
  it "parses the env"
end
