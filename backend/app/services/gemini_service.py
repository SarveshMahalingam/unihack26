import os
from google import genai
from dotenv import load_dotenv

load_dotenv()
client = genai.Client(api_key=os.getenv("GEM_API"))

def analyze_product(ingredients: str, user_profile: str) -> str:
    prompt = f"""
    You are an expert health and dietary analyzer. 
    Review these ingredients: {ingredients}
    Against this exact user profile: {user_profile}

    Return ONLY a raw JSON object (no markdown, no backticks) matching this structure:
    {{
        "health_match": false,
        "health_status": "Allergen Alert",
        "flagged_ingredients": ["Peanut Oil", "Whey Protein"]
    }}
    
    Rules:
    1. "health_match" MUST be false if ANY ingredient violates an allergy, dislike, or dietary goal.
    2. "flagged_ingredients" MUST be an array of the ingredients from the list that caused the violation. Leave empty if totally safe.Keep the word limit as minimal as possible
    """
    
    response = client.models.generate_content(
        model='gemini-2.5-flash',
        contents=prompt,
    )
    
    return response.text.replace("⁠ json", "").replace(" ⁠", "").strip()
