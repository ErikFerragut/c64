# Documentation Structure

## Directory Layout

```
asm_tutorial/
├── README.md          # This file
├── LOG.md             # Development log
├── TOOLS.md           # Tool reference
├── src/               # Source files
│   ├── 00-TOC.md
│   ├── 01-INSTALL.md
│   ├── ...
│   ├── A-REF.md
│   └── images/
└── out/               # Generated output
    ├── c64-tutorial.html
    ├── c64-tutorial.epub
    └── c64-tutorial.pdf
```

## File Naming Conventions

- **Chapters**: `XX-name.md` (e.g., `01-INSTALL.md`, `02-HELLO.md`)
- **Appendices**: `[A-Z]-name.md` (e.g., `A-REF.md`, `B-VIC-II.md`)
- **Images**: `src/images/` directory

## Building the Book

Requires pandoc (`sudo apt install pandoc`).

### HTML (recommended)

```bash
cd ~/c64/asm_tutorial/src
pandoc -s 00-TOC.md 01-INSTALL.md 02-HELLO.md A-REF.md B-VIC-II.md \
  -o ../out/c64-tutorial.html \
  --toc \
  --metadata title="C64 Assembly Tutorial"
```

### EPUB (e-reader)

```bash
cd ~/c64/asm_tutorial/src
pandoc -s 00-TOC.md 01-INSTALL.md 02-HELLO.md A-REF.md B-VIC-II.md \
  -o ../out/c64-tutorial.epub \
  --metadata title="C64 Assembly Tutorial"
```

### PDF

Requires xelatex for Unicode support (`sudo apt install texlive-xetex`).

```bash
cd ~/c64/asm_tutorial/src
pandoc -s 00-TOC.md 01-INSTALL.md 02-HELLO.md A-REF.md B-VIC-II.md \
  -o ../out/c64-tutorial.pdf \
  --pdf-engine=xelatex \
  --metadata title="C64 Assembly Tutorial" \
  -V monofont="DejaVu Sans Mono"
```

The `-V monofont` flag sets a monospace font that includes box-drawing characters for tree diagrams.
