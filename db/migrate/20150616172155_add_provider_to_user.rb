class AddProviderToUser < ActiveRecord::Migration
  def change
    add_column :users, :provider, :string
    add_column :users, :unconfirmed_ccid, :string
  end
end
