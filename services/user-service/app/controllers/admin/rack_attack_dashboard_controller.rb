# frozen_string_literal: true

module Admin
  class RackAttackDashboardController < ApplicationController
    before_action :authenticate_admin!
    
    def index
      @statistics = RackAttackMonitor.statistics
      @suspicious_ips = @statistics[:suspicious_ips]
      @recent_blocks = recent_security_events(:blocked)
      @recent_throttles = recent_security_events(:throttled)
    end

    def ip_details
      @ip = params[:ip]
      @reputation = RackAttackMonitor.check_ip_reputation(@ip)
      @whois_info = fetch_whois_info(@ip) if Rails.env.production?
    end

    def whitelist_ip
      ip = params[:ip]
      add_to_whitelist(ip)
      redirect_to admin_rack_attack_dashboard_path, 
                  notice: "IP #{ip} has been whitelisted"
    end

    def blacklist_ip
      ip = params[:ip]
      reason = params[:reason] || 'Manual block by admin'
      add_to_blacklist(ip, reason)
      redirect_to admin_rack_attack_dashboard_path,
                  notice: "IP #{ip} has been blacklisted"
    end

    def clear_ip_history
      ip = params[:ip]
      clear_ip_tracking(ip)
      redirect_to admin_rack_attack_dashboard_path,
                  notice: "History cleared for IP #{ip}"
    end

    private

    def authenticate_admin!
      # Implement your admin authentication logic
      # redirect_to root_path unless current_user&.admin?
    end

    def recent_security_events(type)
      # Fetch recent events from your logging system
      # This is a placeholder implementation
      []
    end

    def fetch_whois_info(ip)
      # Integrate with WHOIS service
      # Example: use the whois gem
      begin
        # Whois.whois(ip)
        { error: 'WHOIS lookup not implemented' }
      rescue => e
        { error: e.message }
      end
    end

    def add_to_whitelist(ip)
      key = "rack_attack:whitelist:#{ip}"
      Rails.cache.write(key, true, expires_in: 30.days)
      
      # Log the action
      Rails.logger.info "[RackAttack] IP whitelisted by admin", {
        ip: ip,
        admin: current_user.email,
        timestamp: Time.current
      }
    end

    def add_to_blacklist(ip, reason)
      key = "rack_attack:blacklist:#{ip}"
      Rails.cache.write(key, { reason: reason, admin: current_user.email }, expires_in: 30.days)
      
      # Log the action
      Rails.logger.info "[RackAttack] IP blacklisted by admin", {
        ip: ip,
        reason: reason,
        admin: current_user.email,
        timestamp: Time.current
      }
    end

    def clear_ip_tracking(ip)
      Rails.cache.delete("rack_attack:ip_behavior:#{ip}")
      
      # Log the action
      Rails.logger.info "[RackAttack] IP history cleared by admin", {
        ip: ip,
        admin: current_user.email,
        timestamp: Time.current
      }
    end
  end
end