class PagesController < ApplicationController
  layout 'application'
  
  def home
    redirect_to new_user_session_path
  end
  
  def terms_of_service
  end
  
  def privacy_policy
  end
end




