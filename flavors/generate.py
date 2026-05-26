#!/usr/bin/env python3
import os
import sys

try:
    import tomllib
except ModuleNotFoundError:
    print("Error: tomllib not found. This script requires Python 3.11+")
    sys.exit(1)

try:
    from jinja2 import Environment, FileSystemLoader, StrictUndefined, TemplateError
except ModuleNotFoundError:
    print("Error: Jinja2 not found.")
    print("Install it with: sudo apt install python3-jinja2")
    sys.exit(1)


def hex_to_rgb(hex_str: str) -> str:
    hex_str = hex_str.lstrip("#")
    return f"{int(hex_str[0:2], 16)}, {int(hex_str[2:4], 16)}, {int(hex_str[4:6], 16)}"


def hex_to_ansi(hex_str: str) -> str:
    hex_str = hex_str.lstrip("#")
    return f"{int(hex_str[0:2], 16)};{int(hex_str[2:4], 16)};{int(hex_str[4:6], 16)}"


def build_mapping(data: dict) -> dict[str, str]:
    mapping: dict[str, str] = {}

    for section, value in data.items():
        if isinstance(value, dict):
            for key, raw in value.items():
                raw = str(raw).strip().lstrip("#")
                name = f"{section}_{key}"

                mapping[name] = raw

                if raw and raw.lower() != "none":
                    try:
                        mapping[f"{name}_rgb"] = hex_to_rgb(raw)
                        mapping[f"{name}_ansi"] = hex_to_ansi(raw)
                    except ValueError:
                        pass
        else:
            mapping[section] = str(value)

    return mapping


def generate_theme(theme_name: str) -> None:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.dirname(script_dir)

    flavors_dir = os.path.join(root_dir, "flavors")
    base_dir = os.path.join(flavors_dir, "base")
    theme_file = os.path.join(flavors_dir, "palettes", f"{theme_name}.toml")

    if not os.path.exists(theme_file):
        print(f"Error: theme file not found: {theme_file}")
        sys.exit(1)

    with open(theme_file, "rb") as f:
        data = tomllib.load(f)

    mapping = build_mapping(data)

    env = Environment(
        loader=FileSystemLoader(base_dir),
        undefined=StrictUndefined,
        autoescape=False,
        keep_trailing_newline=True,
        trim_blocks=False,
        lstrip_blocks=False,
    )

    outputs = {
        "mako.conf.j2": ".config/mako/config",
        "starship.toml.j2": ".config/starship.toml",
        "dircolors.j2": ".dircolors",
        "hypr.conf.j2": ".config/hypr/theme.conf",
        "tmux.conf.j2": "tmux/theme.conf",
        "wofi.css.j2": ".config/wofi/style.css",
        "nvim.lua.j2": ".config/nvim/lua/theme.lua",
        "gitconfig.j2": ".gitconfig.d/theme",
    }

    print(f"Generating theme: {theme_name}")

    for template_name, rel_out_path in outputs.items():
        template_path = os.path.join(base_dir, template_name)

        if not os.path.exists(template_path):
            print(f"Warning: template not found: {template_path}")
            continue

        try:
            rendered = env.get_template(template_name).render(**mapping)
        except TemplateError as e:
            print(f"Error: failed rendering {template_name} for {theme_name}: {e}")
            sys.exit(1)

        out_path = os.path.join(root_dir, rel_out_path)
        os.makedirs(os.path.dirname(out_path), exist_ok=True)

        if os.path.islink(out_path):
            os.unlink(out_path)

        with open(out_path, "w", encoding="utf-8") as f:
            f.write(rendered)

        print(f"  -> Created {rel_out_path}")


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python3 generate.py <theme_name> [theme_name ...]")
        print("Example: python3 generate.py malachite")
        sys.exit(1)

    for theme in sys.argv[1:]:
        generate_theme(theme)


if __name__ == "__main__":
    main()