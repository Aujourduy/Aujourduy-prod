# Service d'extraction JSON via l'API Qwen ou Ollama local
# Envoie le HTML et récupère un JSON structuré des événements
class QwenApiService
  attr_reader :html_content, :source_url, :extracted_data, :error

  # Configuration API Qwen Cloud
  QWEN_API_ENDPOINT = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation".freeze
  QWEN_MODEL = "qwen-max".freeze

  # Configuration OpenRouter
  OPENROUTER_API_ENDPOINT = "https://openrouter.ai/api/v1/chat/completions".freeze

  # Configuration Ollama Local
  OLLAMA_MODEL = "qwen2.5:3b-instruct-q4_K_M".freeze

  def self.ollama_endpoint
    host = ENV["OLLAMA_HOST"] || "172.18.0.1"
    "http://#{host}:11434/api/generate"
  end

  TIMEOUT = 120 # secondes (plus long pour Ollama)

  # @param html_content [String] Le HTML à analyser
  # @param source_url [String] L'URL source (pour métadonnées)
  # @param owner_teacher [Teacher, nil] Le teacher propriétaire du site (utilisé comme défaut)
  # @param site_type [String, nil] Type de site: "mono_teacher" ou "multi_teacher"
  def initialize(html_content, source_url, owner_teacher = nil, site_type = nil)
    @html_content = html_content
    @source_url = source_url
    @owner_teacher = owner_teacher
    @site_type = site_type || "mono_teacher" # Par défaut mono_teacher pour rétrocompatibilité
    @extracted_data = nil
    @error = nil
  end

  # Extrait les événements du HTML
  # @return [Array<Hash>, nil] Tableau de hashs d'événements ou nil
  def extract!
    validate_inputs!

    begin
      # Nettoyer le HTML avant de l'envoyer
      cleaned_html = HtmlCleanerService.to_text(@html_content)

      Rails.logger.info("HTML nettoyé : #{@html_content.length} → #{cleaned_html.length} caractères")

      # Remplacer le HTML par la version nettoyée
      @html_content = cleaned_html

      # Appeler l'API (priorité: OpenRouter > Ollama > Qwen cloud)
      response = if use_openrouter?
                   call_openrouter_api
                 elsif use_ollama?
                   call_ollama_api
                 else
                   call_qwen_api
                 end

      parse_response(response)
    rescue StandardError => e
      @error = "Erreur extraction Qwen: #{e.class.name} - #{e.message}"
      Rails.logger.error(@error)
      Rails.logger.error(e.backtrace.join("\n"))
      nil
    end
  end

  # Version classe pour usage simple
  # @param html_content [String] Le HTML
  # @param source_url [String] L'URL source
  # @return [Array<Hash>, nil] Données extraites
  def self.extract(html_content, source_url)
    new(html_content, source_url).extract!
  end

  private

  def validate_inputs!
    raise ArgumentError, "HTML ne peut pas être vide" if @html_content.blank?
    raise ArgumentError, "source_url ne peut pas être vide" if @source_url.blank?

    # Valider selon le mode
    if use_openrouter?
      raise ArgumentError, "OPENROUTER_API_KEY non configurée" if ENV["OPENROUTER_API_KEY"].blank?
      Rails.logger.info("Mode OpenRouter activé (modèle: #{ENV['OPENROUTER_MODEL'] || 'qwen/qwen-2.5-72b-instruct'})")
    elsif use_ollama?
      # Ollama : pas besoin de clé API
      Rails.logger.info("Mode Ollama activé")
    else
      # API Cloud : nécessite une clé
      raise ArgumentError, "QWEN_API_KEY non configurée" if api_key.blank?
    end
  end

  # Détermine si on utilise OpenRouter (priorité haute)
  def use_openrouter?
    ENV["USE_OPENROUTER"] == "true"
  end

  # Détermine si on utilise Ollama ou l'API cloud
  def use_ollama?
    !use_openrouter? && (ENV["USE_OLLAMA"] == "true" || ENV["QWEN_API_KEY"].blank?)
  end

  def api_key
    ENV["QWEN_API_KEY"]
  end

  # Appel API Qwen Cloud
  def call_qwen_api
    uri = URI(QWEN_API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = TIMEOUT

    request = Net::HTTP::Post.new(uri.path)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = build_qwen_request_body.to_json

    Rails.logger.info("Appel API Qwen Cloud pour #{@source_url}")
    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Erreur API Qwen: #{response.code} - #{response.body}"
    end

    JSON.parse(response.body)
  end

  # Appel OpenRouter API
  def call_openrouter_api
    uri = URI(OPENROUTER_API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = TIMEOUT

    request = Net::HTTP::Post.new(uri.path)
    request["Authorization"] = "Bearer #{ENV['OPENROUTER_API_KEY']}"
    request["Content-Type"] = "application/json"
    request["HTTP-Referer"] = "https://aujourduy.fr" # Optionnel mais recommandé par OpenRouter
    request.body = build_openrouter_request_body.to_json

    model = ENV["OPENROUTER_MODEL"] || "qwen/qwen-2.5-72b-instruct"
    Rails.logger.info("Appel OpenRouter API (#{model}) pour #{@source_url}")

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Erreur OpenRouter: #{response.code} - #{response.body}"
    end

    # OpenRouter retourne un format compatible OpenAI
    # On le normalise au format attendu par parse_response
    body = JSON.parse(response.body)

    {
      "output" => {
        "choices" => [
          {
            "message" => {
              "content" => body.dig("choices", 0, "message", "content")
            }
          }
        ]
      }
    }
  end

  # Appel Ollama Local
  def call_ollama_api
    uri = URI(self.class.ollama_endpoint)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = TIMEOUT

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request.body = build_ollama_request_body.to_json

    Rails.logger.info("Appel Ollama local pour #{@source_url}")

    # Ollama stream la réponse, on doit lire ligne par ligne
    full_response = ""
    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Erreur Ollama: #{response.code} - #{response.body}"
    end

    # Parser les lignes JSON streamées
    response.body.each_line do |line|
      next if line.strip.empty?

      chunk = JSON.parse(line)
      full_response += chunk["response"] if chunk["response"]

      # Ollama envoie "done": true à la fin
      break if chunk["done"]
    end

    # Retourner au format compatible avec parse_response
    {
      "output" => {
        "choices" => [
          {
            "message" => {
              "content" => full_response
            }
          }
        ]
      }
    }
  end

  # Body pour API Qwen Cloud
  def build_qwen_request_body
    {
      model: QWEN_MODEL,
      input: {
        messages: [
          {
            role: "system",
            content: system_prompt
          },
          {
            role: "user",
            content: user_prompt
          }
        ]
      },
      parameters: {
        temperature: 0.1, # Basse température pour extraction précise
        top_p: 0.8,
        max_tokens: 32000, # Augmenté pour supporter les événements récurrents
        result_format: "message"
      }
    }
  end

  # Body pour Ollama Local
  def build_ollama_request_body
    {
      model: OLLAMA_MODEL,
      prompt: "#{system_prompt}\n\n#{user_prompt}",
      stream: true,
      options: {
        temperature: 0.1,
        top_p: 0.8,
        num_predict: 4000
      }
    }
  end

  # Body pour OpenRouter API
  def build_openrouter_request_body
    {
      model: ENV["OPENROUTER_MODEL"] || "qwen/qwen-2.5-72b-instruct",
      messages: [
        {
          role: "system",
          content: system_prompt
        },
        {
          role: "user",
          content: user_prompt
        }
      ],
      temperature: 0.1,
      top_p: 0.8,
      max_tokens: 16000 # Rails calcule les récurrences, OpenRouter extrait juste les règles
    }
  end

  def system_prompt
    today = Date.current

    # Contexte du teacher propriétaire du site selon le type de site
    owner_context = if @owner_teacher
      owner_name = "#{@owner_teacher.first_name} #{@owner_teacher.last_name}"

      if @site_type == "multi_teacher"
        # Site multi-teacher (ex: LibraDanse) - chaque event a son propre teacher
        <<~OWNER

          CONTEXTE IMPORTANT - SITE MULTI-TEACHERS :
          Ce site présente des événements de PLUSIEURS teachers différents.

          RÈGLES D'EXTRACTION :
          - Chercher le nom du teacher pour CHAQUE événement individuellement
          - Si un teacher est explicitement nommé (ex: "Guillaume Laplane", "Bruno Ayme") → l'extraire
          - Si AUCUN teacher n'est trouvé pour un événement → laisser first_name et last_name VIDES (null)
          - NE PAS utiliser de teacher par défaut

          Patterns courants pour identifier un teacher dans un titre :
          - "Practice – Teacher Name – Venue" → extraire Teacher Name
          - "Jour Date – Practice – Teacher – Lieu" → extraire Teacher
          - Les noms de personnes ont généralement un prénom + nom (ex: "Guillaume Laplane")

          ATTENTION - Ce ne sont PAS des teachers :
          - Noms de lieux : "F.A.C.", "CocoSwing", "Balroom"
          - Acronymes et noms de salles
          - Titres génériques sans nom de personne
        OWNER
      else
        # Site mono-teacher (ex: marcsilvestre.com) - un seul teacher pour tout le site
        <<~OWNER

          CONTEXTE IMPORTANT - SITE MONO-TEACHER :
          Ce site appartient à #{owner_name}. C'est un site personnel avec un seul teacher.

          RÈGLES D'EXTRACTION :
          - Utiliser #{owner_name} comme teacher pour TOUS les événements
          - Ne pas chercher d'autres noms de teachers
          - first_name: "#{@owner_teacher.first_name}", last_name: "#{@owner_teacher.last_name}"
        OWNER
      end
    else
      ""
    end

    <<~PROMPT
      Tu es un expert en extraction de données d'événements de danse depuis des pages web HTML.

      Date actuelle : #{today.strftime('%Y-%m-%d')} (#{today.strftime('%A %d %B %Y')})
      #{owner_context}

      Ta tâche :
      1. Analyser le HTML fourni
      2. Extraire TOUS les événements de danse/mouvement présents
      3. Pour les événements RÉCURRENTS (ex: "tous les vendredis", "chaque mardi") :
         - NE PAS calculer toutes les dates individuelles
         - Extraire la RÈGLE de récurrence (jour de la semaine, fréquence, date de début)
         - Marquer l'événement comme récurrent avec is_recurring: true
      4. Pour les événements ponctuels ou stages multi-jours, créer normalement
      5. Retourner un tableau JSON avec tous les événements

      ⚠️ RÈGLE CRITIQUE - EXTRACTION AVEC INFORMATIONS MINIMALES :
      - Si un événement a une DATE + un LIEU → EXTRAIRE même si le contexte est minimal
      - La description peut être basique si peu d'infos disponibles :
        - Si pas de description dans le HTML → utiliser "Stage de danse" ou le titre
        - Exemples acceptables : "Stage", "Stage de danse", "Cours", ou réutiliser le titre
      - Ne PAS filtrer les événements sous prétexte qu'ils manquent de détails
      - L'important est d'extraire TOUS les événements mentionnés, même succincts

      IMPORTANT - ÉVÉNEMENTS RÉCURRENTS :
      - "Tous les vendredis" → is_recurring: true, day_of_week: "friday", pattern: "weekly"
      - "Chaque mardi" → is_recurring: true, day_of_week: "tuesday", pattern: "weekly"
      - "Un vendredi sur deux" → is_recurring: true, day_of_week: "friday", pattern: "biweekly"
      - "Le premier lundi du mois" → is_recurring: true, day_of_week: "monday", pattern: "monthly", week_of_month: 1

      ⚠️ RÈGLE CRITIQUE - RÉCURRENCE EXPLICITE UNIQUEMENT :
      - Pattern EXPLICITE (calculer la récurrence, is_recurring: TRUE) :
        - Contient TOUJOURS le jour de la semaine (lundi, mardi, etc.)
        - + détails permettant de calculer : "tous les", "chaque", "le Xe du mois"
        - Exemples : "Tous les vendredis", "Le 2e jeudi du mois", "Chaque mardi"
      - Pattern VAGUE (NE PAS calculer, is_recurring: FALSE, créer uniquement dates listées) :
        - Pas de jour de la semaine spécifié
        - Exemples : "1 fois par mois", "2 fois par mois", "Régulièrement", "De temps en temps", "Souvent"
      - Si des dates spécifiques sont listées après une mention vague, ce sont les SEULES dates

      IMPORTANT - FORMAT :
      - Ne retourne QUE du JSON valide, aucun texte avant ou après
      - Utilise le format exact spécifié dans le prompt utilisateur
      - Si une info manque, omets le champ ou utilise null
      - Pour les dates : format YYYY-MM-DD
      - Pour les heures : format HH:MM (24h)
      - Pour les prix : toujours 2 décimales (ex: 15.00)
    PROMPT
  end

  def user_prompt
    <<~PROMPT
      Voici le HTML d'une page web contenant des événements de danse/mouvement.

      Source URL : #{@source_url}

      Extrait TOUS les événements et retourne un JSON au format suivant :

      #{json_format_specification}

      HTML à analyser :
      ```html
      #{truncate_html(@html_content)}
      ```

      Retourne UNIQUEMENT le JSON, sans texte explicatif.
    PROMPT
  end

  def json_format_specification
    # Charger toutes les practices existantes de la base de données
    existing_practices = Practice.pluck(:name).sort
    practices_list = existing_practices.map { |p| "\"#{p}\"" }.join(", ")

    # Format tiré de scrapping/Prompt.md
    <<~FORMAT
      Format pour UN événement :
      {
        "scraping_metadata": {
          "source_url": "#{@source_url}",
          "scraped_at": "#{Time.current.iso8601}",
          "scraper": "Qwen"
        },
        "teacher": {
          "first_name": "...",
          "last_name": "..."
        },
        "venue": {  // Obligatoire si is_online: false
          "name": "...",
          "address_line1": "...",
          "postal_code": "...",
          "city": "...",
          "department_code": "...",    // Code département (ex: "07", "69", "2A", "971"). IMPORTANT: Remplis automatiquement pour villes connues (Paris→75, Lyon→69, Marseille→13, Rennes→35, etc.)
          "department_name": "...",    // Nom département (ex: "Ardèche", "Rhône"). Essaie de donner les deux si possible.
          "region": "...",             // Région (ex: "Île-de-France", "Bretagne", "Auvergne-Rhône-Alpes"). IMPORTANT: Remplis pour villes connues (Paris→Île-de-France, Rennes→Bretagne, Lyon→Auvergne-Rhône-Alpes)
          "country": "..."
        },
        "event": {
          "title": "...",
          "description": "...",  // Peut être basique ("Stage", "Stage de danse", "Cours") si peu de contexte disponible
          "practice": "...",  // ⚠️ IMPORTANT: Choisis EXACTEMENT parmi cette liste: #{practices_list}
                              // Si aucune ne correspond, utilise la plus proche ou laisse vide
          "source_url": "#{@source_url}",
          "is_online": false,
          "price_normal": 0.00,
          "price_reduced": 0.00,
          "currency": "EUR",
          "start_date": "YYYY-MM-DD",      // Pour événements ponctuels ou première occurrence
          "end_date": "YYYY-MM-DD",        // Optionnel (si multi-jours)
          "start_time": "HH:MM",
          "end_time": "HH:MM",

          // NOUVEAUX CHAMPS POUR RÉCURRENCE (optionnels)
          "is_recurring": false,            // true si événement récurrent
          "recurrence_rule": {              // Seulement si is_recurring = true
            "pattern": "weekly",            // "weekly", "biweekly", "monthly"
            "day_of_week": "friday",        // "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"
            "week_of_month": null,          // 1-4 pour "monthly" pattern (ex: "premier lundi du mois" = 1)
            "recurrence_start_date": "YYYY-MM-DD",  // Date de début de la récurrence (ou null pour aujourd'hui)
            "recurrence_end_date": null     // Date de fin explicite (null = fin juin par défaut)
          }
        }
      }

      Si PLUSIEURS événements : retourner [ {...}, {...}, {...} ]
      Si AUCUN événement : retourner []
    FORMAT
  end

  def parse_response(response)
    # La réponse Qwen est dans output.choices[0].message.content
    content = response.dig("output", "choices", 0, "message", "content")

    if content.blank?
      @error = "Réponse Qwen vide"
      Rails.logger.error(@error)
      return nil
    end

    # DEBUG: Afficher la réponse brute
    Rails.logger.debug("="*80)
    Rails.logger.debug("RÉPONSE BRUTE DU MODÈLE:")
    Rails.logger.debug(content[0..1000]) # Premiers 1000 caractères
    Rails.logger.debug("="*80)

    # Extraire le JSON (parfois Qwen ajoute du texte avant/après)
    json_text = extract_json_from_text(content)

    # Parser le JSON
    @extracted_data = JSON.parse(json_text)

    # Normaliser : si c'est un objet unique, le mettre dans un tableau
    @extracted_data = [@extracted_data] unless @extracted_data.is_a?(Array)

    Rails.logger.info("Extraction Qwen réussie : #{@extracted_data.length} événement(s)")
    @extracted_data
  rescue JSON::ParserError => e
    @error = "Erreur parsing JSON: #{e.message}. Contenu: #{content&.first(500)}"
    Rails.logger.error(@error)
    nil
  end

  def extract_json_from_text(text)
    # Chercher le JSON entre crochets [] ou accolades {}
    # Essayer d'abord un tableau
    if text =~ /(\[.*\])/m
      return $1
    end

    # Sinon chercher un objet
    if text =~ /(\{.*\})/m
      return $1
    end

    # Si rien trouvé, retourner le texte brut (va échouer au parsing)
    text
  end

  def truncate_html(html)
    # Limiter la taille du HTML pour ne pas dépasser les tokens Qwen
    # ~50k caractères = ~12k tokens (approximation)
    max_chars = 50_000

    if html.length > max_chars
      Rails.logger.warn("HTML tronqué de #{html.length} à #{max_chars} caractères")
      html.first(max_chars) + "\n\n... (contenu tronqué)"
    else
      html
    end
  end
end
