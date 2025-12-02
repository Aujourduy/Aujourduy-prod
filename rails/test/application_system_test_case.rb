require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Configuration Chrome pour Docker
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |driver_options|
    driver_options.add_argument('--no-sandbox')
    driver_options.add_argument('--disable-dev-shm-usage')
    driver_options.add_argument('--disable-gpu')
    driver_options.add_argument('--window-size=1400,1400')
    driver_options.add_argument('--headless=new')
    driver_options.add_argument('--disable-crash-reporter')
    driver_options.add_argument('--disable-software-rasterizer')
    driver_options.add_argument('--disable-extensions')
    # Cache Selenium dans un dossier accessible
    driver_options.add_argument('--user-data-dir=/tmp/chrome-user-data')
    # Chemin explicite vers Chromium dans Docker
    driver_options.binary = '/usr/bin/chromium'
  end

  # Helper pour login via formulaire (pour tests système)
  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123" # Mot de passe par défaut des fixtures
    click_button "Log in"
  end
end
