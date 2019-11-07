class CreateCentralLoginPages < ActiveRecord::Migration
  def change
    create_table :central_login_pages do |t|
      t.timestamps null: false
      t.string :title, null: false
      t.string :domain, null: false, index: { unique: true }
      t.references :primary_item
    end

    create_table :central_login_page_items do |t|
      t.timestamps null: false
      t.references :page, null: false
      t.references :company, null: false
      t.integer :sort_order
    end
  end
end
