class Api::V1::AuditLogsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :authorize_admin!
  
  def index
    audit_logs = AuditLog.includes(:user)
    
    # Apply filters
    audit_logs = audit_logs.by_user(params[:user_id]) if params[:user_id].present?
    audit_logs = audit_logs.by_action(params[:action]) if params[:action].present?
    audit_logs = audit_logs.by_ip(params[:ip_address]) if params[:ip_address].present?
    audit_logs = audit_logs.recent(params[:days].to_i) if params[:days].present?
    audit_logs = audit_logs.login_events if params[:login_events] == 'true'
    audit_logs = audit_logs.security_events if params[:security_events] == 'true'
    
    # Date range filter
    if params[:start_date].present?
      audit_logs = audit_logs.where('created_at >= ?', Date.parse(params[:start_date]).beginning_of_day)
    end
    
    if params[:end_date].present?
      audit_logs = audit_logs.where('created_at <= ?', Date.parse(params[:end_date]).end_of_day)
    end
    
    # Pagination
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 50, 100].min # Max 100 per page
    
    audit_logs = audit_logs.order(created_at: :desc)
    total_count = audit_logs.count
    audit_logs = audit_logs.offset((page - 1) * per_page).limit(per_page)
    
    render json: {
      status: 'success',
      data: {
        audit_logs: audit_logs.map { |log| audit_log_serializer(log) },
        pagination: {
          current_page: page,
          per_page: per_page,
          total_count: total_count,
          total_pages: (total_count.to_f / per_page).ceil
        }
      }
    }
  end
  
  def show
    audit_log = AuditLog.find(params[:id])
    
    render json: {
      status: 'success',
      data: {
        audit_log: audit_log_serializer(audit_log)
      }
    }
  end
  
  def user_activity
    user = User.find(params[:user_id])
    audit_logs = AuditLog.by_user(user.id).order(created_at: :desc).limit(100)
    
    render json: {
      status: 'success',
      data: {
        user: {
          id: user.id,
          email: user.email,
          full_name: user.full_name
        },
        activity: audit_logs.map { |log| audit_log_serializer(log) }
      }
    }
  end
  
  def security_events
    audit_logs = AuditLog.security_events
                          .includes(:user)
                          .order(created_at: :desc)
                          .limit(100)
    
    render json: {
      status: 'success',
      data: {
        security_events: audit_logs.map { |log| audit_log_serializer(log) }
      }
    }
  end
  
  def login_events
    audit_logs = AuditLog.login_events
                          .includes(:user)
                          .order(created_at: :desc)
                          .limit(100)
    
    render json: {
      status: 'success',
      data: {
        login_events: audit_logs.map { |log| audit_log_serializer(log) }
      }
    }
  end
  
  def statistics
    # Get audit statistics
    total_logs = AuditLog.count
    today_logs = AuditLog.where('created_at >= ?', Date.current.beginning_of_day).count
    this_week_logs = AuditLog.where('created_at >= ?', 1.week.ago).count
    this_month_logs = AuditLog.where('created_at >= ?', 1.month.ago).count
    
    # Security event statistics
    security_events = AuditLog.security_events.where('created_at >= ?', 1.month.ago)
    failed_logins = security_events.by_action('login_failure').count
    account_lockouts = security_events.by_action('account_locked').count
    
    # Top IP addresses
    top_ips = AuditLog.where('created_at >= ?', 1.month.ago)
                      .group(:ip_address)
                      .order('count_all DESC')
                      .limit(10)
                      .count
    
    render json: {
      status: 'success',
      data: {
        statistics: {
          total_logs: total_logs,
          today_logs: today_logs,
          this_week_logs: this_week_logs,
          this_month_logs: this_month_logs,
          failed_logins_month: failed_logins,
          account_lockouts_month: account_lockouts,
          top_ip_addresses: top_ips
        }
      }
    }
  end
  
  private
  
  def audit_log_serializer(audit_log)
    {
      id: audit_log.id,
      action: audit_log.action,
      user: audit_log.user ? {
        id: audit_log.user.id,
        email: audit_log.user.email,
        full_name: audit_log.user.full_name
      } : nil,
      resource_type: audit_log.resource_type,
      resource_id: audit_log.resource_id,
      details: audit_log.details,
      ip_address: audit_log.ip_address,
      user_agent: audit_log.user_agent,
      session_id: audit_log.session_id,
      request_id: audit_log.request_id,
      created_at: audit_log.created_at,
      updated_at: audit_log.updated_at,
      is_security_event: audit_log.is_security_event?,
      is_sensitive_action: audit_log.is_sensitive_action?
    }
  end
end



