class AddLastScrapingErrorDetailsToTeacherUrls < ActiveRecord::Migration[8.0]
  def change
    add_column :teacher_urls, :last_scraping_error_details, :text
  end
end
