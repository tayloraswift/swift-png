#  ❣❣❣  DO NOT EDIT  ❣  THIS FILE IS AUTOMATICALLY SYNCED  ❣  DO NOT EDIT  ❣❣❣
#!/usr/bin/env python3
"""
SourceKit-LSP Helper Script for Swift Symbol Resolution.
Provides CLI access to workspace symbols, definitions, hover type info, and references.
"""

import sys
import os
import json
import subprocess
import shutil
import argparse
from typing import Dict, Any, Optional

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
                    "workspace": {"symbol": {"dynamicRegistration": False}},
                    "textDocument": {
                        "definition": {"dynamicRegistration": False},
                        "references": {"dynamicRegistration": False},
                        "hover": {"dynamicRegistration": False},
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
    parser = argparse.ArgumentParser(description="Query sourcekit-lsp for Swift symbols")
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
        else:
            res = None
        print(json.dumps(res, indent=2))
    finally:
        client.close()

if __name__ == "__main__":
    main()
