json.extract! teacher, :id, :first_name, :last_name, :bio, :contact_email, :phone, :photo_url, :user_id, :created_at, :updated_at
json.url teacher_url(teacher, format: :json)
