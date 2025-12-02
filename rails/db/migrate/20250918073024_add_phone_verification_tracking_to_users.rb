class AddPhoneVerificationTrackingToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone_verification_last_sent_at, :datetime
    add_column :users, :phone_verification_attempts, :integer
  end
end
