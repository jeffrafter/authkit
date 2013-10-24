require 'spec_helper'

describe PasswordResetController do
  render_views

  describe "GET 'show'" do
    it "returns http success" do
      get 'show'
      response.should be_success
    end
  end

end
