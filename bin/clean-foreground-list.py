#!/usr/bin/env python3

import argparse
import re
import sys


_NON_ALNUM_RE = re.compile(r"[^0-9A-Za-z_]")


def _sanitize_item(item: str) -> str:
    return _NON_ALNUM_RE.sub("_", item)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input",
        nargs="?",
        help="Newline-separated list file. If omitted, reads from stdin.",
    )
    parser.add_argument(
        "--output",
        nargs="?",
        help="Name of output file. If omitted, writes to stdout.",
    )
    args = parser.parse_args(argv)

    if args.input:
        with open(args.input, "r", encoding="utf-8") as f:
            lines = f.readlines()
    else:
        lines = sys.stdin.readlines()

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            for raw in lines:
                item = raw.strip()
                if not item:
                    continue
                f.write(_sanitize_item(item) + "\n")
    else:
        for raw in lines:
            item = raw.strip()
            if not item:
                continue
            sys.stdout.write(_sanitize_item(item) + "\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
