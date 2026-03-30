class OrganizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization, only: [:show, :destroy]

  # GET /organizations
  # Lists all organizations the current user belongs to, with their role.
  # Uses includes to avoid N+1 when showing role badge in the view.
  def index
    @memberships = current_user.organization_memberships.includes(:organization)
  end

  # GET /organizations/:id
  # Shows org details + member list. Pundit enforces member-only access.
  # Uses includes(:user) on memberships to avoid N+1 per member row.
  def show
    authorize @organization
    @memberships = @organization.organization_memberships.includes(:user).order(:role)
    @current_membership = @organization.organization_memberships.find_by(user: current_user)
  end

  # POST /organizations
  # Creates a new org and auto-assigns creator as org_admin in a transaction.
  # The transaction ensures both records succeed or neither is persisted.
  def create
    @organization = Organization.new(organization_params)
    @organization.creator = current_user

    Organization.transaction do
      @organization.save!
      @organization.organization_memberships.create!(user: current_user, role: "org_admin")
    end

    redirect_to @organization, notice: "Organization \"#{@organization.name}\" was created successfully!"
  rescue ActiveRecord::RecordInvalid => e
    @memberships = current_user.organization_memberships.includes(:organization)
    flash.now[:alert] = e.message
    render :index, status: :unprocessable_entity
  end

  # DELETE /organizations/:id
  # Only org_admin can delete the organization.
  def destroy
    authorize @organization
    name = @organization.name
    @organization.destroy!
    redirect_to root_path, notice: "Organization \"#{name}\" was successfully deleted."
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name)
  end
end
