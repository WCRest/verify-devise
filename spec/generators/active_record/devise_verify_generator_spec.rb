# frozen_string_literal: true
require "generators/active_record/devise_verify_generator"

RSpec.describe ActiveRecord::Generators::DeviseVerifyGenerator, type: :generator do
  destination File.expand_path("../../tmp", __FILE__)

  after(:all) do
    prepare_destination
  end

  before(:all) do
    prepare_destination
    run_generator ["user"]
  end

  it "copies the migration file across" do
    expect(destination_root).to have_structure {
      directory "db" do
        directory "migrate" do
          migration "devise_verify_add_to_users.rb" do
            contains "DeviseVerifyAddToUsers"
            contains "ActiveRecord::Migration[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
          end
        end
      end
    }
  end
end