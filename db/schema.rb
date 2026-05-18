# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2018_10_17_031052) do
  create_table "de_settings", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "name"
    t.string "secure_id"
    t.string "settings"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_file_id"
    t.integer "user_id"
    t.index ["secure_id"], name: "index_de_settings_on_secure_id"
    t.index ["user_file_id"], name: "index_de_settings_on_user_file_id"
    t.index ["user_id"], name: "index_de_settings_on_user_id"
  end

  create_table "user_files", force: :cascade do |t|
    t.string "content_type"
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.string "location"
    t.string "md5"
    t.string "name"
    t.integer "size"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin"
    t.datetime "created_at", precision: nil, null: false
    t.text "extra"
    t.string "name"
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", precision: nil, null: false
    t.string "upload_token"
  end

  create_table "visiteds", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "de_setting_id"
    t.datetime "last", precision: nil
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["de_setting_id"], name: "index_visiteds_on_de_setting_id"
    t.index ["user_id"], name: "index_visiteds_on_user_id"
  end
end
