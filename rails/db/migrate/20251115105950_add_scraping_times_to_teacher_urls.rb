class AddScrapingTimesToTeacherUrls < ActiveRecord::Migration[8.0]
  def change
    add_column :teacher_urls, :start_scraping_at, :datetime
    add_column :teacher_urls, :end_scraping_at, :datetime
  end
end
