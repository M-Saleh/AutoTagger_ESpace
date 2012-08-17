class AddlinkToSolarPages < ActiveRecord::Migration
  def up
  end
def change
    add_column :solar_pages, :links, :string
  end
  def down
  end
end
