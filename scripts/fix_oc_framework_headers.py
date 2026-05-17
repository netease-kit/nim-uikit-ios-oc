#!/usr/bin/env python3

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import DefaultDict, Dict, Iterable, Optional, Set, Tuple


MODULE_CLASS_DIRS: Dict[str, str] = {
    "NECommonUIKitOC": "Common/NECommonUIKitOC/NECommonUIKitOC/Classes",
    "NEChatKitOC": "IMUIKit/NEChatKitOC/NEChatKitOC/Classes",
    "NEConversationUIKitOC": "IMUIKit/NEConversationUIKitOC/NEConversationUIKitOC/Classes",
    "NEContactUIKitOC": "IMUIKit/NEContactUIKitOC/NEContactUIKitOC/Classes",
    "NEChatUIKitOC": "IMUIKit/NEChatUIKitOC/NEChatUIKitOC/Classes",
    "NETeamUIKitOC": "IMUIKit/NETeamUIKitOC/NETeamUIKitOC/Classes",
    "NEMapKitOC": "IMUIKit/NEMapKitOC/NEMapKitOC/Classes",
    "NEAISearchKitOC": "IMUIKit/NEAISearchKitOC/NEAISearchKitOC/Classes",
}

IMPORT_RE = re.compile(
    r'^(?P<prefix>\s*#\s*(?:import|include)\s*)"(?P<path>[^"]+\.h)"(?P<suffix>.*)$'
)
RELATIVE_IMPORT_RE = re.compile(r'^\s*#\s*(?:import|include)\s*"\.\.?/')


def build_header_index(source_root: Path) -> DefaultDict[str, Set[str]]:
    index: DefaultDict[str, Set[str]] = defaultdict(set)
    for module, rel_dir in MODULE_CLASS_DIRS.items():
        classes_dir = source_root / rel_dir
        if not classes_dir.is_dir():
            continue
        for header in classes_dir.rglob("*.h"):
            index[header.name].add(module)
    return index


def framework_headers(framework: Path) -> Set[str]:
    headers_dir = framework / "Headers"
    if not headers_dir.is_dir():
        return set()
    return {path.name for path in headers_dir.glob("*.h")}


def choose_replacement(
    *,
    module: str,
    import_path: str,
    current_headers: Set[str],
    header_index: Dict[str, Set[str]],
) -> Optional[str]:
    basename = Path(import_path).name
    owners = header_index.get(basename, set())
    is_path_import = "/" in import_path

    if is_path_import:
        if basename in current_headers:
            return f'"{basename}"'
        if len(owners) == 1:
            owner = next(iter(owners))
            if owner == module:
                return f'"{basename}"'
            return f"<{owner}/{basename}>"
        return None

    if basename in current_headers:
        return None

    external_owners = owners - {module}
    if len(external_owners) == 1:
        owner = next(iter(external_owners))
        return f"<{owner}/{basename}>"

    return None


def rewritten_line(
    *,
    line: str,
    module: str,
    current_headers: Set[str],
    header_index: Dict[str, Set[str]],
) -> Tuple[str, bool]:
    match = IMPORT_RE.match(line)
    if not match:
        return line, False

    replacement = choose_replacement(
        module=module,
        import_path=match.group("path"),
        current_headers=current_headers,
        header_index=header_index,
    )
    if replacement is None:
        return line, False

    return f"{match.group('prefix')}{replacement}{match.group('suffix')}", True


def rewrite_header(
    *,
    header: Path,
    module: str,
    current_headers: Set[str],
    header_index: Dict[str, Set[str]],
    dry_run: bool,
) -> int:
    lines = header.read_text(encoding="utf-8").splitlines(keepends=True)
    rewritten = []
    count = 0
    for line in lines:
        new_line, changed = rewritten_line(
            line=line,
            module=module,
            current_headers=current_headers,
            header_index=header_index,
        )
        rewritten.append(new_line)
        if changed:
            count += 1

    if count and not dry_run:
        header.write_text("".join(rewritten), encoding="utf-8")
    return count


def unresolved_relative_imports(headers: Iterable[Path]) -> list[Tuple[Path, int, str]]:
    unresolved: list[Tuple[Path, int, str]] = []
    for header in headers:
        for index, line in enumerate(header.read_text(encoding="utf-8").splitlines(), start=1):
            if RELATIVE_IMPORT_RE.match(line):
                unresolved.append((header, index, line.strip()))
    return unresolved


def rewrite_framework_headers(
    *,
    framework: Path,
    module: str,
    source_root: Path,
    dry_run: bool,
    fail_on_rewrite: bool,
    fail_on_unresolved_relative: bool,
) -> int:
    headers_dir = framework / "Headers"
    if not headers_dir.is_dir():
        return 0

    header_index = build_header_index(source_root)
    current_headers = framework_headers(framework)
    headers = sorted(headers_dir.glob("*.h"))

    rewrite_count = 0
    for header in headers:
        rewrite_count += rewrite_header(
            header=header,
            module=module,
            current_headers=current_headers,
            header_index=header_index,
            dry_run=dry_run,
        )

    unresolved = unresolved_relative_imports(headers)
    if fail_on_unresolved_relative and unresolved:
        print(f"error: unresolved relative imports remain in {framework}", file=sys.stderr)
        for header, line_no, import_line in unresolved[:30]:
            print(f"  {header}:{line_no}: {import_line}", file=sys.stderr)
        if len(unresolved) > 30:
            print(f"  ... {len(unresolved) - 30} more", file=sys.stderr)
        raise SystemExit(1)

    if rewrite_count:
        action = "would rewrite" if dry_run else "rewrote"
        print(f"{action} {rewrite_count} header imports in {framework}")
        if fail_on_rewrite:
            print(
                "error: framework public headers require import cleanup in source before release",
                file=sys.stderr,
            )
            raise SystemExit(1)
    return rewrite_count


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Rewrite OC framework public header imports for flattened binary distribution."
    )
    parser.add_argument("--framework", required=True, help="Path to Foo.framework")
    parser.add_argument("--module", required=True, help="Framework module name")
    parser.add_argument("--source-root", required=True, help="Repository root used to scan header ownership")
    parser.add_argument("--dry-run", action="store_true", help="Print changes without writing files")
    parser.add_argument(
        "--fail-on-rewrite",
        action="store_true",
        help="Fail when any public header import would need rewriting",
    )
    parser.add_argument(
        "--fail-on-unresolved-relative",
        action="store_true",
        help="Fail when public headers still contain ../ relative imports after rewriting",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    rewrite_framework_headers(
        framework=Path(args.framework).resolve(),
        module=args.module,
        source_root=Path(args.source_root).resolve(),
        dry_run=args.dry_run,
        fail_on_rewrite=args.fail_on_rewrite,
        fail_on_unresolved_relative=args.fail_on_unresolved_relative,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
