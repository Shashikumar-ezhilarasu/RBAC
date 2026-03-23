# CircuitVerse GSoC POC — Organization + RBAC

> **Stack:** Ruby on Rails 8.1 (full-stack) · PostgreSQL · Devise · Pundit · ERB + Stimulus/Turbo

---

## Approach

Full-stack Rails app (not API-only) matching CircuitVerse's existing architecture. Auth is handled by Devise; authorization is enforced by Pundit policy objects. The frontend is pure ERB + Hotwire (Stimulus/Turbo) — no React, no separate frontend server. The "Add Instructor" form is **not rendered at all** for non-admins (not just hidden), providing defense-in-depth beyond what CSS alone offers.

---

## DB Design

```
┌──────────────────────┐       ┌────────────────────────────┐
│        users         │       │       organizations        │
├──────────────────────┤       ├────────────────────────────┤
│ id (PK)              │◄──┐   │ id (PK)                    │
│ name                 │   │   │ name                       │
│ email (unique)       │   └───│ created_by_id (FK→users)   │
│ encrypted_password   │       │ slug (unique, auto-gen)    │
│ created_at/updated_at│       │ created_at/updated_at      │
└──────────────────────┘       └────────────────────────────┘
           │                              │
           │    ┌─────────────────────────┘
           │    │
           ▼    ▼
┌────────────────────────────────────────┐
│        organization_memberships        │
├────────────────────────────────────────┤
│ id (PK)                                │
│ organization_id (FK)                   │
│ user_id (FK)                           │
│ role  ('org_admin' | 'instructor')     │
│ created_at/updated_at                  │
│ UNIQUE INDEX on (organization_id, user_id) │
└────────────────────────────────────────┘
```

---

## RBAC Logic

Policy: `app/policies/organization_policy.rb` (Pundit)

| Method | Who | Decision |
|---|---|---|
| `show?` | org_admin OR instructor | Any member can view the org |
| `add_member?` | org_admin ONLY | Instructors cannot add members |

```ruby
class OrganizationPolicy < ApplicationPolicy
  def show?
    member?          # org_admin or instructor
  end

  def add_member?
    org_admin?       # org_admin only
  end

  private

  def membership
    @membership ||= record.organization_memberships.find_by(user: user)
  end

  def member?    = membership.present?
  def org_admin? = membership&.role == "org_admin"
end
```

`Pundit::NotAuthorizedError` is rescued in `ApplicationController` and redirects with a flash alert — no 403 page, user stays in the app.

---

## File Structure

```
org-rbac-poc/
├── README.md                         ← this file
└── backend/                          ← Rails app
    ├── app/
    │   ├── controllers/
    │   │   ├── application_controller.rb       (Pundit, rescue_from)
    │   │   ├── organizations_controller.rb     (index, show, create)
    │   │   ├── organizations/
    │   │   │   └── memberships_controller.rb   (create — org_admin only)
    │   │   └── users/
    │   │       └── registrations_controller.rb (strong params: name)
    │   ├── models/
    │   │   ├── user.rb                         (Devise, associations)
    │   │   ├── organization.rb                 (auto-slug, validations)
    │   │   └── organization_membership.rb      (role validation, ROLES)
    │   ├── policies/
    │   │   ├── application_policy.rb           (Pundit base)
    │   │   └── organization_policy.rb          (show?, add_member?)
    │   ├── views/
    │   │   ├── layouts/application.html.erb    (navbar, flash)
    │   │   ├── organizations/
    │   │   │   ├── index.html.erb              (dashboard)
    │   │   │   └── show.html.erb               (org detail + members)
    │   │   └── users/
    │   │       ├── sessions/new.html.erb        (sign in)
    │   │       └── registrations/new.html.erb   (sign up)
    │   └── assets/stylesheets/application.css  (dark design system)
    ├── config/
    │   ├── routes.rb
    │   └── database.yml
    ├── db/
    │   ├── migrate/
    │   │   ├── *_devise_create_users.rb
    │   │   ├── *_create_organizations.rb
    │   │   └── *_create_organization_memberships.rb
    │   └── seeds.rb
    └── .env.example
```

---

## Setup Instructions

### Prerequisites
- Ruby 4.x (`brew install ruby`)
- PostgreSQL running locally
- Node.js + npm (for importmap assets — already bundled)

### Backend

```bash
cd backend

# 1. Install gem dependencies
bundle install

# 2. Copy env vars (edit if your PG credentials differ)
cp .env.example .env

# 3. Create DB, run migrations, seed test data
rails db:create db:migrate db:seed

# 4. Start the server
rails server
# → http://localhost:3000
```

### Seeded accounts (ready immediately after db:seed)

| Email | Password | Role |
|---|---|---|
| `alice@test.com` | `password123` | `org_admin` of ABC University |
| `bob@test.com` | `password123` | `instructor` of ABC University |

---

## Demo Flow

```
1. rails db:seed

2. Sign in as alice@test.com
   → Dashboard shows "ABC University" with org_admin badge
   → Click org → "Add Instructor" section IS visible

3. Sign out → Sign in as bob@test.com
   → Dashboard shows "ABC University" with instructor badge
   → Click org → "Add Instructor" section is NOT rendered at all

4. Test RBAC enforcement (as Bob, try via curl):
   POST /organizations/1/memberships  →  redirects with "Not authorized" flash
```

---

## What's Working (Current Status ✅)

- [x] Devise auth (sign up, sign in, sign out, with custom name field)
- [x] Organization create — auto-generates slug, auto-assigns org_admin role
- [x] Pundit policies — show? (member), add_member? (org_admin only)
- [x] Dashboard — lists all user orgs with role badge
- [x] Org detail page — member table, created date, slug
- [x] Add Instructor form — rendered only for org_admins (ERB conditional, not CSS hide)
- [x] Flash messages — success/error in styled components
- [x] DB migrations — all 3 pass cleanly
- [x] Seeds — alice + bob + ABC University seeded successfully

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Ruby on Rails 8.1 (full-stack) |
| Database | PostgreSQL |
| Auth | Devise 5 |
| Authorization | Pundit 2 |
| Frontend | ERB + Hotwire (Turbo + Stimulus) |
| Asset pipeline | Propshaft + Importmap |
