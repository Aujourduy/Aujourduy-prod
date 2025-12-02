# Seed pour initialiser les Teachers avec leurs Users et Practices
# Fichier: db/seeds/teachers_init.rb (VERSION COMPLÈTE)
# Mot de passe pour tous les comptes : Password123!
# Les users pourront récupérer leur compte via "Mot de passe oublié"

puts "🌱 Début du seed des teachers depuis CSV..."

# Mapping des noms de practices du CSV vers les noms normalisés
PRACTICE_MAPPING = {
  "La danse du merveilleux" => "La Danse Du Merveilleux",
  "Danse des 5 rythmes" => "Danse Des 5 Rythmes",
  "Danse de 5 rythmes" => "Danse Des 5 Rythmes",
  "5Rhythms" => "Danse Des 5 Rythmes",
  "Danse des 5 Rythmes" => "Danse Des 5 Rythmes",
  "Openfloor" => "Openfloor",
  "Open Floor" => "Openfloor",
  "Swell dance" => "Swell Dance",
  "Ecstatic dance" => "Ecstatic Dance",
  "Ecstatic Dance" => "Ecstatic Dance",
  "Danse inspirée" => "Danse Inspirée",
  "A corps d'âme" => "A Corps D'Âme",
  "Movement medecine" => "Movement Medicine",
  "Movement Medicine" => "Movement Medicine",
  "Life art process" => "Life Art Process",
  "Life Art Process" => "Life Art Process",
  "Danse essentielle" => "Danse Essentielle",
  "Danse conscience" => "Danse Conscience",
  "Dança Vida" => "Dança Vida",
  "Embody you Soul" => "Embody You Soul",
  "Danse libre & sensitive" => "Danse Libre & Sensitive",
  "Exploration de la Grâce" => "Exploration De La Grâce",
  "Les Êtres Dansés" => "Les Êtres Dansés",
  "Danse libre et intuitive" => "Danse Libre Et Intuitive",
  "Danse libre et musique live" => "Danse Libre Et Musique Live",
  "Expression Sensitive" => "Expression Sensitive",
  "La Danse du Présent" => "La Danse Du Présent",
  "Shaping the Invisible" => "Shaping The Invisible",
  "Dancing Freedom" => "Dancing Freedom",
  "Mouvement Dansé" => "Mouvement Dansé",
  "Danse Libre" => "Danse Libre",
  "Mouvements et Danse Biodynamique®" => "Mouvements Et Danse Biodynamique®",
  "Stellar Medicine Dance" => "Stellar Medicine Dance",
  "Being Dance" => "Being Dance",
  "Biodanza" => "Biodanza"
}

