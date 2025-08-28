class LanguagesController < ApplicationController
  def change
    locale = params[:locale].to_s.strip.to_sym
    
    if I18n.available_locales.include?(locale)
      session[:locale] = locale
      I18n.locale = locale
    end
    
    redirect_back(fallback_location: root_path)
  end
  
  def index
    @current_locale = I18n.locale
    @available_locales = I18n.available_locales
  end
end

