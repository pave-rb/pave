# Pavê web icon kit

Generated from the supplied Pavê artwork as square PNG assets for a Rails 8 app.

## Recommended Rails placement

```txt
public/icon.png                  # copy from icon.png
public/favicon.ico               # copy from favicon.ico
public/apple-touch-icon.png      # copy from apple-touch-icon.png
app/assets/images/pave-icon.png  # copy from pave-icon-transparent-1024.png
```

## Navbar/logo usage

```erb
<%= image_tag "pave-icon-transparent-1024.png", alt: "Pavê", class: "h-8 w-8" %>
```

## Notes

- `pave-icon-square-1024.png` is best for social previews, app icons, and browser icons.
- `pave-icon-transparent-1024.png` is best inside the UI on light or controlled backgrounds.
- Very small favicon sizes are included, but this mark is detail-heavy; prefer 32px+ where possible.
