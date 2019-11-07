class AddForceSslFlagOnTokens < ActiveRecord::Migration
  def change
    add_column :tokens, :force_ssl, :boolean, default: true, null: false
  end
end
