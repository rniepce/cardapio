from __future__ import annotations

import uuid
from datetime import date
from typing import Optional, List

from sqlalchemy import Column, String, Date, ForeignKey, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class Recipe(Base):
    __tablename__ = "recipes"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title: Mapped[str] = mapped_column(String, nullable=False)
    prep_time: Mapped[str] = mapped_column(String, default="15 min")
    tags = mapped_column(JSON, default=list)
    image_url: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    url: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    target_meals = mapped_column(JSON, default=list)


class MealEntry(Base):
    __tablename__ = "meal_entries"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    type_raw_value: Mapped[str] = mapped_column(String, nullable=False)
    recipe_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True), ForeignKey("recipes.id", ondelete="SET NULL"), nullable=True)
    menu_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("daily_menus.id", ondelete="CASCADE"), nullable=False)

    recipe: Mapped[Optional[Recipe]] = relationship("Recipe", lazy="joined")


class DailyMenu(Base):
    __tablename__ = "daily_menus"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    date: Mapped[date] = mapped_column(Date, unique=True, nullable=False)

    meals: Mapped[List[MealEntry]] = relationship(
        "MealEntry", cascade="all, delete-orphan", lazy="joined",
        order_by="MealEntry.type_raw_value"
    )
