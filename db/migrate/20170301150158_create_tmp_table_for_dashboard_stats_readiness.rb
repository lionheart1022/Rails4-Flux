class CreateTmpTableForDashboardStatsReadiness < ActiveRecord::Migration
  def change
    create_table :tmp_dashboard_stats_readiness do |t|
      t.references :company
      t.boolean :ready, null: false, default: false
    end
  end
end
