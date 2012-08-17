# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120816121850) do


  create_table "solar_pages", :force => true do |t|
    t.integer  "page_id"
    t.string   "page_title"
    t.string   "s_d_title"
    t.integer  "page_type"
    t.integer  "incoming"
    t.integer  "outgoing"
    t.string   "en_form"
    t.integer  "link_occur"
    t.integer  "text_occur"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "links"
  end

  create_table "system_settings", :force => true do |t|
    t.date "wikipedia_last", :default => '2012-07-27'
  end


end
