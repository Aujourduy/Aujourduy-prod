# Service pour calculer toutes les dates d'un événement récurrent
# À partir d'une règle de récurrence extraite par OpenRouter
class RecurrenceCalculatorService
  attr_reader :recurrence_rule, :dates, :error

  # Mapping des jours de la semaine (français → symbole Ruby)
  DAY_MAPPING = {
    'monday' => :monday,
    'tuesday' => :tuesday,
    'wednesday' => :wednesday,
    'thursday' => :thursday,
    'friday' => :friday,
    'saturday' => :saturday,
    'sunday' => :sunday
  }.freeze

  # @param recurrence_rule [Hash] La règle de récurrence extraite du JSON
  # @param event_start_date [String|Date] Date de début explicite de l'événement (optionnel)
  def initialize(recurrence_rule, event_start_date = nil)
    @recurrence_rule = recurrence_rule
    @event_start_date = event_start_date
    @dates = []
    @error = nil
  end

  # Calcule toutes les dates de récurrence
  # @return [Array<Date>] Tableau de dates ou [] en cas d'erreur
  def calculate!
    return [] unless validate_rule!

    pattern = @recurrence_rule['pattern']
    day_of_week = @recurrence_rule['day_of_week']

    start_date = determine_start_date
    end_date = determine_end_date

    Rails.logger.info("Calcul récurrence: pattern=#{pattern}, day=#{day_of_week}, #{start_date} → #{end_date}")

    case pattern
    when 'weekly'
      calculate_weekly(start_date, end_date, day_of_week)
    when 'biweekly'
      calculate_biweekly(start_date, end_date, day_of_week)
    when 'monthly'
      calculate_monthly(start_date, end_date, day_of_week)
    else
      @error = "Pattern de récurrence inconnu: #{pattern}"
      Rails.logger.error(@error)
      []
    end

    @dates
  rescue StandardError => e
    @error = "Erreur calcul récurrence: #{e.class.name} - #{e.message}"
    Rails.logger.error(@error)
    Rails.logger.error(e.backtrace.join("\n"))
    []
  end

  # Version classe pour usage simple
  # @return [Array<Date>]
  def self.calculate(recurrence_rule, event_start_date = nil)
    new(recurrence_rule, event_start_date).calculate!
  end

  private

  def validate_rule!
    unless @recurrence_rule.is_a?(Hash)
      @error = "recurrence_rule doit être un Hash"
      return false
    end

    unless @recurrence_rule['pattern'].present?
      @error = "pattern manquant dans recurrence_rule"
      return false
    end

    unless @recurrence_rule['day_of_week'].present?
      @error = "day_of_week manquant dans recurrence_rule"
      return false
    end

    true
  end

  def determine_start_date
    # Priorité : recurrence_start_date > event_start_date > aujourd'hui
    if @recurrence_rule['recurrence_start_date'].present?
      Date.parse(@recurrence_rule['recurrence_start_date'])
    elsif @event_start_date.present?
      @event_start_date.is_a?(Date) ? @event_start_date : Date.parse(@event_start_date)
    else
      Date.current
    end
  end

  def determine_end_date
    # Si une date de fin explicite est fournie, l'utiliser
    if @recurrence_rule['recurrence_end_date'].present?
      return Date.parse(@recurrence_rule['recurrence_end_date'])
    end

    # Sinon, utiliser la règle : 30 juin de cette année ou l'année suivante
    today = Date.current
    if today.month > 6
      Date.new(today.year + 1, 6, 30)
    else
      Date.new(today.year, 6, 30)
    end
  end

  # Calcule les occurrences hebdomadaires
  def calculate_weekly(start_date, end_date, day_of_week)
    day_symbol = DAY_MAPPING[day_of_week]
    unless day_symbol
      @error = "Jour de la semaine invalide: #{day_of_week}"
      return
    end

    current_date = start_date

    # Avancer jusqu'au prochain jour correspondant si nécessaire
    until current_date.public_send("#{day_symbol}?")
      current_date += 1.day
    end

    # Générer toutes les occurrences
    while current_date <= end_date
      @dates << current_date
      current_date += 1.week
    end
  end

  # Calcule les occurrences bi-hebdomadaires (une semaine sur deux)
  def calculate_biweekly(start_date, end_date, day_of_week)
    day_symbol = DAY_MAPPING[day_of_week]
    unless day_symbol
      @error = "Jour de la semaine invalide: #{day_of_week}"
      return
    end

    current_date = start_date

    # Avancer jusqu'au prochain jour correspondant
    until current_date.public_send("#{day_symbol}?")
      current_date += 1.day
    end

    # Générer les occurrences toutes les 2 semaines
    while current_date <= end_date
      @dates << current_date
      current_date += 2.weeks
    end
  end

  # Calcule les occurrences mensuelles (ex: "premier lundi du mois")
  def calculate_monthly(start_date, end_date, day_of_week)
    day_symbol = DAY_MAPPING[day_of_week]
    unless day_symbol
      @error = "Jour de la semaine invalide: #{day_of_week}"
      return
    end

    week_of_month = @recurrence_rule['week_of_month'] || 1

    current_month = start_date.beginning_of_month

    while current_month <= end_date
      # Trouver le N-ième jour de la semaine du mois
      date = find_nth_day_of_month(current_month, day_symbol, week_of_month)

      # Ajouter si dans la plage
      if date && date >= start_date && date <= end_date
        @dates << date
      end

      current_month += 1.month
    end
  end

  # Trouve le N-ième jour de la semaine dans un mois donné
  # @param month_start [Date] Premier jour du mois
  # @param day_symbol [Symbol] :monday, :tuesday, etc.
  # @param week_number [Integer] 1-4 (1 = premier, 2 = deuxième, etc.)
  def find_nth_day_of_month(month_start, day_symbol, week_number)
    current_date = month_start
    count = 0

    while current_date.month == month_start.month
      if current_date.public_send("#{day_symbol}?")
        count += 1
        return current_date if count == week_number
      end
      current_date += 1.day
    end

    nil
  end
end
