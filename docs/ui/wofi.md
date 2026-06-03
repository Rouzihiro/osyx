# Wofi

Wofi is the launcher layer, used as a small keyboard-first menu surface for launching apps and picking generated lists.

App launching is rare in my workflow. Most Wofi usage is clipboard management where it acts as a fast selection surface.

**Files:**

`config/.config/wofi/config` ---> maps to: `~/.config/wofi/config`
`config/.config/wofi/style.css` ---> maps to: `~/.config/wofi/style.css`

The static config controls launcher behavior.

`style.css` is generated theme output.

```text
packages/flavors/base/wofi.css.j2
        ↓
packages/flavors/generate.py
        ↓
config/.config/wofi/style.css
```
