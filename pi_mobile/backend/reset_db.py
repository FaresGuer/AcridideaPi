"""
Drop and recreate all tables.
Use this to fix schema issues.
"""
from database import Base, engine

# Drop all tables
Base.metadata.drop_all(bind=engine)
print("✓ Dropped all tables")

# Recreate tables
Base.metadata.create_all(bind=engine)
print("✓ Recreated all tables with correct schema")
