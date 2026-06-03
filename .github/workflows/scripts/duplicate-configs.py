import hashlib
import subprocess
import sys
import os
import re
from typing import Optional

EXCLUDE_RE: re.Pattern[str] = re.compile(
    r"""(?x)(
        ^\.git/|
        ^\.gnupg/|
        ^\.ssh/|
        \.gpg$|
        ^\.exported/|
        ^\.local/share/|
        ^\.wallpapers/|
        ^\.icons/|
        ^\.themes/|
        ^dircolors/|
        /themes/|
        ^\.terminfo/|
        \.png$|\.jpg$|\.jpeg$|\.webp$|\.gif$|\.ico$|
        \.ttf$|\.otf$|\.woff2?$|
        \.pdf$|\.zip$|\.tar$|\.gz$|\.7z$|\.rar$
    )"""
)

FOCUS_RE: re.Pattern[str] = re.compile(
    r"""(?x)(
        ^config/|
        ^packages/flavors/|
        ^provisioning/|
        ^scripts/|
        ^\.vscode/|
        ^\.storybook/|
        ^README\.md$
    )"""
)


def git_ls() -> list[str]:
    out: str = subprocess.check_output(
        ["git", "ls-files", "--stage"],
        text=True,
    )

    files: list[str] = []
    for line in out.splitlines():
        parts: list[str] = line.split()
        mode: str = parts[0]
        path: str = parts[-1]

        if mode == "160000":
            continue

        files.append(path)

    return files


def read_file(path: str) -> Optional[bytes]:
    try:
        with open(path, "rb") as fp:
            return fp.read()
    except Exception:
        return None


def hash_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def collect_groups(files: list[str]) -> dict[str, list[str]]:
    groups: dict[str, list[str]] = {}

    for f in files:
        if not os.path.isfile(f):
            continue

        data: Optional[bytes] = read_file(f)
        if not data:
            continue

        h: str = hash_bytes(data)
        groups.setdefault(h, []).append(f)

    return groups


def find_duplicates(groups: dict[str, list[str]]) -> list[tuple[str, list[str]]]:
    return [(h, fs) for h, fs in groups.items() if len(fs) > 1]


def main() -> None:
    files: list[str] = git_ls()
    files = [f for f in files if not EXCLUDE_RE.search(f)]
    files = [f for f in files if FOCUS_RE.search(f)]

    groups: dict[str, list[str]] = collect_groups(files)
    dupes: list[tuple[str, list[str]]] = find_duplicates(groups)

    if dupes:
        print("Exact duplicate content found:")
        for h, fs in dupes:
            print(f"\nsha256:{h}")
            for f in fs:
                print(f"  - {f}")
        sys.exit(1)

    print("OK: no duplicate content in focused config set.")


if __name__ == "__main__":
    main()
