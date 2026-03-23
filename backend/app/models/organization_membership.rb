class OrganizationMembership < ApplicationRecord
  ROLES = %w[org_admin instructor].freeze

  belongs_to :organization
  belongs_to :user

  validates :role, presence: true, inclusion: { in: ROLES, message: "%{value} is not a valid role. Must be 'org_admin' or 'instructor'" }
  validates :user_id, uniqueness: { scope: :organization_id, message: "is already a member of this organization" }
end
