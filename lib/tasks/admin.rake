# frozen_string_literal: true

namespace :admin do
  desc "Interactively create a platform super admin"
  task create: :environment do
    require "io/console"

    prompt = ->(label) do
      print label
      STDIN.gets.to_s.strip
    end

    secret_prompt = ->(label) do
      print label
      value = STDIN.noecho(&:gets).to_s.chomp
      puts
      value
    end

    email = prompt.call("Email: ")
    abort "ERROR: email is required" if email.blank?
    abort "ERROR: user already exists for #{email}" if User.exists?(email: email)

    password = secret_prompt.call("Password: ")
    password_confirmation = secret_prompt.call("Repeat password: ")

    abort "ERROR: password is required" if password.blank?
    abort "ERROR: passwords do not match" unless password == password_confirmation

    confirmation = prompt.call("Turn #{email} into a super admin? Type YES to confirm: ")
    abort "No user created." unless confirmation == "YES"

    user = User.new(
      email: email,
      password: password,
      password_confirmation: password_confirmation,
      system_role: :super_admin
    )
    user.skip_confirmation!

    if user.save
      puts "Super admin created: #{email}"
    else
      abort "ERROR: could not create user — #{user.errors.full_messages.join(', ')}"
    end
  end
end
