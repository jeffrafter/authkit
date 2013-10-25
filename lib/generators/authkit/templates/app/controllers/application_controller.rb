
  before_filter :set_time_zone

  helper_method :logged_in?, :current_user

  # It is very unlikely that this exception will be created under normal
  # circumstances. Unique validations are handled in Rails, but they are
  # also enforced at the database level to guarantee data integrity. In
  # certain cases (double-clicking a save link, multiple distributed servers)
  # it is possible to get past the Rails validation in which case the
  # database throws an exception.
  rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique

  protected

  def current_user
    return @current_user if defined?(@current_user)
    @current_user ||= User.find_by(session[:user_id]) if session[:user_id]
    @current_user ||= User.user_from_remember_token(cookies.signed[:remember]) unless cookies.signed[:remember].blank?
    session[:user_id] = @current_user.id if @current_user
    session[:time_zone] = @current_user.time_zone if @current_user
    set_time_zone

    @current_user
  end

  def allow_tracking?
    "#{request.headers['X-Do-Not-Track']}" != '1' && "#{request.headers['DNT']}" != '1'
  end

  def logged_in?
    !!current_user
  end

  def require_login
    deny_user(nil, login_path) unless logged_in?
  end

  def require_token
    deny_user("Invalid token", root_path) unless @user = User.user_from_token(params[:token])
  end

  def login(user)
    @current_user = user
    current_user.track_sign_in(request.remote_ip) if allow_tracking?
    current_user.set_token(:remember_token)
    set_remember_cookie
    reset_session
    session[:user_id] = current_user.id
    session[:time_zone] = current_user.time_zone
    set_time_zone
    current_user
  end

  def logout
    current_user.clear_remember_token if current_user
    cookies.delete(:remember)
    reset_session
    @current_user = nil
  end

  def set_time_zone
    Time.zone = session[:time_zone] if session[:time_zone].present?
  end

  def set_remember_cookie
    cookies.permanent.signed[:remember] = {
      value: current_user.remember_token,
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
