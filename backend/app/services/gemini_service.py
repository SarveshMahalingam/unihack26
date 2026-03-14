import os
from google import genai
from dotenv import load_dotenv

load_dotenv()

# Initialize the new SDK client

client = genai.Client(api_key=os.getenv("GEM_API"))

def analyze_food(product_data, user_profile):
    prompt = f"""
    Analyze product: {product_data.get('product_name', 'Unknown')}
    Ingredients: {product_data.get('ingredients_text', 'N/A')}
    User Allergies: {user_profile['allergies']}
    User Dislikes: {user_profile['dislikes']}
    User Goals: {user_profile['goals']}

    Return a JSON response with:
    - nutri_score (A-E)
    - ethical_score (1-10)
    - status (safe, warning, danger)
    - alerts (list of strings: MUST be extremely concise. strictly use the format "Contains [item]" or "High in [item]". Example: "Contains peanuts", "High in sugar")
    - summary (2 sentences)
    """
    
    # New generation syntax
    response = client.models.generate_content(
        model='gemini-2.5-flash',
        contents=prompt
    )
    return response.text