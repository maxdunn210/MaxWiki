# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 40) do

  create_table "adults", :force => true do |t|
    t.string   "email",           :limit => 60, :default => ""
    t.string   "firstname",       :limit => 50
    t.string   "lastname",        :limit => 50
    t.integer  "household_id",                  :default => 0
    t.string   "home_phone",      :limit => 20
    t.string   "work_phone",      :limit => 20
    t.string   "cell_phone",      :limit => 20
    t.string   "relationship",    :limit => 50
    t.integer  "adultnum",                      :default => 0
    t.string   "login",           :limit => 80, :default => "",    :null => false
    t.string   "salted_password", :limit => 40, :default => "",    :null => false
    t.string   "salt",            :limit => 40, :default => "",    :null => false
    t.integer  "verified",                      :default => 0
    t.string   "role",            :limit => 40
    t.string   "security_token",  :limit => 40
    t.datetime "token_expiry"
    t.integer  "deleted",                       :default => 0
    t.datetime "delete_after"
    t.string   "company",         :limit => 60
    t.string   "question1"
    t.string   "question2"
    t.string   "question3"
    t.string   "question4"
    t.boolean  "paid",                          :default => false
    t.string   "paid_by",         :limit => 20
    t.integer  "wait_list_pos",                 :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "wiki_id"
    t.string   "auth_provider"
    t.text     "auth_extra"
  end

  create_table "doctors", :force => true do |t|
    t.integer "household_id",                  :default => 0
    t.string  "healthplan",     :limit => 100, :default => "", :null => false
    t.string  "policy_num",     :limit => 40,  :default => "", :null => false
    t.string  "physician_name", :limit => 50,  :default => "", :null => false
    t.string  "physician_tel",  :limit => 50,  :default => "", :null => false
    t.string  "physician_addr", :limit => 100, :default => "", :null => false
    t.integer "wiki_id"
  end

  create_table "emails", :force => true do |t|
    t.integer  "mailer_id"
    t.integer  "user_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "from"
    t.string   "to"
    t.integer  "last_send_attempt", :default => 0
    t.text     "mail"
    t.integer  "wiki_id"
  end

  create_table "events", :force => true do |t|
    t.string   "kind",              :limit => 40
    t.string   "name",              :limit => 40
    t.datetime "date_time"
    t.integer  "home_team_id"
    t.string   "note",              :limit => 200
    t.integer  "visitor_team_id"
    t.integer  "location_id"
    t.integer  "length"
    t.string   "home_team_note",    :limit => 200
    t.string   "visitor_team_note", :limit => 200
    t.integer  "wiki_id"
  end

  create_table "households", :force => true do |t|
    t.string  "address",                   :limit => 100
    t.string  "city",                      :limit => 100
    t.string  "zip",                       :limit => 20
    t.string  "session_id",                :limit => 80
    t.integer "wiki_id"
    t.float   "volunteer_feepaid",                        :default => 0.0
    t.date    "volunteer_feepaid_on"
    t.string  "volunteer_feepaid_by",      :limit => 20,  :default => ""
    t.float   "snackshack_deposit",                       :default => 0.0
    t.date    "snackshack_depositpaid_on"
    t.string  "snackshack_depositpaid_by", :limit => 20,  :default => ""
    t.float   "snackshack_refund",                        :default => 0.0
    t.date    "snackshack_refunded_on"
    t.string  "snackshack_refunded_by",    :limit => 20,  :default => ""
  end

  create_table "locations", :force => true do |t|
    t.string  "name"
    t.string  "short_name"
    t.integer "parent_location_id"
  end

  create_table "lookups", :force => true do |t|
    t.string  "kind",          :limit => 40
    t.string  "name",          :limit => 40
    t.string  "short_name",    :limit => 10
    t.integer "display_order"
    t.string  "page_name",     :limit => 100
    t.integer "wiki_id"
  end

  create_table "mailer_groups", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.string  "user_filter"
    t.boolean "auto_subscribe"
    t.integer "wiki_id"
  end

  create_table "mailer_subscriptions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "mailer_group_id"
    t.boolean  "subscribed"
    t.datetime "updated_at"
    t.string   "updated_by"
    t.integer  "wiki_id"
  end

  create_table "mailers", :force => true do |t|
    t.string  "name"
    t.string  "subject"
    t.string  "page"
    t.string  "additional_filter"
    t.integer "mailer_group_id"
    t.integer "wiki_id"
  end

  create_table "old_survey_answers", :force => true do |t|
    t.integer  "survey_id"
    t.integer  "survey_question_id"
    t.string   "response"
    t.integer  "user_id"
    t.string   "submitter_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "wiki_id"
  end

  add_index "old_survey_answers", ["id"], :name => "id"

  create_table "pages", :force => true do |t|
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
    t.integer  "wiki_id",                                                :null => false
    t.string   "locked_by",          :limit => 60
    t.string   "name",               :limit => 60
    t.datetime "locked_at"
    t.string   "access_read",        :limit => 40, :default => "Public"
    t.string   "access_write",       :limit => 40, :default => "Editor"
    t.string   "access_permissions", :limit => 40, :default => "Admin"
    t.string   "kind"
    t.string   "link"
    t.integer  "parent_id"
  end

  create_table "players", :force => true do |t|
    t.integer  "household_id",                        :default => 0
    t.string   "firstname",            :limit => 50,  :default => "",    :null => false
    t.string   "lastname",             :limit => 50,  :default => "",    :null => false
    t.date     "birthday",                                               :null => false
    t.integer  "years_exp"
    t.string   "lastlevel",            :limit => 20
    t.string   "grade",                :limit => 20
    t.string   "school",               :limit => 40
    t.string   "teacher",              :limit => 40
    t.string   "note"
    t.string   "shirtsize",            :limit => 20
    t.string   "pantsize",             :limit => 20
    t.string   "limitation",           :limit => 100
    t.string   "allergies",            :limit => 100, :default => "",    :null => false
    t.boolean  "age_checked"
    t.boolean  "waiver_required"
    t.float    "fee_paid",                            :default => 0.0
    t.date     "fee_paid_on"
    t.string   "fee_paid_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "referred_by"
    t.integer  "team_id"
    t.boolean  "address_checked",                     :default => false
    t.boolean  "form_printed",                        :default => false
    t.boolean  "signed_form_received",                :default => false
    t.boolean  "info_checked"
    t.integer  "wiki_id"
    t.boolean  "tryout_required",                     :default => false
    t.date     "tryout_date"
    t.string   "remarks",              :limit => 100, :default => ""
  end

  create_table "revisions", :force => true do |t|
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.datetime "revised_at",                 :null => false
    t.integer  "page_id",                    :null => false
    t.text     "content",                    :null => false
    t.string   "author",       :limit => 60
    t.string   "ip",           :limit => 60
    t.integer  "wiki_id"
    t.string   "content_type"
  end

  add_index "revisions", ["author"], :name => "revisions_author_index"
  add_index "revisions", ["created_at"], :name => "revisions_created_at_index"
  add_index "revisions", ["page_id"], :name => "revisions_page_id_index"

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.binary   "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"

  create_table "survey_answers", :force => true do |t|
    t.integer "survey_id"
    t.integer "survey_response_id"
    t.integer "survey_question_id"
    t.string  "answer"
    t.integer "wiki_id"
  end

  create_table "survey_answers_hide", :force => true do |t|
    t.integer  "survey_id"
    t.integer  "survey_question_id"
    t.string   "response"
    t.integer  "user_id"
    t.string   "submitter_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "wiki_id"
  end

  create_table "survey_questions", :force => true do |t|
    t.string  "name"
    t.string  "question"
    t.integer "display_order"
    t.integer "survey_id"
    t.string  "input_type"
    t.string  "choices"
    t.boolean "mandatory"
    t.string  "html_options"
    t.integer "wiki_id"
  end

  create_table "survey_responses", :force => true do |t|
    t.integer  "survey_id"
    t.integer  "user_id"
    t.string   "session_id"
    t.string   "submitter_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "wiki_id"
  end

  create_table "surveys", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.string  "submit_page"
    t.integer "wiki_id"
  end

  create_table "system", :force => true do |t|
    t.string "name"
    t.string "description"
    t.text   "config"
    t.string "read_only_mode"
    t.string "read_only_msg"
  end

  create_table "teams", :force => true do |t|
    t.string  "name",      :limit => 40
    t.string  "manager",   :limit => 60
    t.integer "level_id"
    t.integer "league_id"
    t.string  "page_name", :limit => 100
    t.integer "wiki_id"
  end

  create_table "usages", :force => true do |t|
    t.integer "location_id"
    t.float   "value"
    t.string  "kind"
  end

  create_table "wiki_files", :force => true do |t|
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.integer  "wiki_id",              :null => false
    t.string   "file_name"
    t.string   "description"
    t.string   "source_uri"
    t.string   "source_type"
    t.string   "detect_change_marker"
    t.string   "detect_change_type"
    t.string   "cache_path"
    t.string   "converted_path"
    t.string   "converted_type"
    t.string   "refresh_method"
    t.datetime "last_check"
  end

  create_table "wiki_references", :force => true do |t|
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "page_id",                       :null => false
    t.string   "referenced_name", :limit => 60, :null => false
    t.string   "link_type",       :limit => 1,  :null => false
    t.integer  "wiki_id"
  end

  add_index "wiki_references", ["page_id"], :name => "wiki_references_page_id_index"
  add_index "wiki_references", ["referenced_name"], :name => "wiki_references_referenced_name_index"

  create_table "wikis", :force => true do |t|
    t.datetime "created_at",                                              :null => false
    t.datetime "updated_at",                                              :null => false
    t.string   "description",        :limit => 60,                        :null => false
    t.string   "name",               :limit => 60,                        :null => false
    t.string   "additional_style"
    t.integer  "allow_uploads",                    :default => 1
    t.integer  "published",                        :default => 0
    t.integer  "count_pages",                      :default => 0
    t.string   "markup",             :limit => 50, :default => "textile"
    t.string   "color",              :limit => 6,  :default => "008B26"
    t.integer  "max_upload_size",                  :default => 100
    t.integer  "safe_mode",                        :default => 0
    t.integer  "brackets_only",                    :default => 0
    t.text     "config"
    t.integer  "wiki_file_next_num",               :default => 0
  end

end
