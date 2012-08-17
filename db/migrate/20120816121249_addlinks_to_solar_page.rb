class AddlinksToSolarPage < ActiveRecord::Migration


  def change
    add_column :solar_pages, :links, :string
  end
end
