class DeviseVerifyAddTo<%= table_name.camelize %> < ActiveRecord::Migration<%= migration_version %>
  def self.up
    change_table :<%= table_name %> do |t|
      t.string    :verify_id
      t.datetime  :last_sign_in_with_verify
      t.boolean   :verify_enabled, :default => false
    end

    add_index :<%= table_name %>, :verify_id
  end

  def self.down
    change_table :<%= table_name %> do |t|
      t.remove :verify_id, :last_sign_in_with_verify, :verify_enabled
    end
  end
end

