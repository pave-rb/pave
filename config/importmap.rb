# Pin npm packages by running ./bin/importmap

pin "application"
pin "confirm_modal", to: "confirm_modal.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from Pave::Backoffice::Engine.root.join("app/javascript/controllers").to_s, under: "controllers"
Pave.products.each do |product|
  next unless product.legacy_constants?

  controllers_path = product.root.join("app/javascript/controllers")
  pin_all_from controllers_path.to_s, under: "controllers" if controllers_path.directory?
end
pin_all_from "app/javascript/utils", under: "utils"
pin "flatpickr" # @4.6.13
