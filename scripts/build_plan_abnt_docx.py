from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION

from build_abnt_docx import (
    add_cover,
    add_page_number,
    build_body,
    clean_text,
    configure_section,
    configure_styles,
    restart_page_numbering,
)


ROOT = Path(r"C:\Projeto Leitor de cod de barras")
SOURCE = ROOT / "docs" / "superpowers" / "plans" / "2026-03-23-v1-plan.md"
TARGET = ROOT / "docs" / "superpowers" / "plans" / "2026-03-23-v1-plan-abnt.docx"


def main() -> None:
    source_text = SOURCE.read_text(encoding="utf-8")
    lines = source_text.splitlines()
    title = clean_text(lines[0].removeprefix("# ").strip())

    date_text = "23 de março de 2026"
    status_text = "Plano de implementação"

    document = Document()
    configure_styles(document)
    configure_section(document.sections[0])

    add_cover(document, title, date_text, status_text)

    body_section = document.add_section(WD_SECTION.NEW_PAGE)
    configure_section(body_section)
    body_section.header.is_linked_to_previous = False
    restart_page_numbering(body_section, start=1)
    add_page_number(body_section.header.paragraphs[0])

    build_body(document, lines[1:])

    TARGET.parent.mkdir(parents=True, exist_ok=True)
    document.save(TARGET)
    print(TARGET)


if __name__ == "__main__":
    main()
