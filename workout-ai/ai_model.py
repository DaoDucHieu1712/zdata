import ollama
import json
from schemas import UserInput, WorkoutPlan

MODEL = "llama3.2:3b"


def build_prompt(user: UserInput) -> str:
    bmi = user.weight_kg / ((user.height_cm / 100) ** 2)
    return f"""You are an expert fitness coach and nutritionist.
Generate a weekly workout and meal plan for this user.
Respond ONLY in valid JSON, no markdown, no explanation, no extra text.

User profile:
- Gender: {user.gender}
- Age: {user.age} years old
- Weight: {user.weight_kg}kg | Height: {user.height_cm}cm | BMI: {bmi:.1f}
- Goal: {user.goal_type}
- Activity level: {user.activity_level}
- Current weight → Target weight: {user.current_weight_kg}kg → {user.target_weight_kg}kg
- Notes: {user.notes or "None"}

Return ONLY this JSON structure, nothing else:
{{
  "bmi": 22.5,
  "tdee": 2200,
  "daily_calories": 1800,
  "protein_g": 150,
  "carbs_g": 180,
  "fat_g": 60,
  "summary": "2-3 câu tóm tắt cá nhân hóa bằng tiếng Việt",
  "workout_plan": [
    {{
      "day": "Thứ 2",
      "focus": "Ngực + Vai",
      "exercises": [
        {{
          "name": "Bench Press",
          "sets": 4,
          "reps": "8-10",
          "rest": "90 giây",
          "instructions": "Hướng dẫn chi tiết bằng tiếng Việt",
          "notes": "Lưu ý quan trọng khi tập"
        }}
      ]
    }}
  ],
  "rest_days": ["Thứ 4", "Chủ nhật"],
  "meal_plan": [
    {{
      "day": "Ngày tập (Thứ 2, 3, 5, 6, 7)",
      "meals": [
        {{
          "meal": "Bữa sáng 7:00",
          "foods": ["3 quả trứng luộc", "2 lát bánh mì nguyên cám", "1 quả chuối"],
          "calories": 450,
          "protein_g": 25
        }}
      ]
    }}
  ],
  "tips": ["tip 1", "tip 2", "tip 3", "tip 4", "tip 5"]
}}

Rules:
- workout_plan must cover all training days (not rest days), minimum 4 exercises per day
- Each exercise must have detailed Vietnamese instructions, not generic
- No junk food, no fast food in meal plan
- All meals must be realistic and commonly available in Vietnam
- Calories and macros must match user goal and TDEE
- Return ONLY the JSON object, absolutely nothing else
"""


async def generate_plan(user: UserInput) -> WorkoutPlan:
    prompt = build_prompt(user)

    for attempt in range(2):
        response = ollama.chat(
            model=MODEL,
            messages=[{"role": "user", "content": prompt}],
            options={
                "temperature": 0.3,
                "num_predict": 4000,
            },
        )

        raw = response["message"]["content"]
        print(f"[Attempt {attempt+1}] Raw:\n{raw[:300]}...")

        try:
            data = json.loads(raw)
            return WorkoutPlan(**data)
        except (json.JSONDecodeError, Exception):
            start = raw.find("{")
            end = raw.rfind("}") + 1
            if start != -1 and end > 0:
                try:
                    data = json.loads(raw[start:end])
                    return WorkoutPlan(**data)
                except Exception:
                    pass
            if attempt == 0:
                continue

    raise ValueError("Failed to generate valid plan after 2 attempts")
