class CreateEmployments < ActiveRecord::Migration
  def change
    create_table :employments do |t|
      t.references :user
      t.references :employable, :polymorphic => true
      t.timestamps
    end
  end
end
