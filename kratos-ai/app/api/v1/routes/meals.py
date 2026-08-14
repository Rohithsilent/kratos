from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.database.models.meal_entry import MealEntryModel
from app.schemas.nutrition import MealEntryCreate, MealEntryResponse

router = APIRouter(prefix="/meals", tags=["meals"])


@router.get("/{firebase_uid}", response_model=List[MealEntryResponse])
async def get_meals(
    firebase_uid: str,
    date: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
):
    """Get meal history for a user, with optional date filtering."""
    query = select(MealEntryModel).where(MealEntryModel.firebase_uid == firebase_uid)

    if date:
        query = query.where(MealEntryModel.date == date)
    elif start_date and end_date:
        query = query.where(
            MealEntryModel.date >= start_date,
            MealEntryModel.date <= end_date,
        )
    
    if not date:
        query = query.order_by(MealEntryModel.logged_at.desc())

    result = await db.execute(query)
    meals = result.scalars().all()
    return meals


@router.post("/{firebase_uid}", response_model=MealEntryResponse, status_code=status.HTTP_201_CREATED)
async def log_meal(
    firebase_uid: str,
    meal: MealEntryCreate,
    db: AsyncSession = Depends(get_db),
):
    """Log a new meal or update an existing one (using its provided ID)."""
    # Check if meal with this ID already exists
    existing = await db.get(MealEntryModel, meal.id)
    if existing:
        # Update existing
        for key, value in meal.model_dump(by_alias=True).items():
            if hasattr(existing, key) and key != "id":
                setattr(existing, key, value)
        await db.commit()
        await db.refresh(existing)
        return existing
        
    # Create new
    db_meal = MealEntryModel(
        id=meal.id,
        firebase_uid=firebase_uid,
        date=meal.date,
        food_name=meal.food_name,
        calories=meal.calories,
        protein=meal.protein,
        carbs=meal.carbs,
        fats=meal.fats,
        meal_type=meal.meal_type,
        logged_at=meal.logged_at,
        source=meal.source,
        serving_size=meal.serving_size,
    )
    db.add(db_meal)
    await db.commit()
    await db.refresh(db_meal)
    return db_meal


@router.delete("/{firebase_uid}/{meal_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_meal(
    firebase_uid: str,
    meal_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Delete a logged meal."""
    meal = await db.get(MealEntryModel, meal_id)
    if not meal or meal.firebase_uid != firebase_uid:
        raise HTTPException(status_code=404, detail="Meal not found")
        
    await db.delete(meal)
    await db.commit()
