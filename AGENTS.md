<!-- ❣❣❣  DO NOT EDIT  ❣  THIS FILE IS AUTOMATICALLY SYNCED  ❣  DO NOT EDIT  ❣❣❣ -->
## English writing style

When producing summaries, design docs, or any other English prose, use Wikipedia-style sentence casing, including in headings. The first letter in a sentence is capitalized, except if it begins a word which is always left uncapitalized (as in “eBay”).

Always use unicode curly quotes (`“”`, `‘’`) when writing English prose, including code comments.


## Swift coding style and conventions

Please familiarize yourself with, and adhere to, our [institutional Swift style guide](https://raw.githubusercontent.com/tayloraswift/dollup/master/Agent/Swift.md).

Read the markdown content directly using your URL reader tool, or check if `/tmp/swift_style_guide.md` exists. If not cached, fetch and save it locally to `/tmp/swift_style_guide.md`.


## Swift symbol resolution and `sourcekit-lsp`

To perform semantic symbol lookup, go-to-definition, hover type resolution, or reference searching across the Swift codebase, use the included [`lsp_query.py`](.github/tools/lsp_query.py) script:

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
