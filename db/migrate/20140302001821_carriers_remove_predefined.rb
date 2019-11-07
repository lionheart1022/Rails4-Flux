class CarriersRemovePredefined < ActiveRecord::Migration
  def up
    remove_column(:carriers, :is_predefined_carrier)
  end

  def down
    add_column(:carriers, :is_predefined_carrier, :boolean)
  end
end
