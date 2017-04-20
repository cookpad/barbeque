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

ActiveRecord::Schema.define(version: 20170420030157) do

  create_table "barbeque_apps", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC" do |t|
    t.string   "name",                       null: false
    t.string   "docker_image",               null: false
    t.text     "description",  limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["name"], name: "index_barbeque_apps_on_name", unique: true, using: :btree
  end

  create_table "barbeque_job_definitions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC" do |t|
    t.string   "job",                       null: false
    t.integer  "app_id",                    null: false
    t.string   "command",                   null: false
    t.text     "description", limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["job", "app_id"], name: "index_barbeque_job_definitions_on_job_and_app_id", unique: true, using: :btree
  end

  create_table "barbeque_job_executions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC" do |t|
    t.string   "message_id",                    null: false
    t.integer  "status",            default: 0, null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "job_definition_id"
    t.datetime "finished_at"
    t.integer  "job_queue_id"
    t.index ["job_definition_id"], name: "index_barbeque_job_executions_on_job_definition_id", using: :btree
    t.index ["message_id"], name: "index_barbeque_job_executions_on_message_id", unique: true, using: :btree
  end

  create_table "barbeque_job_queues", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC" do |t|
    t.string   "name",                      null: false
    t.text     "description", limit: 65535
    t.string   "queue_url",                 null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["name"], name: "index_barbeque_job_queues_on_name", unique: true, using: :btree
  end

  create_table "barbeque_job_retries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC" do |t|
    t.string   "message_id",                   null: false
    t.integer  "job_execution_id",             null: false
    t.integer  "status",           default: 0, null: false
    t.datetime "finished_at"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.index ["message_id"], name: "index_barbeque_job_retries_on_message_id", unique: true, using: :btree
  end

  create_table "barbeque_slack_notifications", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC" do |t|
    t.integer  "job_definition_id"
    t.string   "channel",                                   null: false
    t.boolean  "notify_success",            default: false, null: false
    t.string   "failure_notification_text"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  create_table "barbeque_sns_subscriptions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "topic_arn",         null: false
    t.integer  "job_queue_id",      null: false
    t.integer  "job_definition_id", null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

end
