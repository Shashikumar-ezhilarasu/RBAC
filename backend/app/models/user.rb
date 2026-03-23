class User < ApplicationRecord
  # Devise modules: database_authenticatable handles email/password,
  # registerable allows signup, recoverable enables password reset,
  # rememberable for persistent sessions, validatable auto-validates email/password format
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }

  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships
  has_many :created_organizations, class_name: "Organization", foreign_key: :created_by_id, dependent: :nullify
end
