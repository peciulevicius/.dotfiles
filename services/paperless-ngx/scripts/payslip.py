# Payslip clean-up, run by post-consume.sh inside the Paperless container (via
# `manage.py shell`, so the Django ORM is available). For a Visma
# "Atsiskaitymų lapelis <year> <month>" payslip: title = "<Month> <year>" taken
# from the payslip text (the document date is the issue date, i.e. the next
# month), document type "Payslip", storage path "Payslips" (one folder), and no
# tags or correspondent. Without DOCUMENT_ID it re-processes every payslip.
import os
import re

from documents.models import Document, DocumentType, StoragePath

MONTHS = {"sausis": 1, "vasaris": 2, "kovas": 3, "balandis": 4, "gegužė": 5, "birželis": 6,
          "liepa": 7, "rugpjūtis": 8, "rugsėjis": 9, "spalis": 10, "lapkritis": 11, "gruodis": 12}
NAMES = ["January", "February", "March", "April", "May", "June", "July", "August",
         "September", "October", "November", "December"]
PATTERN = re.compile(r"Atsiskaitym\w*\s+lapelis\s+(\d{4})\s+(\w+)", re.IGNORECASE)


def fix(doc):
    match = PATTERN.search(doc.content or "")
    month = MONTHS.get(match.group(2).lower()) if match else None
    if not month:
        return False
    doc_type, _ = DocumentType.objects.get_or_create(name="Payslip", defaults={"matching_algorithm": 0})
    path, _ = StoragePath.objects.get_or_create(
        name="Payslips", defaults={"path": "Payslips/{{ title }}", "matching_algorithm": 0})
    doc.title = f"{NAMES[month - 1]} {match.group(1)}"
    doc.document_type = doc_type
    doc.storage_path = path
    doc.correspondent = None
    doc.save()  # Paperless moves the file to the new storage path on save
    doc.tags.clear()
    print(f"payslip {doc.id} -> {doc.title}")
    return True


ids = [os.environ["DOCUMENT_ID"]] if os.environ.get("DOCUMENT_ID") else \
    Document.objects.filter(content__icontains="lapelis").values_list("id", flat=True)
for document_id in ids:
    fix(Document.objects.get(id=document_id))
