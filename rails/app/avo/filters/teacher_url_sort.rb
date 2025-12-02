class Avo::Filters::TeacherUrlSort < Avo::Filters::SelectFilter
  self.name = "Trier par"

  def apply(request, query, value)
    return query if value.blank?

    case value
    when "teacher_asc"
      query.joins(:teacher).reorder("teachers.first_name ASC, teachers.last_name ASC")
    when "teacher_desc"
      query.joins(:teacher).reorder("teachers.first_name DESC, teachers.last_name DESC")
    when "name_asc"
      query.reorder("teacher_urls.name ASC")
    when "name_desc"
      query.reorder("teacher_urls.name DESC")
    when "last_scraped_asc"
      query.reorder("teacher_urls.last_scraped_at ASC NULLS FIRST")
    when "last_scraped_desc"
      query.reorder("teacher_urls.last_scraped_at DESC NULLS LAST")
    when "url_asc"
      query.reorder("teacher_urls.url ASC")
    when "url_desc"
      query.reorder("teacher_urls.url DESC")
    when "duration_asc"
      query.reorder("teacher_urls.last_scraping_duration ASC NULLS FIRST")
    when "duration_desc"
      query.reorder("teacher_urls.last_scraping_duration DESC NULLS LAST")
    when "interval_asc"
      query.reorder(Arel.sql("(teacher_urls.scraping_config->>'interval_days')::integer ASC NULLS FIRST"))
    when "interval_desc"
      query.reorder(Arel.sql("(teacher_urls.scraping_config->>'interval_days')::integer DESC NULLS LAST"))
    else
      query
    end
  end

  def options
    {
      "teacher_asc" => "👤 Teacher ⬆️ (A → Z)",
      "teacher_desc" => "👤 Teacher ⬇️ (Z → A)",
      "name_asc" => "📝 Nom ⬆️ (A → Z)",
      "name_desc" => "📝 Nom ⬇️ (Z → A)",
      "last_scraped_desc" => "🕒 Dernier scraping ⬇️ (plus récent)",
      "last_scraped_asc" => "🕒 Dernier scraping ⬆️ (plus ancien)",
      "duration_desc" => "⏱️ Durée scraping ⬇️ (plus long)",
      "duration_asc" => "⏱️ Durée scraping ⬆️ (plus court)",
      "interval_desc" => "📅 Intervalle scraping ⬇️ (plus espacé)",
      "interval_asc" => "📅 Intervalle scraping ⬆️ (plus fréquent)",
      "url_asc" => "🔗 URL ⬆️ (A → Z)",
      "url_desc" => "🔗 URL ⬇️ (Z → A)"
    }
  end

  def default
    "teacher_asc"
  end
end
