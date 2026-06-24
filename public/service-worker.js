self.addEventListener("push", (event) => {
  const payload = parsePushPayload(event.data)
  const title = payload.title || "Pavê"
  const url = safeNotificationUrl(payload.url)

  const options = {
    body: payload.body || "",
    icon: "/icon.png",
    badge: "/icon.png",
    tag: payload.tag || `notification-${Date.now()}`,
    data: { url }
  }

  event.waitUntil(self.registration.showNotification(title, options))
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()

  const targetUrl = safeNotificationUrl(event.notification.data && event.notification.data.url)

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((windowClients) => {
      const existingClient = windowClients.find((client) => client.url === targetUrl)
      if (existingClient) return existingClient.focus()

      return clients.openWindow(targetUrl)
    })
  )
})

function parsePushPayload(data) {
  if (!data) return {}

  try {
    return data.json()
  } catch (_error) {
    return { body: data.text() }
  }
}

function safeNotificationUrl(value) {
  const url = new URL(value || "/", self.location.origin)

  return url.origin === self.location.origin ? url.href : self.location.origin
}
