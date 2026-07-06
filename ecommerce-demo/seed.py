import csv
import os
from sqlalchemy.orm import Session
from models import Item


def seed_items(db: Session):
    if db.query(Item).count() > 0:
        return

    csv_path = os.path.join(os.path.dirname(__file__), "items.csv")
    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            # tags are all remaining columns after price
            item = Item(
                name=row["name"],
                description=row["description"],
                price=float(row["price"]),
                category=row.get("category", "General"),
                tags=row.get("tags", ""),
                semantic_description=row.get("semantic_description", ""),
            )
            db.add(item)
    db.commit()
