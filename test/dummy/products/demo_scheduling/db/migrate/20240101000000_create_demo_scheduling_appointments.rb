class CreateDemoSchedulingAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :demo_scheduling_appointments do |t|
      t.string :title, null: false
      t.datetime :scheduled_at, null: false
      t.string :status, default: "pending", null: false
      t.references :space, null: true, foreign_key: true
      t.timestamps
    end
  end
end
