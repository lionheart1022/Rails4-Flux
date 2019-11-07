class AddStateAndDownloadUrlToReports < ActiveRecord::Migration
  def change
    add_column :reports, :state, :string
    add_column :reports, :download_url, :string
  end
end
