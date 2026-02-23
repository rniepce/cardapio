from __future__ import annotations

import os
import uuid
from datetime import date
from contextlib import asynccontextmanager
from typing import Optional, List

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session, sessionmaker

from models import Base, Recipe as RecipeDB, MealEntry as MealEntryDB, DailyMenu as DailyMenuDB

# ---------------------------------------------------------------------------
# Database setup
# ---------------------------------------------------------------------------

DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///./cardapio.db")
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, pool_pre_ping=True, connect_args=connect_args)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


# ---------------------------------------------------------------------------
# Pydantic schemas
# ---------------------------------------------------------------------------

class RecipeOut(BaseModel):
    id: uuid.UUID
    title: str
    prep_time: str
    tags: List[str]
    image_url: Optional[str] = None
    url: Optional[str] = None
    target_meals: List[str]

    class Config:
        from_attributes = True


class RecipeCreate(BaseModel):
    title: str
    prep_time: str = "15 min"
    tags: List[str] = []
    image_url: Optional[str] = None
    url: Optional[str] = None
    target_meals: List[str] = []


class MealEntryOut(BaseModel):
    id: uuid.UUID
    type_raw_value: str
    recipe: Optional[RecipeOut] = None

    class Config:
        from_attributes = True


class DailyMenuOut(BaseModel):
    id: uuid.UUID
    date: date
    meals: List[MealEntryOut]

    class Config:
        from_attributes = True


class AssignRecipeBody(BaseModel):
    recipe_id: uuid.UUID


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

app = FastAPI(title="Cardápio API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

MEAL_TYPES_ORDERED = ["Café da Manhã", "Almoço", "Jantar"]


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.get("/")
def health():
    return {"status": "ok", "service": "cardapio-api"}


@app.get("/menus/{menu_date}", response_model=DailyMenuOut)
def get_menu(menu_date: date, db: Session = Depends(get_db)):
    """Get the menu for a specific date. Creates one automatically if it doesn't exist."""
    menu = db.execute(
        select(DailyMenuDB).where(DailyMenuDB.date == menu_date)
    ).unique().scalar_one_or_none()

    if menu is None:
        menu = DailyMenuDB(date=menu_date)
        for meal_type in MEAL_TYPES_ORDERED:
            menu.meals.append(MealEntryDB(type_raw_value=meal_type))
        db.add(menu)
        db.commit()
        db.refresh(menu)

    return menu


@app.put("/meals/{meal_id}/recipe", response_model=MealEntryOut)
def assign_recipe(meal_id: uuid.UUID, body: AssignRecipeBody, db: Session = Depends(get_db)):
    """Assign a recipe to a meal entry."""
    meal = db.get(MealEntryDB, meal_id)
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")

    recipe = db.get(RecipeDB, body.recipe_id)
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    # Learn meal type preference
    if meal.type_raw_value not in recipe.target_meals:
        recipe.target_meals = [*recipe.target_meals, meal.type_raw_value]

    meal.recipe_id = recipe.id
    db.commit()
    db.refresh(meal)
    return meal


@app.delete("/meals/{meal_id}/recipe", response_model=MealEntryOut)
def remove_recipe(meal_id: uuid.UUID, db: Session = Depends(get_db)):
    """Remove the recipe from a meal entry."""
    meal = db.get(MealEntryDB, meal_id)
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")

    meal.recipe_id = None
    meal.recipe = None
    db.commit()
    db.refresh(meal)
    return meal


@app.get("/recipes", response_model=List[RecipeOut])
def list_recipes(db: Session = Depends(get_db)):
    """List all saved recipes."""
    recipes = db.execute(select(RecipeDB).order_by(RecipeDB.title)).scalars().all()
    return recipes


@app.post("/recipes", response_model=RecipeOut, status_code=201)
def create_recipe(body: RecipeCreate, db: Session = Depends(get_db)):
    """Create a new recipe."""
    recipe = RecipeDB(
        title=body.title.strip(),
        prep_time=body.prep_time,
        tags=body.tags,
        image_url=body.image_url,
        url=body.url,
        target_meals=body.target_meals,
    )
    db.add(recipe)
    db.commit()
    db.refresh(recipe)
    return recipe


@app.delete("/recipes/{recipe_id}", status_code=204)
def delete_recipe(recipe_id: uuid.UUID, db: Session = Depends(get_db)):
    """Delete a recipe."""
    recipe = db.get(RecipeDB, recipe_id)
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    # Unlink from any meals first
    meals_with_recipe = db.execute(
        select(MealEntryDB).where(MealEntryDB.recipe_id == recipe_id)
    ).scalars().all()
    for meal in meals_with_recipe:
        meal.recipe_id = None

    db.delete(recipe)
    db.commit()
