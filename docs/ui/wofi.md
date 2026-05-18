# Wofi

Wofi is the launcher layer, used as a small keyboard-first menu surface for launching apps and picking generated lists.

App launching is rare in my workflow. Most Wofi usage is clipboard management.

It acts as a fast selection surface.

## Files

```text
.config/wofi/config
.config/wofi/style.css
```

The static config controls launcher behavior.

`style.css` is generated theme output.

```text
flavors/base/wofi.css.j2
        ↓
flavors/generate.py
        ↓
.config/wofi/style.css
```
