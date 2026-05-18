# Dircolors

`dircolors` controls how file types appear in terminal listings.

Commands like:

```sh
ls
lsd
eza
```

read the `LS_COLORS` environment variable to decide how directories, executables, symlinks, archives, images, videos, Git folders, sockets, permissions, and special files should be colored.

Without `dircolors`, terminal listings become inconsistent, low-contrast, or dependent on distro defaults.

I use `lsd` though, since it shows icons. Aliased as `l` (from [zsh](./zsh.md)).

The theme engine generates a dircolors file from the active palette.

Example flow:

```text
palette
  ↓
dircolors template
  ↓
generated LS_COLORS
  ↓
shell export
  ↓
terminal listings
```

The file is right here `~/.dircolors`.

The shell then loads the generated theme through [zsh](./zsh.md):

```sh
eval "$(dircolors ~/.dircolors)"
```

## What changes

| Type          | Meaning              |
| ------------- | -------------------- |
| directories   | accent color         |
| executables   | success/active color |
| symlinks      | secondary accent     |
| archives      | warning color        |
| images/videos | media color          |
| broken links  | error color          |
| sockets/pipes | utility color        |

## Relationship with `lsd`

`lsd` already has its own theme layer, but `LS_COLORS` still matters because:

- many tools still read it directly
- fallback tools use it
- SSH sessions may not use `lsd`
- scripts and subshells inherit it automatically

So the setup keeps `dircolors` as the low-level color substrate even when higher-level tools exist.
