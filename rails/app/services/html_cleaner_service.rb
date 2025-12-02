# Service de nettoyage HTML pour le scraping
# Enlève CSS, JS, scripts et ne garde que le contenu textuel pertinent
class HtmlCleanerService
  attr_reader :html, :cleaned_text

  # Tags à supprimer complètement (avec leur contenu)
  TAGS_TO_REMOVE = %w[
    script style noscript iframe embed object
    svg path canvas video audio
    nav aside
    form input button select textarea
  ].freeze

  # Tags à garder mais extraire le texte
  CONTENT_TAGS = %w[
    p div span h1 h2 h3 h4 h5 h6
    a li ul ol dl dt dd
    article section main
    table tr td th tbody thead
    time address blockquote
  ].freeze

  # Attributs à supprimer (garde seulement href, title, alt)
  ATTRIBUTES_TO_KEEP = %w[href title alt datetime].freeze

  def initialize(html)
    @html = html
    @cleaned_text = nil
  end

  # Nettoie le HTML et retourne du texte simplifié
  # @return [String] HTML nettoyé ou texte brut
  def clean!
    return "" if @html.blank?

    # Utiliser Nokogiri pour parser le HTML
    doc = Nokogiri::HTML(@html)

    # Supprimer les tags inutiles
    TAGS_TO_REMOVE.each do |tag|
      doc.css(tag).remove
    end

    # Supprimer les commentaires HTML
    doc.xpath("//comment()").remove

    # Supprimer les attributs inutiles (class, id, style, etc.)
    doc.css("*").each do |node|
      node.attributes.each do |name, attr|
        node.remove_attribute(name) unless ATTRIBUTES_TO_KEEP.include?(name)
      end
    end

    # Extraire le texte du body uniquement
    body = doc.at_css("body")
    return "" unless body

    # Convertir en texte avec structure minimale
    @cleaned_text = normalize_whitespace(body.inner_html)

    Rails.logger.info("HTML nettoyé : #{@html.length} → #{@cleaned_text.length} caractères")
    @cleaned_text
  end

  # Version texte pur (sans HTML)
  def to_text
    return "" if @html.blank?

    doc = Nokogiri::HTML(@html)

    # Supprimer les tags inutiles
    TAGS_TO_REMOVE.each do |tag|
      doc.css(tag).remove
    end

    body = doc.at_css("body") || doc
    text = body.text

    # Nettoyer les espaces
    normalize_whitespace(text)
  end

  # Version classe pour usage simple
  # @param html [String] HTML à nettoyer
  # @return [String] HTML nettoyé
  def self.clean(html)
    new(html).clean!
  end

  # Version texte pur
  # @param html [String] HTML à convertir
  # @return [String] Texte pur
  def self.to_text(html)
    new(html).to_text
  end

  private

  def normalize_whitespace(text)
    text
      .gsub(/\r\n/, "\n")           # Windows line endings
      .gsub(/\t/, " ")               # Tabs to spaces
      .gsub(/ +/, " ")               # Multiple spaces to single
      .gsub(/\n\n+/, "\n\n")         # Multiple newlines to double
      .strip
  end
end
