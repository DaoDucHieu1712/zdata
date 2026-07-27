from pydantic import BaseModel
from typing import List, Optional
from enum import Enum


class Gender(str, Enum):
    male = "Nam"
    female = "Nữ"


class GoalType(str, Enum):
    muscle_cut = "Tăng cơ giảm mỡ"
    bulk = "Tăng cân"
    cut = "Giảm cân"


class ActivityLevel(str, Enum):
    sedentary = "Ít vận động"
    light = "Vận động nhẹ 1-3 ngày/tuần"
    moderate = "Vận động vừa 3-5 ngày/tuần"
    active = "Vận động nhiều 6-7 ngày/tuần"


class UserInput(BaseModel):
    gender: Gender
    age: int
    weight_kg: float
    height_cm: float
    goal_type: GoalType
    activity_level: ActivityLevel
    current_weight_kg: float
    target_weight_kg: float
    notes: Optional[str] = ""


class Exercise(BaseModel):
    name: str
    sets: int
    reps: str
    rest: str
    instructions: str
    notes: str


class DayWorkout(BaseModel):
    day: str
    focus: str
    exercises: List[Exercise]


class Meal(BaseModel):
    meal: str
    foods: List[str]
    calories: int
    protein_g: int


class DayMeals(BaseModel):
    day: str
    meals: List[Meal]


class WorkoutPlan(BaseModel):
    bmi: float
    tdee: int
    daily_calories: int
    protein_g: int
    carbs_g: int
    fat_g: int
    summary: str
    workout_plan: List[DayWorkout]
    rest_days: List[str]
    meal_plan: List[DayMeals]
    tips: List[str]
