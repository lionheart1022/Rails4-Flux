class CreateFeatureFlags < ActiveRecord::Migration
  def change
    create_table :feature_flags do |t|
      t.datetime :created_at, null: false
      t.datetime :revoked_at
      t.references :resource, polymorphic: true, null: false
      t.string :identifier, null: false

      t.index [:resource_type, :resource_id, :identifier], name: "index_feature_flags_on_resource_and_identifier"
    end
  end
end
