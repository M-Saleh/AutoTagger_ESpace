class CreateSolarPages < ActiveRecord::Migration
  def change
    create_table :solar_pages do |t|
      t.integer :page_id
      t.string :page_title
      t.string :s_d_title
      t.integer :page_type
      t.integer :incoming
      t.integer :outgoing
      t.string :en_form
      t.integer :link_occur
      t.integer :text_occur

      t.timestamps
    end
  end
end
