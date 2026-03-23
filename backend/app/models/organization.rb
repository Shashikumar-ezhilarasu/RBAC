class Organization < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id

  has_many :organization_memberships, dependent: :destroy
  has_many :members, through: :organization_memberships, source: :user

  validates :name, presence: true, length: { minimum: 2, maximum: 200 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers and hyphens" }

  before_validation :generate_slug, on: :create

  private

  # Auto-generate a URL-friendly slug from the org name before saving.
  # Downcases, strips non-alphanumeric chars, replaces spaces with dashes.
  def generate_slug
    return if name.blank?

    base_slug = name.downcase.strip.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").squeeze("-")
    candidate = base_slug
    counter = 1

    while Organization.exists?(slug: candidate)
      candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate
  end
end
