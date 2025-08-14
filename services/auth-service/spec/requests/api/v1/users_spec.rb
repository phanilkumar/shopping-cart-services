require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/users/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/users/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /profile" do
    it "returns http success" do
      get "/api/v1/users/profile"
      expect(response).to have_http_status(:success)
    end
  end

end
