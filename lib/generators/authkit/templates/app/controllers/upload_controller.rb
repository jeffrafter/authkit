class UploadController < ApplicationController
  before_filter :require_login
  before_filter :require_advertiser, only: [:audio, :cover]
  before_filter :aws_key_to_remote_url, only: [:avatar]

  respond_to :json

  def audio
    @audio = current_user.audios.build(audio_params)

    # Each new upload needs to be unique in case the same file is uploaded twice with different content
    @audio.attachment_uploaded_at = Time.now

    if @audio.save
      respond_to do |format|
        format.json { render json: @audio }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @audio.errors }.to_json, status: 422 }
      end
    end
  end

  def cover
    @cover = current_user.covers.build(cover_params)

    # Each new upload needs to be unique in case the same file is uploaded twice with different content
    @cover.attachment_uploaded_at = Time.now

    if @cover.save
      respond_to do |format|
        format.json { render json: @cover }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @cover.errors }.to_json, status: 422 }
      end
    end
  end

  def avatar
    @avatar = current_user.build_avatar(avatar_params)

    # Each new upload needs to be unique in case the same file is uploaded twice with different content
    @avatar.attachment_uploaded_at = Time.now

    if current_user.save
      respond_to do |format|
        format.json { render json: @avatar }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @avatar.errors }.to_json, status: 422 }
      end
    end
  end

  protected

  def audio_params
    params.require(:audio).permit(:attachment)
  end

  def cover_params
    params.require(:cover).permit(:attachment)
  end

  def avatar_params
    params.require(:avatar).permit(:attachment, :remote_url)
  end

  def aws_key_to_remote_url
    params[:avatar] ||= {}
    params[:avatar][:remote_url] ||= view_context.aws_url_for(params[:key]) if params[:key].present?
  end

end
