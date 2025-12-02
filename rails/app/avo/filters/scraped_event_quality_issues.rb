class Avo::Filters::ScrapedEventQualityIssues < Avo::Filters::SelectFilter
  def apply(request, query, value)
    case value
    when 'with_errors'
      query.where("quality_flags -> 'errors' IS NOT NULL AND quality_flags -> 'errors' != '[]'::jsonb")
    when 'with_warnings'
      query.where("quality_flags -> 'warnings' IS NOT NULL AND quality_flags -> 'warnings' != '[]'::jsonb")
    when 'no_issues'
      query.where("quality_flags = '{}'::jsonb OR quality_flags IS NULL")
    else
      query
    end
  end

  def options
    {
      'with_errors' => '❌ Avec erreurs',
      'with_warnings' => '⚠️  Avec avertissements',
      'no_issues' => '✅ Sans problèmes'
    }
  end

  def name
    'Qualité'
  end
end
