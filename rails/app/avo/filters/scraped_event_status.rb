class Avo::Filters::ScrapedEventStatus < Avo::Filters::SelectFilter
  def apply(request, query, value)
    query.where(status: value)
  end

  def options
    {
      'pending' => 'pending',
      'validated' => 'validated',
      'rejected' => 'rejected',
      'imported' => 'imported'
    }
  end

  def name
    'Statut'
  end
end
