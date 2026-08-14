from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class MealEntryBase(BaseModel):
    date: str = Field(..., description="Date of the meal (YYYY-MM-DD)")
    food_name: str = Field(..., alias="foodName")
    calories: float
    protein: float
    carbs: float
    fats: float
    meal_type: str = Field(..., alias="mealType")
    logged_at: datetime = Field(..., alias="loggedAt")
    source: str = "manual"
    serving_size: Optional[float] = Field(None, alias="servingSize")
    
    model_config = ConfigDict(
        populate_by_name=True,
    )


class MealEntryCreate(MealEntryBase):
    id: str


class MealEntryResponse(MealEntryBase):
    id: str

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
    )
