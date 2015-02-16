
  before_filter :set_time_zone

  helper_method :logged_in?, :current_user

  # It is very unlikely that this exception will be created under normal
  # circumstances. Unique validations are handled in Rails, but they are also
  # enforced at the database level to guarantee data integrity. In certain
  # cases (double-clicking a save link, multiple distributed servers) it is
  # possible to get past the Rails validation in which case the database throws
  # an exception.
  rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique

  protected

  # The user is fetched using id or remember token but these come from a
  # verified cookie (verified using secure compare) so these database calls do
  # not need to protect against timing attacks.
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session ||= UserSession.active.where(id: session[:user_session_id]).first if session[:user_session_id]
    set_current_user_session_from_remember_token unless @current_user_session
    @current_user_session.access(request) if @current_user_session
    session[:user_session_id] = @current_user_session.id if @current_user_session
    session[:time_zone] = @current_user_session.user.time_zone if @current_user_session
    set_time_zone

    @current_user_session
  end

  def current_user
    current_user_session && current_user_session.user
  end

  def allow_tracking?
    "#{request.headers['X-Do-Not-Track']}" != '1' && "#{request.headers['DNT']}" != '1'
  end

  def logged_in?
    !!current_user
  end

  def require_login
    deny_user(nil, login_path) unless logged_in?
    deny_user("Your account has been suspended, please contact support", login_path) if logged_in? && current_user.suspended?
  end

  def require_completed_login
    redirect_to users_complete_path if current_user.incomplete?
  end

  def login(user, remember=false)
    reset_session
    @current_user_session = UserSession.create(user: user)
    current_user.track_sign_in(request.remote_ip) if allow_tracking?
    set_remember_cookie if remember
    session[:user_session_id] = current_user_session.id
    session[:time_zone] = current_user.time_zone
    set_time_zone
    current_user_session
  end

  def logout
    current_user_session.sign_out if current_user_session
    cookies.delete(:remember)
    reset_session
    @current_user_session = nil
  end

  def set_time_zone
    Time.zone = session[:time_zone] if session[:time_zone].present?
  end

  def set_current_user_session_from_remember_token
    token = cookies.signed[:remember]
    return if token.blank?
    @current_user_session = UserSession.active.where(remember_token: "#{token}").first
    @current_user_session
  end

  def set_remember_cookie
    cookies.permanent.signed[:remember] = {
      value: current_user_session.remember_token,
      secure: Rails.env.production?
    }
  end

  def redirect_back_or_default
    redirect_to(session.delete(:return_url) || root_path)
  end

  def deny_user(message=nil, location=nil)
    location ||= (logged_in? ? root_path : login_path)

    session[:return_url] = request.fullpath
    respond_to do |format|
      format.json { render(status: 403, nothing: true) }
      format.text { redirect_to(location) }
      format.html do
        flash[:error] = message || "Sorry, you must be logged in to do that"
        redirect_to(location)
      end
    end

    false
  end

  def record_not_unique
    respond_with(nil, location: root_path, status: 422)
  end
