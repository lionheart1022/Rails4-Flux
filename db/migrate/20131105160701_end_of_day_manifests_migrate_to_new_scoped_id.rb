class EndOfDayManifestsMigrateToNewScopedId < ActiveRecord::Migration
  def up
    add_column(:end_of_day_manifests, :end_of_day_manifest_id, :integer)

    Customer.all.each do |customer|
      customer.end_of_day_manifests.order(:id).each_with_index do |end_of_day_manifest, idx|
        end_of_day_manifest.end_of_day_manifest_id = idx+1
        end_of_day_manifest.save!
      end

      customer.current_end_of_day_manifest_id = customer.end_of_day_manifests.count
      customer.save!
    end
  end

  def down
    remove_column(:end_of_day_manifests, :end_of_day_manifest_id)
  end
end
