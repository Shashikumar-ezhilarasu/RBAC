# This seed file demonstrates both RBAC roles so mentors can test immediately.
# Run: rails db:seed
# Login credentials after seeding:
#   alice@test.com / password123  → org_admin of "ABC University"
#   bob@test.com   / password123  → instructor of "ABC University"

puts "Cleaning up existing seed data..."
OrganizationMembership.delete_all
Organization.delete_all
User.delete_all

puts "Creating users..."

# User A — will become org_admin
alice = User.create!(
  name: "Alice",
  email: "alice@test.com",
  password: "password123",
  password_confirmation: "password123"
)

# User B — will be added as instructor
bob = User.create!(
  name: "Bob",
  email: "bob@test.com",
  password: "password123",
  password_confirmation: "password123"
)

puts "Creating organization..."

# Alice creates "ABC University" — slug auto-generated as "abc-university"
org = Organization.create!(
  name: "ABC University",
  creator: alice
)

puts "Creating memberships..."

# Alice is org_admin (creator role — can add members, view org)
OrganizationMembership.create!(
  organization: org,
  user: alice,
  role: "org_admin"
)

# Bob is instructor (read-only — can view org, cannot add members)
OrganizationMembership.create!(
  organization: org,
  user: bob,
  role: "instructor"
)

puts ""
puts "✅ Seed complete!"
puts ""
puts "  alice@test.com / password123  →  org_admin  of '#{org.name}' (slug: #{org.slug})"
puts "  bob@test.com   / password123  →  instructor of '#{org.name}'"
puts ""
puts "Demo flow:"
puts "  1. Sign in as Alice → she sees 'Add Instructor' form on the org page"
puts "  2. Sign in as Bob   → form is NOT rendered (Pundit + ERB conditional)"
