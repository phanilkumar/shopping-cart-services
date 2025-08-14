require 'rails_helper'

RSpec.describe "Api::V1::OAuths", type: :request do
  describe "GET /google" do
    it "returns http success" do
      get "/api/v1/o_auth/google"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /facebook" do
    it "returns http success" do
      get "/api/v1/o_auth/facebook"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /github" do
    it "returns http success" do
      get "/api/v1/o_auth/github"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /twitter" do
    it "returns http success" do
      get "/api/v1/o_auth/twitter"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /linkedin" do
    it "returns http success" do
      get "/api/v1/o_auth/linkedin"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /callback" do
    it "returns http success" do
      get "/api/v1/o_auth/callback"
      expect(response).to have_http_status(:success)
    end
  end

end
