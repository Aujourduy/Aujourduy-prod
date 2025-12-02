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
  ["Duy", "Dang", "La danse du merveilleux", "aujourduy@gmail.com", "https://sites.google.com/view/aujourduy2/accueil", "http://res.cloudinary.com/demdlk08x/image/upload/v1739961429/cezmwywrvkcoodbpj27b.jpg"],
  ["Marc", "Silvestre", "Danse des 5 rythmes", "info@marcsilvestre.com", "https://www.marcsilvestre.com/agenda-cours-stages-1", "http://res.cloudinary.com/demdlk08x/image/upload/v1739961414/amnwb9wnnsmqhu5i9b4j.png"],
  ["Peter", "Wilberforce", "Danse des 5 rythmes", "bodyvoiceandbeing@gmail.com", "https://www.bodyvoiceandbeing.com/cours-et-ateliers-reguliers", "https://res.cloudinary.com/demdlk08x/image/upload/v1742820578/mghwybs9osujzic5med8.jpg"],
  ["Garance", "Monziès", "Openfloor", "garancem@msn.com", "https://www.danseinspiree.com/ateliers-1", "https://res.cloudinary.com/demdlk08x/image/upload/v1742202525/dlowwrjd2jvmto7lj3pj.png"],
  ["Amélie", "Schweiger", "Danse de 5 rythmes", "goundor@orange.fr", "https://lesviesdansent.fr/danse-des-5-rythmes-cours.html", "https://res.cloudinary.com/demdlk08x/image/upload/v1740146612/j3c4v5bvuthlosdf8sje.png"],
  [nil, "Swell Dance", "Swell dance", "accueil@swell.dance", "https://www.swell.dance/", "http://res.cloudinary.com/demdlk08x/image/upload/v1739961426/haxgkakg37qlc9v3qeqy.png"],
  [nil, "Love Ecstatic Dance", "Ecstatic dance", "leschampsdamour@gmail.com", "https://www.helloasso.com/associations/les-champs-d-amour", "https://res.cloudinary.com/demdlk08x/image/upload/v1741181012/d8zmifkxdfkue7mdswmz.jpg"],
  ["Caroline", "Villotte Carvès", "Danse inspirée", "caroline.carves@gmail.com", "https://www.lesonenmouvements.com/", "https://res.cloudinary.com/demdlk08x/image/upload/v1741204578/xtjvcouz3qvgrdqcudhc.jpg"],
  ["Melinda", "Rabate", "A corps d'âme", "acorpsdames49@gmail.com", "https://www.a-corps-d-ames.com", "https://res.cloudinary.com/demdlk08x/image/upload/v1741338699/wtthhhv6vlsxx6dtz6kq.jpg"],
  ["Clément", "Leon", "Movement medicine", "movementmedicineinfo@gmail.com", "https://www.clementleon.com/movement-medicine", "https://res.cloudinary.com/demdlk08x/image/upload/v1741207967/ysgnjemfyjs1mspxmnma.png"],
  ["Stephane", "Vernier", "Life art process", "stephane.vernier@yahoo.fr", "https://www.stephanevernier.com/ateliers", "https://res.cloudinary.com/demdlk08x/image/upload/v1741867782/tycfchvfehr8otlp0eco.jpg"],
  ["Dominique", "Dahan", "Danse essentielle", "dahandominique@gmail.com", "https://www.danseessentielle.com/agenda-par-th%C3%A8me", "https://res.cloudinary.com/demdlk08x/image/upload/v1744054551/galsmmorptigvoikq2wf.jpg"],
  ["Apsara", "Le Huy", "Movement Medicine", "lehuymai@yahoo.fr", "https://www.essence-movement.com/movement-medicine", "https://res.cloudinary.com/demdlk08x/image/upload/v1741867990/z4zovhftjcmmoihelvgh.avif"],
  ["Solange", "BRELOT", "Movement Medicine", "contact@liberetadanse.com", "https://liberetadanse.com/cours-hebdo-meditation-mouvement", "https://res.cloudinary.com/demdlk08x/image/upload/v1742060681/u1bxhv2bmhcgsx8romds.png"],
  ["Sébastien", "Ossard", "Danse conscience", "lesebi@free.fr", "https://www.facebook.com/share/1AAH2ew8h7/?mibextid=wwXIfr", "https://res.cloudinary.com/demdlk08x/image/upload/v1742054901/sopcaavcatsxta8m4qkn.jpg"],
  ["Caroline", "Lecouturier", "Dança Vida", "clecouturier75@gmail.com", "https://www.danca-vida.com/ateliers-de-danse", "https://res.cloudinary.com/demdlk08x/image/upload/v1742222838/q4hzerbj1bous185fl9c.jpg"],
  ["Céline", "Laurent", "Embody you Soul", "celine0302@gmail.com", nil, "https://res.cloudinary.com/demdlk08x/image/upload/v1742318329/kjdnng355mqsht2qz1h8.png"],
  ["Florence", "Bablon", "Danse libre & sensitive", "florencebablon.ateliers@gmail.com", "https://www.florencebablon.fr/agenda", "https://res.cloudinary.com/demdlk08x/image/upload/v1742318330/erc4crggogl80z9kjc7f.png"],
  ["Laurie", "Thinot", "Exploration de la Grâce", "contact@graceflow.fr", "https://www.graceflow.fr/a-propos/", "https://res.cloudinary.com/demdlk08x/image/upload/v1742422522/fs6oh2rzdavwektvnb8h.jpg"],
  ["Lina", "Kriskova", "Open Floor", "lina.openfloor@gmail.com", nil, "https://res.cloudinary.com/demdlk08x/image/upload/v1742370590/nbbxlwkduivphxfon6gy.jpg"],
  ["David", "Nadasi", "Ecstatic Dance", "macrophone@gmail.com", nil, "https://res.cloudinary.com/demdlk08x/image/upload/v1742421245/x5rxyjpbhmxyyy6wqvob.png"],
  ["ALEXANDRA", "DE WILLERMIN", "Danse des 5 Rythmes", "adewillermin1@gmail.com", "https://www.comeandance.wix.com/alex", "https://res.cloudinary.com/demdlk08x/image/upload/v1742631201/fcl3fga0yj9i1nzttx86.jpg"],
  ["Gwenaelle", "DOERFLINGER", "Life Art Process", "gwenaelled@hotmail.com", "https://lavoixquidanse.jimdofree.com/dates-des-stages-et-ateliers/", "https://res.cloudinary.com/demdlk08x/image/upload/v1742814254/f1sjfkg7rqutebahjqcq.jpg"],
  ["Alain", "Bornarel", "Les Êtres Dansés", "lesetresdanses@gmail.com", "https://www.lesetresdanses.fr", "https://res.cloudinary.com/demdlk08x/image/upload/v1742998779/fclhzfc4juukpaafqvwy.png"],
  ["Noemi", "Haire-Sievers", "Danse libre et intuitive", "nhairesievers@gmail.com", nil, "https://res.cloudinary.com/demdlk08x/image/upload/v1748006357/w6yj5ftr2mcczb9oxfrd.jpg"],
  ["Sylvain", "Lalevée", "Danse libre et musique live", "nenufaar@yahoo.fr", "https://www.facebook.com/nenufaar/", "https://res.cloudinary.com/demdlk08x/image/upload/v1743699531/b00xazec7mpx40uj7ypk.jpg"],
  ["Silvija", "Tomcik", "Danse de 5 rythmes", "info@prendrecorps.fr", "https://www.prendrecorps.fr/silvija", "https://res.cloudinary.com/demdlk08x/image/upload/v1743788147/thx7myezzel9mgi2fory.jpg"],
  ["Florence", "Strigler", "Expression Sensitive", "f.strigler@wanadoo.fr", "https://corporescens.fr/ateliers-et-stages/", "https://res.cloudinary.com/demdlk08x/image/upload/v1747300359/l94fty7b7rtoaf5lea0a.jpg"],
  ["Cyrille", "Chantereau", "La Danse du Présent", "cyrill.chantereau@gmail.com", "https://www.justdancewithlife.com", "https://res.cloudinary.com/demdlk08x/image/upload/v1747300361/q9ganphevjkdlndvxdqp.jpg"],
  ["Emma", "Roberts", "Shaping the Invisible", "info@shapingtheinvisible.co.uk", "http://www.shapingtheinvisible.co.uk/unbound-soul-weekend-workshop-paris.html", "https://res.cloudinary.com/demdlk08x/image/upload/v1748004603/pdfhir7bkbq8janbmrnk.jpg"],
  ["Laure", "Kypriotis", "Dancing Freedom", "kypriotisl@gmail.com", "https://www.laure-kypriotis-reconnect.com/agenda", "https://res.cloudinary.com/demdlk08x/image/upload/v1749640500/zwrrtsk2irqynancmg73.png"],
  ["Claudy", "Traineau", "Mouvement Dansé", "contact@ct-coaching-formation.fr", "https://www.ct-coaching-formation.fr/mouvement-danse/", "https://res.cloudinary.com/demdlk08x/image/upload/v1750859178/ambf92lbrngodacoxu4m.jpg"],
  ["Audey", "Hesschentier", "Danse Libre", "audrey.hesschentier@gmail.com", nil, "https://res.cloudinary.com/demdlk08x/image/upload/v1750933375/xorlxtc1kk8aw1we4ldq.jpg"],
  ["Fabienne", "Marnat", "Mouvements et Danse Biodynamique®", "fabienne.marnat@gmail.com", "https://www.facebook.com/profile.php?id=100072550416220", "https://res.cloudinary.com/demdlk08x/image/upload/v1753638175/otpe1cz0l4x4bdaesfqd.png"],
  ["Guillaume", "Laplane", "5Rhythms", "guillaume5rhythms@gmail.com", "https://guillaumelaplane.com", "https://res.cloudinary.com/demdlk08x/image/upload/v1754666734/mvaivfcxqu8c6yfrbjds.jpg"]  
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
  # On veut extraire : folder/image (sans extension)
  match = url.match(/\/upload\/(?:v\d+\/)?(.+)$/)
  if match
    cloudinary_path = match[1]
    # Enlever l'extension si présente (.jpg, .png, .gif, .avif, etc.)
    cloudinary_path.sub(/\.(jpg|jpeg|png|gif|webp|avif|svg)$/i, '')
  else
    nil
  end
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
    
    # Ajouter photo_url si présent
    if photo_url.present?
      update_params[:photo_url] = photo_url
    end
    
    teacher.update!(update_params)
    
    # Si le User n'a pas d'avatar et que le Teacher a une photo, extraire cloudinary_id et copier vers le User
    if user.google_uid.blank? && user.avatar_cloudinary_id.blank? && photo_url.present?
      photo_cloudinary_id = extract_cloudinary_id(photo_url)
      if photo_cloudinary_id.present?
        user.update!(avatar_cloudinary_id: photo_cloudinary_id)
        puts "    🎭 Avatar User mis à jour depuis Teacher"
      end
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