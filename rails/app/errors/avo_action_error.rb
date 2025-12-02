# Exception personnalisée pour les actions Avo
# Permet d'afficher des messages d'erreur propres sans stack trace
class AvoActionError < StandardError
  attr_reader :title, :details, :hint

  def initialize(title:, details:, hint: nil)
    @title = title
    @details = details
    @hint = hint
    super("#{title}: #{details}")
  end
end
