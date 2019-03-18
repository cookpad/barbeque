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

ActiveRecord::Schema.define(version: 2019_03_15_052951) do

  create_table "barbeque_apps", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.string "docker_image", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_barbeque_apps_on_name", unique: true
  end

  create_table "barbeque_docker_containers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "message_id", null: false
    t.string "container_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_barbeque_docker_containers_on_message_id", unique: true
  end

  create_table "barbeque_ecs_hako_tasks", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "message_id", null: false
    t.string "cluster", null: false
    t.string "task_arn", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_barbeque_ecs_hako_tasks_on_message_id", unique: true
  end

  create_table "barbeque_job_definitions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "job", null: false
    t.integer "app_id", null: false
    t.string "command", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job", "app_id"], name: "index_barbeque_job_definitions_on_job_and_app_id", unique: true
  end

  create_table "barbeque_job_executions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "message_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "job_definition_id"
    t.datetime "finished_at"
    t.integer "job_queue_id"
    t.index ["created_at"], name: "index_barbeque_job_executions_on_created_at"
    t.index ["job_definition_id"], name: "index_barbeque_job_executions_on_job_definition_id"
    t.index ["message_id"], name: "index_barbeque_job_executions_on_message_id", unique: true
    t.index ["status"], name: "index_barbeque_job_executions_on_status"
  end

  create_table "barbeque_job_queues", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "queue_url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_barbeque_job_queues_on_name", unique: true
  end

  create_table "barbeque_job_retries", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "message_id", null: false
    t.integer "job_execution_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_barbeque_job_retries_on_message_id", unique: true
    t.index ["status"], name: "index_barbeque_job_retries_on_status"
  end

  create_table "barbeque_retry_configs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "job_definition_id", null: false
    t.integer "retry_limit", default: 3, null: false
    t.float "base_delay", default: 15.0, null: false
    t.integer "max_delay"
    t.boolean "jitter", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_definition_id"], name: "index_barbeque_retry_configs_on_job_definition_id", unique: true
  end

  create_table "barbeque_slack_notifications", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.integer "job_definition_id"
    t.string "channel", null: false
    t.boolean "notify_success", default: false, null: false
    t.string "failure_notification_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "notify_failure_only_if_retry_limit_reached", default: false, null: false
  end

  create_table "barbeque_sns_subscriptions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "topic_arn", null: false
    t.integer "job_queue_id", null: false
    t.integer "job_definition_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
