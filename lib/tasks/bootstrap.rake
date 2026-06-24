namespace :bootstrap do
  desc "Upsert billing plans and credit bundles (idempotent, safe for all environments)"
  task reference_data: :environment do
    puts "== Billing Plans =="
    [
      { slug: "essential", name: "Essential", price_cents: 4999,
        max_team_members: 1, max_customers: 100, max_scheduling_links: 3,
        whatsapp_monthly_quota: 0, features: [], allowed_payment_methods: [],
        position: 1, public: true, highlighted: false, trial_default: false, active: true },
      { slug: "pro", name: "Pro", price_cents: 11990,
        max_team_members: 5, max_customers: nil, max_scheduling_links: nil,
        whatsapp_monthly_quota: 200,
        features: %w[personalized_booking_page custom_appointment_policies whatsapp_included_quota],
        allowed_payment_methods: [],
        position: 2, public: true, highlighted: true, trial_default: true, active: true },
      { slug: "enterprise", name: "Enterprise", price_cents: 29999,
        max_team_members: nil, max_customers: nil, max_scheduling_links: nil,
        whatsapp_monthly_quota: nil,
        features: %w[personalized_booking_page custom_appointment_policies whatsapp_included_quota priority_support],
        allowed_payment_methods: %w[credit_card],
        position: 3, public: true, highlighted: false, trial_default: false, active: true }
    ].each do |attrs|
      plan = Billing::Plan.find_or_initialize_by(slug: attrs[:slug])
      plan.assign_attributes(attrs)

      if plan.new_record?
        plan.save!
        puts "  Created plan: #{plan.name}"
      elsif plan.changed?
        plan.save!
        puts "  Updated plan: #{plan.name}"
      else
        puts "  Plan unchanged: #{plan.name}"
      end
    end

    puts "\n== Credit Bundles =="
    [
      { name: "50 credits",  amount: 50,  price_cents: 2500, position: 0, active: true },
      { name: "100 credits", amount: 100, price_cents: 4500, position: 1, active: true },
      { name: "200 credits", amount: 200, price_cents: 8000, position: 2, active: true }
    ].each do |attrs|
      bundle = Billing::CreditBundle.find_or_initialize_by(name: attrs[:name])
      bundle.assign_attributes(attrs)

      if bundle.new_record?
        bundle.save!
        puts "  Created bundle: #{bundle.name}"
      elsif bundle.changed?
        bundle.save!
        puts "  Updated bundle: #{bundle.name}"
      else
        puts "  Bundle unchanged: #{bundle.name}"
      end
    end
  end
end
