class AddLastScrapingStatusToTeacherUrls < ActiveRecord::Migration[8.0]
  def change
    add_column :teacher_urls, :last_scraping_status, :string
  end
end
