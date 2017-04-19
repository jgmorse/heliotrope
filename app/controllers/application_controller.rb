class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior

  # Adds CurationConcerns behaviors to the application controller.
  include CurationConcerns::ApplicationControllerBehavior
  include CurationConcerns::ThemedLayoutController
  with_themed_layout '1_column'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from ActiveFedora::ObjectNotFoundError, with: :render_unauthorized
  # rescue_from ActiveFedora::ActiveFedoraError, with: :render_unauthorized
  rescue_from ActiveRecord::RecordNotFound, with: :render_unauthorized

  protected

    def render_unauthorized(_exception)
      respond_to do |format|
        format.html { render 'curation_concerns/base/unauthorized', status: :unauthorized }
        format.any { head :unauthorized, content_type: 'text/plain' }
      end
    end
end
