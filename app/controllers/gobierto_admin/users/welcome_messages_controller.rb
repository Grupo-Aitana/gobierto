module GobiertoAdmin
  class Users::WelcomeMessagesController < BaseController
    def create
      @user_welcome_message_form = UserWelcomeMessageForm.new(
        id: params[:user_id]
      )

      if @user_welcome_message_form.save
        flash[:notice] = "The message has been sent."
      else
        flash[:alert] = "The message could not be sent. Please try again."
      end

      redirect_to request.referrer
    end
  end
end