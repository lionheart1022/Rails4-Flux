class AddStateToPriceDocuments < ActiveRecord::Migration
  def change
    add_column :price_documents, :state, :string
  end
end
