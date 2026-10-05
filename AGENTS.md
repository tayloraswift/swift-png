<!-- ❣❣❣  DO NOT EDIT  ❣  THIS FILE IS AUTOMATICALLY SYNCED  ❣  DO NOT EDIT  ❣❣❣ -->
## Swift coding style and conventions

Please familiarize yourself with, and adhere to, our [institutional Swift style guide](https://raw.githubusercontent.com/tayloraswift/dollup/master/Agent/Swift.md) ([web link for humans](https://github.com/tayloraswift/dollup/blob/master/Agent/Swift.md)).

Read the markdown content directly using your URL reader tool, or check if `/tmp/swift_style_guide.md` exists. If not cached, fetch and save it locally to `/tmp/swift_style_guide.md`.


## Swift symbol resolution and `sourcekit-lsp`

Avoid grepping for identifiers when working on Swift code, it is error-prone and not recommended when working in a language that uses extensive overloading. Instead, build the project (to obtain the build index) and leverage sourcekit-lsp.

To perform semantic symbol lookup, go-to-definition, hover type resolution, reference searching, or macro expansion across the Swift codebase, use the included [`lsp_query.py`](.github/tools/lsp_query.py) script:

### Using `lsp_query.py`

#### Search workspace symbols

```bash
.github/tools/lsp_query.py symbol <SymbolName>
```

#### Go to definition

```bash
.github/tools/lsp_query.py definition <path/to/file.swift> <line> <column>
```

#### Hover / type documentation

```bash
.github/tools/lsp_query.py hover <path/to/file.swift> <line> <column>
```

#### Find references

```bash
.github/tools/lsp_query.py references <path/to/file.swift> <line> <column>
```

#### Expand macro

```bash
.github/tools/lsp_query.py expand <path/to/file.swift> [<line> <column>]
```

If you do choose to use `grep` (for example, when searching for strings that are not Swift symbols), make sure to exclude build directories (such as `.build`, `.build.wasm`, etc.) and package caches (such as `node_modules`) as `grep` traversal through these can be very slow. Alternatively, use `git grep` to only search through tracked files.


## English writing style

When producing summaries, design docs, or any other English prose, use Wikipedia-style sentence casing, including in headings. The first letter in a sentence is capitalized, unless it begins a word which is always left uncapitalized (as in “eBay”).

Always use unicode curly quotes (`“”`, `‘’`) when writing English prose, including code comments.

### Commit messages

Commit messages should be brief, uncapitalized sentences or sentence fragments, and should not end with a period. Do not prefix commit messages with emoji or prepend “structured” labels such as `fix:`, `feature:`, `modernize:`, et cetera.

### Long-form prose

If you are writing long-form prose (such as tutorials, articles, and design docs), please consult and follow our [English style guide](https://raw.githubusercontent.com/tayloraswift/dollup/master/Agent/English.md) ([web link for humans](https://github.com/tayloraswift/dollup/blob/master/Agent/English.md)). As with the Swift style guide, you should cache it locally to `/tmp/english_style_guide.md`.


## Repository-specific instructions

Before working in this repository, read `CONTRIBUTORS.md` if it exists. If present, this file will contain repository-specific guidance that supplements these global instructions.
