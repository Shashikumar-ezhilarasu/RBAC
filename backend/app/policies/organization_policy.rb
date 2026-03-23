class OrganizationPolicy < ApplicationPolicy
  # Both org_admin and instructor are considered members and can view the org.
  # A non-member (even a logged-in user) should NOT be able to see this org.
  def show?
    member?
  end

  # Only org_admin can add new instructors to an organization.
  # Instructors have read-only access; they cannot modify org membership.
  def add_member?
    org_admin?
  end

  # Only org_admin can create new memberships (same permission as add_member?)
  def create?
    org_admin?
  end

  private

  # Memoized lookup of the current user's membership in this organization.
  # Uses find_by to return nil (not raise) if no membership exists.
  def membership
    @membership ||= record.organization_memberships.find_by(user: user)
  end

  # A user is a member if they have ANY membership (org_admin or instructor).
  def member?
    membership.present?
  end

  # A user is an org_admin only if their specific role is 'org_admin'.
  def org_admin?
    membership&.role == "org_admin"
  end
end
