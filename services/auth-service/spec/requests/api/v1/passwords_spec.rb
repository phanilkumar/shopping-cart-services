require 'rails_helper'

RSpec.describe "Api::V1::Passwords", type: :request do
  describe "GET /forgot" do
    it "returns http success" do
      get "/api/v1/passwords/forgot"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /reset" do
    it "returns http success" do
      get "/api/v1/passwords/reset"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /change" do
    it "returns http success" do
      get "/api/v1/passwords/change"
      expect(response).to have_http_status(:success)
    end
  end

end
