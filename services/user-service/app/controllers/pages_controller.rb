class PagesController < ApplicationController
  layout 'application'
  
  def home
  end
  
  def terms_of_service
  end
  
  def privacy_policy
  end

  def debug_language
    @current_locale = I18n.locale
    @available_locales = I18n.available_locales
    @session_locale = session[:locale]
    @test_translation = t('common.welcome')
  end
end




