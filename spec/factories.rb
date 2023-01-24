# frozen_string_literal: true

FactoryBot.define do
  sequence :email do |n|
    "person#{n}@example.com"
  end

  sequence :verify_id do |n|
    n.to_s
  end

  factory :user do
    email { generate(:email) }
    password { "correct horse battery staple" }

    factory :verify_user do
      verify_id { generate(:verify_id) }
      verify_enabled { true }
    end
  end

  factory :lockable_user, class: LockableUser do
    email { generate(:email) }
    password { "correct horse battery staple" }
  end

  factory :lockable_verify_user, class: LockableUser do
    email { generate(:email) }
    password { "correct horse battery staple" }
    verify_id { generate(:verify_id) }
    verify_enabled { true }
  end
end