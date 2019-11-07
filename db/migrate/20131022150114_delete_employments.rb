class DeleteEmployments < ActiveRecord::Migration
  def up
    drop_table :employments
  end
  
  def down
    create_table :employments do |t|
      t.references :user
      t.references :employable, :polymorphic => true
      t.boolean :is_admin, default: false
      t.timestamps
    end
  end
end