# Données des teachers (Prénom, Nom, Pratique, Email, URL Surveillée, Cloudinary URL)
teachers_data = [
  # Teachers du fichier original (teachers_init.rb)

  # Teachers manquants ajoutés depuis le fichier Teacher.create!
  ["Alexandra", "Stagliano", "Life Art Process", "alexandra.stagliano@teacher.aujourduy.fr", "https://www.alexandrastagliano.com/", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/chzfzeittssdt76hcpoj"],
  ["Anne Ena", "Bernard", "Movement Medicine", "lesneufsouffles@gmail.com", "https://lesneufsouffles.fr", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/kptigfbayc0wcttsfvqa"],
  ["Anouk Heike", "Maucher", "Danse des 5 Rythmes", "anouk@5rhythms-danceoflife.com", "http://www.5rhythms-danceoflife.com/", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/y7vchffwacj1l9hd7myc"],
  ["Brunehilde", "Yvrande", "Stellar Medicine Dance", "stellarmedicinedance@gmail.com", "https://www.stellarmedicinedance.fr/", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/dj9jxx38yufygnszi7m5"],
  ["Bruno", "Ayme", "Ecstatic Dance", "bruno.ayme@teacher.aujourduy.fr", "https://www.mixcloud.com/bruno-ayme/", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/jlakyfa2azpqkeehcvmz"],
  ["Catarina", "Dias", "Being Dance", "welcome@cataroxca.com", "https://cataroxca.com/", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/iwappe4enumvznsqdsp6"],
  ["Fabienne", "Hester", "Movement Medicine", "contact@association-vibrance.fr", "https://association-vibrance.fr", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/dq9rlhzpz27drwk9wdbc"],
  ["Francine", "Acker", "Danse des 5 Rythmes", "francine.acker67@gmail.com", "http://www.psy-gestalt-strasbourg.com", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/klbi7xlybwrqxqhu97wo"],
  ["Fredo", "Klein", "Open Floor", "fklein@outlook.fr", "", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/jm5jnrsax2scf6xredt0"],
  ["Joyleen", "Rao", "Danse des 5 Rythmes", "shine@joyleenrao.com", "https://www.joyleenrao.com/", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/a065byhqeol22qz6bij3"],
  ["Marianne", "Subra", "Danse des 5 Rythmes", "marianne@passerellescommunication.fr", "http://passerellescommunication.fr", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/jtfuuyh3au5qyzjstdci"],
  ["Maude", "Massard-Friat", "Open Floor", "info@maude.dance", "https://maudefriat.com/", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/wjorsocsy7f4efz39vz7"],
  ["Nicolas", "Bernard", "Movement Medicine", "nicolas.bernard@teacher.aujourduy.fr", "https://lesneufsouffles.fr", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/lanhmhavf0kn2npfmkzp"],
  ["Pierre", "Bassil", "Biodanza", "pierre.bassil@teacher.aujourduy.fr", "http://www.dose.dj/", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/gqez1qqpo4cett8pworf"],
  ["Vincent", "Fournout", "Danse des 5 Rythmes", "vincent@danselibre.com", "https://www.danselibre.com", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/jpugbebase68kigvf2s7"],
  ["Au Jour", "Duy", "La danse du merveilleux", "au.jour.duy@gmail.com", nil, "https://lh3.googleusercontent.com/a/ACg8ocLRkSW20DXAesezPJmmRfOif4QtvrsX7K9LiU7Rv66KC_uWFZnt"],
  ["Sara", "Cereghetti", "Danse des 5 Rythmes", "waveyoursoul@gmail.com", "http://www.waveyoursoul.com", "https://res.cloudinary.com/demdlk08x/image/upload/v1/teachers/eywtsxgn4t6kh2dfb452"],
]

# Mot de passe temporaire pour tous les comptes
temp_password = "Password123!"

# Récupérer l'admin créé par seeds.rb
admin = User.find_by(email: "au.jour.duy@gmail.com")
if admin.nil?
  puts "❌ ERREUR: L'admin au.jour.duy@gmail.com n'existe pas. Veuillez d'abord lancer rails db:seed"
  exit
end
puts "✅ Admin trouvé : #{admin.email}"

# Fonction pour extraire le cloudinary_id depuis une URL Cloudinary complète
def extract_cloudinary_id(url)
  return nil if url.blank?
  # Format typique : https://res.cloudinary.com/cloud_name/image/upload/v123456/folder/image.jpg
  # On veut extraire : folder/image ou juste image
  match = url.match(/\/upload\/(?:v\d+\/)?(.+)$/)
  return match[1] if match
  nil
end

# Étape 1 : Créer toutes les Practices uniques avec les noms normalisés (recherche case-insensitive)
normalized_practice_names = teachers_data.map { |d| PRACTICE_MAPPING[d[2]] || d[2] }.compact.uniq

normalized_practice_names.each do |practice_name|
  # Recherche case-insensitive pour éviter les doublons
  practice = Practice.where("LOWER(name) = LOWER(?)", practice_name).first
  
  if practice
    puts "  ⏭️  Practice existe : #{practice.name}"
  else
    practice = Practice.create!(name: practice_name, user: admin)
    puts "  📚 Practice créée : #{practice.name}"
  end
end

puts "\n🎭 Création des Users et Teachers..."

# Regrouper les données par email pour gérer les doublons
teachers_by_email = teachers_data.group_by { |d| d[3]&.strip&.downcase }

# Étape 2 : Créer les Users et mettre à jour leurs Teachers
teachers_by_email.each do |email, entries|
  next if email.blank? # Skip si pas d'email
  
  # Prendre les infos du premier entry (prénom, nom, photo)
  first_entry = entries.first
  first_name = first_entry[0]&.strip.presence || "Prénom"
  last_name = first_entry[1]&.strip.presence || "Inconnu"
  photo_url = first_entry[5]
  
  # Extraire le cloudinary_id si URL Cloudinary
  photo_cloudinary_id = extract_cloudinary_id(photo_url)
  
  # Collecter toutes les practices et URLs pour ce teacher
  practices_names = entries.map { |e| PRACTICE_MAPPING[e[2]] || e[2] }.compact.uniq
  reference_urls = entries.map { |e| e[4] }.compact.uniq
  
  # Créer ou trouver le User
  user = User.find_or_initialize_by(email: email)
  
  if user.new_record?
    user.password = temp_password
    user.password_confirmation = temp_password
    user.first_name = first_name
    user.last_name = last_name
    
    if user.save
      puts "  ✅ User créé : #{user.email}"
    else
      puts "  ❌ Erreur User #{email} : #{user.errors.full_messages.join(', ')}"
      next
    end
  else
    puts "  ⏭️  User existe déjà : #{user.email}"
  end
  
  # Le Teacher a été créé automatiquement par le callback
  teacher = user.teachers.first
  
  if teacher
    # D'ABORD associer toutes les Practices (IMPORTANT: avant l'update à cause de la validation)
    practices_names.each do |practice_name|
      # Recherche case-insensitive
      practice = Practice.where("LOWER(name) = LOWER(?)", practice_name).first
      if practice && !teacher.practices.include?(practice)
        teacher.practices << practice
        puts "    🎯 Practice ajoutée : #{practice.name}"
      end
    end
    
    # ENSUITE mettre à jour le Teacher avec les infos supplémentaires
    update_params = {
      first_name: first_name,
      last_name: last_name,
      contact_email: email
    }
    
    # Ajouter photo_cloudinary_id si présent, sinon photo_url
    if photo_cloudinary_id.present?
      update_params[:photo_cloudinary_id] = photo_cloudinary_id
    elsif photo_url.present?
      update_params[:photo_url] = photo_url
    end
    
    teacher.update!(update_params)
    
    # Si le User n'a pas d'avatar et que le Teacher a une photo, copier vers le User
    if user.google_uid.blank? && user.avatar_cloudinary_id.blank? && photo_cloudinary_id.present?
      user.update!(avatar_cloudinary_id: photo_cloudinary_id)
      puts "    🎭 Avatar User mis à jour depuis Teacher"
    end
    
    # Créer les TeacherUrls pour toutes les URLs de référence
    reference_urls.each do |reference_url|
      next if reference_url.blank? # Skip les URLs vides
      
      # Normaliser l'URL
      if !reference_url.start_with?('http')
        reference_url = "https://#{reference_url}"
      end
      
      begin
        teacher_url = teacher.teacher_urls.find_or_create_by!(url: reference_url) do |tu|
          tu.name = "Site de référence"
          tu.is_active = true
        end
        puts "    🔗 URL de scraping ajoutée : #{reference_url}"
        
        # Mettre à jour reference_url du teacher avec la première URL
        if teacher.reference_url.blank?
          teacher.update!(reference_url: reference_url)
        end
      rescue ActiveRecord::RecordInvalid => e
        puts "    ❌ Erreur URL pour #{teacher.full_name}: #{e.record.errors.full_messages.join(', ')}"
        next
      end
    end
    
    puts "  👤 Teacher mis à jour : #{teacher.full_name} (#{practices_names.size} practice(s))"
  else
    puts "  ❌ Pas de teacher trouvé pour #{email}"
  end
end

puts "\n✨ Seed teachers terminé !"
puts "📊 Résumé :"
puts "  - #{Practice.count} Practices"
puts "  - #{User.count} Users"
puts "  - #{Teacher.count} Teachers"
puts "  - #{TeacherUrl.count} URLs de scraping"
puts "\n💡 Mot de passe pour tous les nouveaux comptes : #{temp_password}"