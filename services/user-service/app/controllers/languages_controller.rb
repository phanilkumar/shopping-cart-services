class LanguagesController < ApplicationController
  def change
    locale = params[:locale].to_s.strip.to_sym
    
    if I18n.available_locales.include?(locale)
      session[:locale] = locale
      I18n.locale = locale
    end
    
    # Try to redirect back to the previous page, but avoid redirecting to sign-up/login pages
    if request.referer.present?
      referer_uri = URI.parse(request.referer)
      referer_path = referer_uri.path
      
      # If the referer is a sign-up or login page, redirect to root instead
      if referer_path.include?('/users/sign_up') || referer_path.include?('/users/sign_in')
        redirect_to root_path
      else
        redirect_to request.referer
      end
    else
      redirect_to root_path
    end
  end
  
  def index
    @current_locale = I18n.locale
    @available_locales = I18n.available_locales
  end
end

