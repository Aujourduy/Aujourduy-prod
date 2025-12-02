class TestController < ApplicationController
  def index
    # On liste tous les fichiers du dossier app/views/test/
    @pages = Dir.glob(Rails.root.join("app", "views", "test", "*.html.erb"))
                .map { |f| File.basename(f, ".html.erb") }
                .sort
  end

  def show
    page = params[:page]

    if lookup_context.template_exists?(page, ["test"])
      render template: "test/#{page}"
    else
      render plain: "Vue introuvable", status: :not_found
    end
  end
end
