# frozen_string_literal: true

# User for testing out the account locking on failure.
#
class LockableUser < User
  devise :verify_authenticatable, :verify_lockable, :database_authenticatable,
         :registerable, :recoverable, :rememberable, :trackable, :validatable,
         :lockable
end
