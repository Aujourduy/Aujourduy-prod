class CreateVenues < ActiveRecord::Migration[8.0]
  def change
    create_table :venues, id: :uuid do |t|
      t.string :name
      t.string :address_line1
      t.string :address_line2
      t.string :postal_code
      t.string :city
      t.string :region
      t.string :country
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6


      t.timestamps
    end
  end
end
