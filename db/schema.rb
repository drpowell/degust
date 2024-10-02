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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181017031052) do

  create_table "de_settings", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "user_file_id"
    t.string   "name"
    t.string   "secure_id"
    t.string   "settings"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["secure_id"], name: "index_de_settings_on_secure_id"
    t.index ["user_file_id"], name: "index_de_settings_on_user_file_id"
    t.index ["user_id"], name: "index_de_settings_on_user_id"
  end

  create_table "user_files", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.string   "location"
    t.string   "content_type"
    t.string   "md5"
    t.integer  "size"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "provider"
    t.string   "uid"
    t.text     "extra"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.boolean  "admin"
    t.string   "upload_token"
  end

  create_table "visiteds", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "de_setting_id"
    t.datetime "last"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["de_setting_id"], name: "index_visiteds_on_de_setting_id"
    t.index ["user_id"], name: "index_visiteds_on_user_id"
  end

end
