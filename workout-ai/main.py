from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from schemas import UserInput, WorkoutPlan
from ai_model import generate_plan
from excel_export import generate_excel

app = FastAPI(title="AI Workout Planner")


@app.get("/health")
def health():
    return {"status": "ok", "model": "llama3.2:3b (local)"}


@app.post("/generate", response_model=WorkoutPlan)
async def generate_json(user: UserInput):
    try:
        return await generate_plan(user)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/generate/excel")
async def generate_excel_file(user: UserInput):
    try:
        plan = await generate_plan(user)
        buffer = generate_excel(plan, user)
        return StreamingResponse(
            buffer,
            media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            headers={"Content-Disposition": "attachment; filename=workout_plan.xlsx"},
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
