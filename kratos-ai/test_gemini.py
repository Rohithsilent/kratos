import os
os.environ["GEMINI_API_KEY"] = "AQ.Ab8RN6Jwp5cT1u2x9F49QrZto-nEmarZ7Pss2iSmrFNNgdEfhA"
from google import genai
from pydantic import BaseModel
class Test(BaseModel):
    hello: str
client = genai.Client()
interaction = client.interactions.create(
    model="gemini-3.6-flash",
    input="Say hello world",
    response_format=Test
)
print(interaction.output_text)
