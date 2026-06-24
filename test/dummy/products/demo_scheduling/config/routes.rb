scope module: "demo_scheduling", as: "demo_scheduling" do
  get "/", to: "backoffice/dashboard#index"
end
