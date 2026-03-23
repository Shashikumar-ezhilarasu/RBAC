module Organizations
  class MembershipsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_organization

    # POST /organizations/:organization_id/memberships
    # Adds a user as an instructor. org_admin only — Pundit enforces this.
    # Looks up the target user by email to keep the interface simple.
    def create
      authorize @organization, :add_member?

      target_user = User.find_by(email: membership_params[:email])

      if target_user.nil?
        redirect_to @organization, alert: "No user found with email \"#{membership_params[:email]}\"."
        return
      end

      membership = @organization.organization_memberships.build(user: target_user, role: "instructor")

      if membership.save
        redirect_to @organization, notice: "#{target_user.name} was added as an instructor."
      else
        redirect_to @organization, alert: membership.errors.full_messages.to_sentence
      end
    end

    private

    def set_organization
      @organization = Organization.find(params[:organization_id])
    end

    def membership_params
      params.require(:membership).permit(:email)
    end
  end
end
