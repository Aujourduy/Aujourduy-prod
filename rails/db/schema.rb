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

ActiveRecord::Schema[8.0].define(version: 2025_11_15_174845) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "event_occurrence_teachers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "event_occurrence_id", null: false
    t.uuid "teacher_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_occurrence_id", "teacher_id"], name: "index_event_occurrence_teachers_on_occurrence_and_teacher", unique: true
    t.index ["event_occurrence_id"], name: "index_event_occurrence_teachers_on_event_occurrence_id"
    t.index ["teacher_id"], name: "index_event_occurrence_teachers_on_teacher_id"
  end

  create_table "event_occurrences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "event_id", null: false
    t.uuid "venue_id"
    t.date "start_date"
    t.time "start_time"
    t.time "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "override_title"
    t.text "override_description"
    t.decimal "override_price_normal", precision: 8, scale: 2
    t.decimal "override_price_reduced", precision: 8, scale: 2
    t.string "override_currency"
    t.string "status", default: "active"
    t.boolean "is_override", default: false
    t.string "recurrence_id"
    t.string "override_source_url"
    t.date "end_date"
    t.index ["event_id"], name: "index_event_occurrences_on_event_id"
    t.index ["is_override"], name: "index_event_occurrences_on_is_override"
    t.index ["recurrence_id"], name: "index_event_occurrences_on_recurrence_id"
    t.index ["status"], name: "index_event_occurrences_on_status"
    t.index ["venue_id"], name: "index_event_occurrences_on_venue_id"
  end

  create_table "events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "title"
    t.text "description"
    t.decimal "price_normal"
    t.decimal "price_reduced"
    t.string "currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "recurrence_rule"
    t.date "recurrence_end_date"
    t.boolean "is_recurring", default: false
    t.uuid "principal_teacher_id"
    t.string "status", default: "active"
    t.uuid "practice_id", null: false
    t.string "source_url"
    t.uuid "teacher_url_id"
    t.boolean "is_online", default: false, null: false
    t.string "online_url"
    t.index ["is_recurring"], name: "index_events_on_is_recurring"
    t.index ["practice_id"], name: "index_events_on_practice_id"
    t.index ["principal_teacher_id"], name: "index_events_on_principal_teacher_id"
    t.index ["teacher_url_id"], name: "index_events_on_teacher_url_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "practices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["name"], name: "index_practices_on_name", unique: true
    t.index ["user_id"], name: "index_practices_on_user_id"
  end

  create_table "scraped_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "source_url", null: false
    t.uuid "teacher_url_id"
    t.datetime "scraped_at", precision: nil, null: false
    t.integer "scraping_duration_ms"
    t.text "html_content"
    t.jsonb "json_data", null: false
    t.string "status", default: "pending", null: false
    t.text "validation_notes"
    t.uuid "validated_by_user_id"
    t.datetime "validated_at", precision: nil
    t.uuid "imported_event_id"
    t.datetime "imported_at", precision: nil
    t.text "import_error"
    t.decimal "confidence_score", precision: 5, scale: 2
    t.jsonb "quality_flags", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "imported_by_user_id"
    t.index ["imported_by_user_id"], name: "index_scraped_events_on_imported_by_user_id"
    t.index ["imported_event_id"], name: "index_scraped_events_on_imported_event_id"
    t.index ["scraped_at"], name: "index_scraped_events_on_scraped_at"
    t.index ["source_url"], name: "index_scraped_events_on_source_url"
    t.index ["status"], name: "index_scraped_events_on_status"
    t.index ["teacher_url_id"], name: "index_scraped_events_on_teacher_url_id"
    t.index ["validated_by_user_id"], name: "index_scraped_events_on_validated_by_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "teacher_practices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "teacher_id", null: false
    t.uuid "practice_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["practice_id"], name: "index_teacher_practices_on_practice_id"
    t.index ["teacher_id", "practice_id"], name: "index_teacher_practices_on_teacher_id_and_practice_id", unique: true
    t.index ["teacher_id"], name: "index_teacher_practices_on_teacher_id"
  end

  create_table "teacher_urls", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "teacher_id", null: false
    t.string "url", null: false
    t.string "name"
    t.datetime "last_scraped_at"
    t.boolean "is_active", default: true, null: false
    t.jsonb "scraping_config", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_scraping_duration"
    t.datetime "start_scraping_at"
    t.datetime "end_scraping_at"
    t.string "last_scraping_status"
    t.text "last_scraping_error_details"
    t.index ["teacher_id", "url"], name: "index_teacher_urls_on_teacher_id_and_url", unique: true
    t.index ["teacher_id"], name: "index_teacher_urls_on_teacher_id"
  end

  create_table "teachers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.text "bio"
    t.string "contact_email"
    t.string "phone"
    t.string "photo_url"
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "photo_cloudinary_id"
    t.string "reference_url"
    t.index ["photo_cloudinary_id"], name: "index_teachers_on_photo_cloudinary_id"
    t.index ["user_id"], name: "index_teachers_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "phone"
    t.datetime "phone_validated_at"
    t.string "country_code"
    t.string "google_uid"
    t.string "google_email"
    t.string "google_avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar_cloudinary_id"
    t.datetime "phone_verification_last_sent_at"
    t.integer "phone_verification_attempts"
    t.string "first_name"
    t.string "last_name"
    t.boolean "is_admin"
    t.jsonb "favorite_cities", default: []
    t.jsonb "favorite_countries", default: []
    t.jsonb "favorite_teacher_ids", default: []
    t.string "search_keywords"
    t.string "filter_mode", default: "union"
    t.uuid "favorite_practice_ids", default: [], array: true
    t.index ["avatar_cloudinary_id"], name: "index_users_on_avatar_cloudinary_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["phone_validated_at"], name: "index_users_on_phone_validated_at"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "venues", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "address_line1"
    t.string "address_line2"
    t.string "postal_code"
    t.string "city"
    t.string "region"
    t.string "country"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.string "departement"
    t.string "department_code"
    t.string "department_name"
    t.index ["user_id"], name: "index_venues_on_user_id"
  end

  add_foreign_key "event_occurrence_teachers", "event_occurrences"
  add_foreign_key "event_occurrence_teachers", "teachers"
  add_foreign_key "event_occurrences", "events"
  add_foreign_key "event_occurrences", "venues"
  add_foreign_key "events", "practices"
  add_foreign_key "events", "teacher_urls", on_delete: :nullify
  add_foreign_key "events", "teachers", column: "principal_teacher_id"
  add_foreign_key "events", "users"
  add_foreign_key "practices", "users"
  add_foreign_key "scraped_events", "events", column: "imported_event_id", on_delete: :nullify
  add_foreign_key "scraped_events", "teacher_urls", on_delete: :nullify
  add_foreign_key "scraped_events", "users", column: "imported_by_user_id"
  add_foreign_key "scraped_events", "users", column: "validated_by_user_id", on_delete: :nullify
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "teacher_practices", "practices"
  add_foreign_key "teacher_practices", "teachers"
  add_foreign_key "teacher_urls", "teachers"
  add_foreign_key "teachers", "users"
  add_foreign_key "venues", "users"
end
