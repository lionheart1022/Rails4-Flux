class AddExternalAccountingNumberToEntityRelations < ActiveRecord::Migration
  def change
    add_column :entity_relations, :external_accounting_number, :string
  end
end
