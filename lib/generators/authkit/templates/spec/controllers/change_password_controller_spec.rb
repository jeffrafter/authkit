require 'spec_helper'

describe ChangePasswordController do
  render_views

  describe "GET 'show'" do
    it "returns http success" do
      get 'show', token: 'testtoken'
      response.should be_success
    end
  end

end
