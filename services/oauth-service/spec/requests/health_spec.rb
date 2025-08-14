require 'rails_helper'

RSpec.describe "Healths", type: :request do
  describe "GET /check" do
    it "returns http success" do
      get "/health/check"
      expect(response).to have_http_status(:success)
    end
  end

end
