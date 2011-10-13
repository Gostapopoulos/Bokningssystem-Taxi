class CreateBookings < ActiveRecord::Migration
  def change
    create_table :bookings do |t|
      t.string :mottagare
      t.datetime :utrop
      t.datetime :hamttid
      t.string :fran
      t.string :till
      t.string :namn
      t.string :anm
      t.string :status
      t.integer :bil
      t.string :telefonnr
      t.integer :utroptimmar
      t.integer :utropminuter

      t.timestamps
    end
  end
end
