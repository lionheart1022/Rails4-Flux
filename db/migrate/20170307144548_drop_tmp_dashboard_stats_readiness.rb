class DropTmpDashboardStatsReadiness < ActiveRecord::Migration
  def change
    drop_table :tmp_dashboard_stats_readiness
  end
end
