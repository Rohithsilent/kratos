import asyncio
from google import genai
from google.genai import types
from app.core.config import settings

client = genai.Client(api_key=settings.GEMINI_API_KEY)

def create_workout(name: str, exercises: list[str]) -> str:
    """Creates a workout routine for the user. Call this if the user asks for a workout."""
    return f"Created {name} with {len(exercises)} exercises"

async def main():
    model = settings.GEMINI_FLASH_MODEL
    config = types.GenerateContentConfig(
        tools=[create_workout],
        temperature=0.0
    )
    response = client.models.generate_content(
        model=model,
        contents="Please create a chest workout for me.",
        config=config,
    )
    print("Response:", response.text)
    if response.function_calls:
        print("Function Calls:", [fc.name for fc in response.function_calls])

if __name__ == "__main__":
    asyncio.run(main())
