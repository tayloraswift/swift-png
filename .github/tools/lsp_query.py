#  ❣❣❣  DO NOT EDIT  ❣  THIS FILE IS AUTOMATICALLY SYNCED  ❣  DO NOT EDIT  ❣❣❣
#!/usr/bin/env python3
"""
SourceKit-LSP Helper Script for Swift Symbol Resolution and Macro Expansion.
Provides CLI access to workspace symbols, definitions, hover type info, references, and macro expansion.
"""

import sys
import os
import json
import subprocess
import shutil
import argparse
import re
from typing import Dict, Any, Optional, List

def find_sourcekit_lsp() -> str:
    path = shutil.which("sourcekit-lsp")
    if path:
        return path
    default_path = "/opt/swift/usr/bin/sourcekit-lsp"
    if os.path.exists(default_path):
        return default_path
    raise RuntimeError("sourcekit-lsp binary not found.")

class LSPClient:
    def __init__(self, root_dir: str):
        self.root_dir = os.path.abspath(root_dir)
        self.binary = find_sourcekit_lsp()
        self.proc = subprocess.Popen(
            [self.binary],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.req_id = 0
        self._initialize()

    def _send(self, method: str, params: Optional[Dict[str, Any]] = None) -> int:
        self.req_id += 1
        payload = {"jsonrpc": "2.0", "id": self.req_id, "method": method}
        if params is not None:
            payload["params"] = params
        body = json.dumps(payload)
        msg = f"Content-Length: {len(body)}\r\n\r\n{body}"
        self.proc.stdin.write(msg.encode("utf-8"))
        self.proc.stdin.flush()
        return self.req_id

    def _notify(self, method: str, params: Optional[Dict[str, Any]] = None):
        payload = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            payload["params"] = params
        body = json.dumps(payload)
        msg = f"Content-Length: {len(body)}\r\n\r\n{body}"
        self.proc.stdin.write(msg.encode("utf-8"))
        self.proc.stdin.flush()

    def _read_response(self, target_id: int) -> Optional[Dict[str, Any]]:
        while True:
            line = self.proc.stdout.readline().decode("utf-8", errors="ignore")
            if not line:
                return None
            if line.startswith("Content-Length:"):
                length = int(line.split(":")[1].strip())
                # Read until double newline
                while line.strip() != "":
                    line = self.proc.stdout.readline().decode("utf-8", errors="ignore")
                body = self.proc.stdout.read(length).decode("utf-8", errors="ignore")
                data = json.loads(body)
                if data.get("id") == target_id:
                    if "error" in data:
                        print(f"LSP Error: {data['error']}", file=sys.stderr)
                        return None
                    return data.get("result")

    def _initialize(self):
        req_id = self._send(
            "initialize",
            {
                "processId": os.getpid(),
                "rootUri": f"file://{self.root_dir}",
                "capabilities": {
                    "workspace": {
                        "symbol": {"dynamicRegistration": False},
                        "executeCommand": {"dynamicRegistration": False},
                    },
                    "textDocument": {
                        "definition": {"dynamicRegistration": False},
                        "references": {"dynamicRegistration": False},
                        "hover": {"dynamicRegistration": False},
                        "codeAction": {
                            "dynamicRegistration": False,
                            "codeActionLiteralSupport": {
                                "codeActionKind": {
                                    "valueSet": [
                                        "",
                                        "quickfix",
                                        "refactor",
                                        "refactor.extract",
                                        "refactor.inline",
                                        "refactor.rewrite",
                                        "source",
                                    ]
                                }
                            },
                        },
                    },
                },
            },
        )
        self._read_response(req_id)
        self._notify("initialized", {})

    def _ensure_open(self, abs_path: str):
        if os.path.exists(abs_path):
            try:
                with open(abs_path, "r", encoding="utf-8") as f:
                    text = f.read()
                self._notify(
                    "textDocument/didOpen",
                    {
                        "textDocument": {
                            "uri": f"file://{abs_path}",
                            "languageId": "swift",
                            "version": 1,
                            "text": text,
                        }
                    },
                )
            except Exception:
                pass

    def query_workspace_symbols(self, query: str) -> Any:
        req_id = self._send("workspace/symbol", {"query": query})
        return self._read_response(req_id)

    def query_definition(self, file_path: str, line: int, col: int) -> Any:
        abs_path = os.path.abspath(file_path)
        self._ensure_open(abs_path)
        req_id = self._send(
            "textDocument/definition",
            {
                "textDocument": {"uri": f"file://{abs_path}"},
                "position": {"line": line - 1, "character": col - 1},
            },
        )
        return self._read_response(req_id)

    def query_hover(self, file_path: str, line: int, col: int) -> Any:
        abs_path = os.path.abspath(file_path)
        self._ensure_open(abs_path)
        req_id = self._send(
            "textDocument/hover",
            {
                "textDocument": {"uri": f"file://{abs_path}"},
                "position": {"line": line - 1, "character": col - 1},
            },
        )
        return self._read_response(req_id)

    def query_references(self, file_path: str, line: int, col: int) -> Any:
        abs_path = os.path.abspath(file_path)
        self._ensure_open(abs_path)
        req_id = self._send(
            "textDocument/references",
            {
                "textDocument": {"uri": f"file://{abs_path}"},
                "position": {"line": line - 1, "character": col - 1},
                "context": {"includeDeclaration": True},
            },
        )
        return self._read_response(req_id)

    def _extract_expansions_from_edit(self, edit: Any, header: str, line: Optional[int]) -> List[Dict[str, Any]]:
        expansions = []
        if isinstance(edit, dict):
            if "changes" in edit and isinstance(edit["changes"], dict):
                for uri, text_edits in edit["changes"].items():
                    for te in text_edits:
                        new_text = te.get("newText", "").strip()
                        if new_text:
                            expansions.append({
                                "header": header or uri,
                                "expansion": new_text,
                                "line": line,
                                "type": "lsp_code_action",
                            })
            if "documentChanges" in edit and isinstance(edit["documentChanges"], list):
                for doc_change in edit["documentChanges"]:
                    edits = doc_change.get("edits", [])
                    uri = doc_change.get("textDocument", {}).get("uri", "")
                    for te in edits:
                        new_text = te.get("newText", "").strip()
                        if new_text:
                            expansions.append({
                                "header": header or uri,
                                "expansion": new_text,
                                "line": line,
                                "type": "lsp_code_action",
                            })
        elif isinstance(edit, str) and edit.strip():
            expansions.append({
                "header": header or "Macro Expansion",
                "expansion": edit.strip(),
                "line": line,
                "type": "lsp_command",
            })
        return expansions

    @staticmethod
    def _dedup_expansions(items: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        dedup = []
        seen = set()
        for item in items:
            key = (item.get("header"), item.get("expansion"))
            if key not in seen:
                seen.add(key)
                dedup.append(item)
        return dedup

    def query_expand(self, file_path: str, line: Optional[int] = None, col: Optional[int] = None) -> Any:
        abs_path = os.path.abspath(file_path)
        if not os.path.exists(abs_path):
            return [{"error": f"File not found: {abs_path}"}]

        self._ensure_open(abs_path)

        # 1. Try LSP codeAction / executeCommand if position is provided
        if line is not None and col is not None:
            req_id = self._send(
                "textDocument/codeAction",
                {
                    "textDocument": {"uri": f"file://{abs_path}"},
                    "range": {
                        "start": {"line": line - 1, "character": max(0, col - 1)},
                        "end": {"line": line - 1, "character": col},
                    },
                    "context": {"diagnostics": []},
                },
            )
            actions = self._read_response(req_id)
            if actions:
                for action in actions:
                    title = action.get("title", "")
                    if "expand" in title.lower() or "macro" in title.lower():
                        if "edit" in action:
                            res = self._extract_expansions_from_edit(action["edit"], title, line)
                            if res:
                                return res
                        if "command" in action:
                            cmd_req = self._send("workspace/executeCommand", action["command"])
                            cmd_res = self._read_response(cmd_req)
                            if cmd_res:
                                res = self._extract_expansions_from_edit(cmd_res, title, line)
                                if res:
                                    return res

            # Try expand.macro.command directly
            req_id = self._send(
                "workspace/executeCommand",
                {
                    "command": "expand.macro.command",
                    "arguments": [
                        {
                            "textDocument": {"uri": f"file://{abs_path}"},
                            "position": {"line": line - 1, "character": col - 1},
                        }
                    ],
                },
            )
            cmd_res = self._read_response(req_id)
            if cmd_res:
                res = self._extract_expansions_from_edit(cmd_res, "Expand Macro", line)
                if res:
                    return res

        # 2. Extract macro expansions via compiler frontend
        return self._dump_macro_expansions(abs_path, line)

    def _dump_macro_expansions(self, abs_path: str, line: Optional[int] = None) -> List[Dict[str, Any]]:
        # Check if project has been built first
        build_dir = os.path.join(self.root_dir, ".build")
        if not os.path.isdir(build_dir):
            return [{
                "error": (
                    f"Project build directory '{build_dir}' not found. "
                    "Please build the project ('swift build' or 'swift test') first so that build artifacts "
                    "and macro plugins are available."
                )
            }]

        target_line_text = ""
        try:
            with open(abs_path, "r", encoding="utf-8") as f:
                file_lines = f.readlines()
            if line is not None and 0 <= line - 1 < len(file_lines):
                target_line_text = file_lines[line - 1].strip()
        except Exception:
            pass

        # Touch the file to ensure swiftc re-analyzes it during dump
        try:
            os.utime(abs_path, None)
        except Exception:
            pass

        cmd = ["swift", "build", "--skip-update"]
        if "/Tests/" in abs_path or abs_path.endswith("Tests.swift"):
            cmd.append("--build-tests")
        cmd.extend(["-Xswiftc", "-Xfrontend", "-Xswiftc", "-dump-macro-expansions"])

        try:
            res = subprocess.run(cmd, cwd=self.root_dir, capture_output=True, text=True, timeout=60)
            if res.returncode != 0:
                err = res.stderr.strip() or res.stdout.strip()
                return [{
                    "error": (
                        f"Failed to dump macro expansions (exit code {res.returncode}). "
                        "Please ensure the project builds successfully ('swift build' or 'swift test') first.\n"
                        f"Build output:\n{err}"
                    )
                }]
            out = res.stdout + "\n" + res.stderr
        except Exception as e:
            return [{"error": f"Failed to dump macro expansions: {e}"}]

        blocks = out.split("------------------------------\n")
        expansions = []
        i = 0
        while i < len(blocks) - 1:
            raw_header = blocks[i].strip()
            body = blocks[i + 1].rstrip()
            header_lines = [l.strip() for l in raw_header.splitlines() if l.strip()]
            macro_header = header_lines[-1] if header_lines else raw_header

            if body and not body.isspace() and not body.startswith("#"):
                expansions.append({"header": macro_header, "expansion": body})
            i += 2

        if line is None:
            return self._dedup_expansions(expansions)

        # Match freestanding: MX<line-1> or MX<line>
        freestanding_matches = []
        for exp in expansions:
            m = re.search(r"MX(\d+)_(\d+)_", exp["header"])
            if m:
                m_l = int(m.group(1))
                if m_l == line or m_l == line - 1:
                    freestanding_matches.append({
                        "header": exp["header"],
                        "expansion": exp["expansion"],
                        "line": line,
                        "type": "freestanding",
                    })
        if freestanding_matches:
            return self._dedup_expansions(freestanding_matches)

        # Match attached macros by declared symbol name
        m_decl = re.search(r"\b(?:var|let|func|enum|struct|class|actor|protocol)\s+([A-Za-z_][A-Za-z0-9_]*)", target_line_text)
        decl_name = m_decl.group(1) if m_decl else None
        if decl_name:
            decl_matches = []
            for exp in expansions:
                h = exp["header"]
                if f"{len(decl_name)}{decl_name}" in h or f"_{decl_name}" in h or f"{decl_name}0" in h or f"{decl_name}O" in h or f"{decl_name}V" in h:
                    decl_matches.append({
                        "header": exp["header"],
                        "expansion": exp["expansion"],
                        "matched_symbol": decl_name,
                        "line": line,
                        "type": "attached",
                    })
            if decl_matches:
                return self._dedup_expansions(decl_matches)

        # Fallback to matching any non-keyword identifier on the line
        keywords = {
            "var", "let", "func", "enum", "struct", "class", "public", "private",
            "fileprivate", "internal", "open", "inlinable", "mutating", "nonmutating",
            "get", "set", "where", "import", "case", "switch", "default", "return",
            "self", "Self", "some", "any", "async", "throws",
        }
        identifiers = [
            ident for ident in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", target_line_text)
            if ident not in keywords and len(ident) > 1
        ]
        attached_matches = []
        for ident in identifiers:
            for exp in expansions:
                if ident in exp["header"]:
                    attached_matches.append({
                        "header": exp["header"],
                        "expansion": exp["expansion"],
                        "matched_symbol": ident,
                        "line": line,
                        "type": "attached",
                    })

        if attached_matches:
            return self._dedup_expansions(attached_matches)

        return expansions

    def close(self):
        try:
            req_id = self._send("shutdown")
            self._read_response(req_id)
            self._notify("exit")
        except Exception:
            pass
        finally:
            if self.proc.poll() is None:
                self.proc.terminate()
                try:
                    self.proc.wait(timeout=1)
                except subprocess.TimeoutExpired:
                    self.proc.kill()

def main():
    parser = argparse.ArgumentParser(description="Query sourcekit-lsp for Swift symbols and macro expansion")
    parser.add_argument("--dir", default=os.getcwd(), help="Workspace root directory")
    subparsers = parser.add_subparsers(dest="subcommand", required=True)

    # symbol subcommand
    sym_parser = subparsers.add_parser("symbol", help="Search workspace symbols")
    sym_parser.add_argument("query", help="Symbol name or prefix")

    # definition subcommand
    def_parser = subparsers.add_parser("definition", help="Go to definition")
    def_parser.add_argument("file", help="File path")
    def_parser.add_argument("line", type=int, help="Line number (1-indexed)")
    def_parser.add_argument("col", type=int, help="Column number (1-indexed)")

    # hover subcommand
    hover_parser = subparsers.add_parser("hover", help="Get hover info")
    hover_parser.add_argument("file", help="File path")
    hover_parser.add_argument("line", type=int, help="Line number (1-indexed)")
    hover_parser.add_argument("col", type=int, help="Column number (1-indexed)")

    # references subcommand
    ref_parser = subparsers.add_parser("references", help="Find references")
    ref_parser.add_argument("file", help="File path")
    ref_parser.add_argument("line", type=int, help="Line number (1-indexed)")
    ref_parser.add_argument("col", type=int, help="Column number (1-indexed)")

    # expand subcommand
    expand_parser = subparsers.add_parser("expand", help="Expand macro at position or in file")
    expand_parser.add_argument("file", help="File path")
    expand_parser.add_argument("line", type=int, nargs="?", default=None, help="Line number (1-indexed, optional)")
    expand_parser.add_argument("col", type=int, nargs="?", default=None, help="Column number (1-indexed, optional)")

    args = parser.parse_args()

    client = LSPClient(root_dir=args.dir)
    try:
        if args.subcommand == "symbol":
            res = client.query_workspace_symbols(args.query)
        elif args.subcommand == "definition":
            res = client.query_definition(args.file, args.line, args.col)
        elif args.subcommand == "hover":
            res = client.query_hover(args.file, args.line, args.col)
        elif args.subcommand == "references":
            res = client.query_references(args.file, args.line, args.col)
        elif args.subcommand == "expand":
            res = client.query_expand(args.file, args.line, args.col)
        else:
            res = None
        print(json.dumps(res, indent=2))
    finally:
        client.close()

if __name__ == "__main__":
    main()
