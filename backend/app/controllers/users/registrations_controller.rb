module Users
  class RegistrationsController < Devise::RegistrationsController
    private

    # Permit the name field in addition to Devise defaults
    def sign_up_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    def account_update_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password)
    end
  end
end
