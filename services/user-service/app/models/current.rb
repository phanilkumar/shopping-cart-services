# frozen_string_literal: true

# Current class to store request context for use in models
class Current < ActiveSupport::CurrentAttributes
  attribute :request, :user
end
