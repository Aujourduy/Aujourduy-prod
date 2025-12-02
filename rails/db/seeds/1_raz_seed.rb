# db/seeds.rb

puts "🔥 Nettoyage complet de la base..."
EventOccurrence.destroy_all
Event.destroy_all
Venue.destroy_all
Teacher.destroy_all
Practice.destroy_all
User.destroy_all
puts "✅ Base nettoyée."


User.create!([
  {email: "au.jour.duy@gmail.com", encrypted_password: "$2a$12$wb3LNfISIPcQNEOtomc2segs8cEFC8MrcYMGHZMptyxAWKCzJrpBy", reset_password_token: nil, reset_password_sent_at: nil, remember_created_at: nil, sign_in_count: 0, current_sign_in_at: nil, last_sign_in_at: nil, current_sign_in_ip: nil, last_sign_in_ip: nil, phone: nil, phone_validated_at: nil, country_code: nil, google_uid: "109045208922376926909", google_email: nil, google_avatar_url: "https://lh3.googleusercontent.com/a/ACg8ocLRkSW20DXAesezPJmmRfOif4QtvrsX7K9LiU7Rv66KC_uWFZnt", avatar_cloudinary_id: nil, phone_verification_last_sent_at: nil, phone_verification_attempts: nil, first_name: "Au Jour", last_name: "Duy", is_admin: true, favorite_cities: [], favorite_countries: [], favorite_teacher_ids: [], search_keywords: nil, filter_mode: "union", favorite_practice_ids: []},
  {email: "bonjour.duy@gmail.com", encrypted_password: "$2a$12$IgBP0Zgm4nhpXJ4Ox91Y/.tsme9iAhpwnb8Zr4QcQfmIfPuTLDYLi", reset_password_token: nil, reset_password_sent_at: nil, remember_created_at: nil, sign_in_count: 0, current_sign_in_at: nil, last_sign_in_at: nil, current_sign_in_ip: nil, last_sign_in_ip: nil, phone: nil, phone_validated_at: nil, country_code: nil, google_uid: "108724227345529221358", google_email: nil, google_avatar_url: "https://lh3.googleusercontent.com/a/ACg8ocLgfaCDDm6YeNkvhUuXqXZhvAIHpE-Pf3jCMhxFZhC32UzlTnn0", avatar_cloudinary_id: nil, phone_verification_last_sent_at: nil, phone_verification_attempts: nil, first_name: "Duy", last_name: "Dang", is_admin: true, favorite_cities: [], favorite_countries: [], favorite_teacher_ids: [], search_keywords: nil, filter_mode: "union", favorite_practice_ids: []}
])


