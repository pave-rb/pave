Pave::Backoffice.product(:demo_scheduling) do |backoffice|
  backoffice.panel :dashboard,
    label: "Dashboard",
    controller: "demo_scheduling/backoffice/dashboard",
    position: 10

  backoffice.panel :appointments,
    label: "Appointments",
    controller: "demo_scheduling/backoffice/appointments",
    position: 20

  backoffice.panel :spaces,
    label: "Spaces",
    controller: "demo_scheduling/backoffice/spaces",
    position: 30

  backoffice.panel :users,
    label: "Users",
    controller: "demo_scheduling/backoffice/users",
    position: 40
end
