module Organizations
  class MembershipsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_organization

    # POST /organizations/:organization_id/memberships
    # Adds a user as an instructor.
    # If the user doesn't exist, they are created with a default password.
    def create
      authorize @organization, :add_member?

      email = membership_params[:email].to_s.strip.downcase
      name  = membership_params[:name].to_s.strip

      if email.blank?
        redirect_to @organization, alert: "Email is required to add an instructor."
        return
      end

      # Find user or create a new one with a default password
      target_user = User.find_by(email: email)
      is_new_user = false

      if target_user.nil?
        if name.blank?
          redirect_to @organization, alert: "Please provide a name for the new user."
          return
        end

        target_user = User.new(
          email: email,
          name: name,
          password: "password123",
          password_confirmation: "password123"
        )

        unless target_user.save
          redirect_to @organization, alert: "Failed to create user: #{target_user.errors.full_messages.to_sentence}"
          return
        end
        is_new_user = true
      end

      # Check if already a member
      if @organization.members.exists?(target_user.id)
        redirect_to @organization, alert: "#{target_user.name} is already a member of this organization."
        return
      end

      membership = @organization.organization_memberships.build(user: target_user, role: "instructor")

      if membership.save
        msg = "#{target_user.name} was added as an instructor."
        msg += " Since they are new, their temporary password is 'password123'." if is_new_user
        redirect_to @organization, notice: msg
      else
        redirect_to @organization, alert: membership.errors.full_messages.to_sentence
      end
    end

    # DELETE /organizations/:organization_id/memberships/:id
    # Removes a member from the organization.
    def destroy
      authorize @organization, :remove_member?

      membership = @organization.organization_memberships.find(params[:id])

      # Prevents admins from accidentally removing themselves!
      if membership.user_id == current_user.id
        redirect_to @organization, alert: "You cannot remove yourself from the organization."
        return
      end

      target_name = membership.user.name
      membership.destroy!

      redirect_to @organization, notice: "#{target_name} was removed from the organization."
    rescue ActiveRecord::RecordNotFound
      redirect_to @organization, alert: "Member not found."
    end

    private

    def set_organization
      @organization = Organization.find(params[:organization_id])
    end

    def membership_params
      params.require(:membership).permit(:email, :name)
    end
  end
end
