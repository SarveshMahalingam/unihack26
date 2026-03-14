import os
from google import genai


from dotenv import load_dotenv

load_dotenv()

# Initialize the new SDK client

client = genai.Client(api_key=os.getenv("GEM_API"))

# def analyze_food(product_data, user_profile):
#     prompt = f"""
#     Analyze product: {product_data.get('product_name', 'Unknown')}
#     Ingredients: {product_data.get('ingredients_text', 'N/A')}
#     User Allergies: {user_profile['allergies']}
#     User Dislikes: {user_profile['dislikes']}
#     User Goals: {user_profile['goals']}

#     Return a JSON response with:
#     - nutri_score (A-E)
#     - ethical_score (1-10)
#     - status (safe, warning, danger)
#     - alerts (list of strings: MUST be extremely concise. strictly use the format "Contains [item]" or "High in [item]". Example: "Contains peanuts", "High in sugar")
#     - summary (2 sentences)
#     - alternatives(2 safe alternatives and their brand names)
#     """
    
#     # New generation syntax
#     response = client.models.generate_content(
#         model='gemini-2.5-flash',
#         contents=prompt
#     )
#     return response.text

def analyze_product(product_info: str, user_profile: str) -> str:
    prompt = f"""
    You are an expert health and ethical food analyzer. 
    Analyze this product: {product_info}
    Against these specific user preferences: {user_profile}

    You MUST return ONLY a raw JSON object (no markdown, no backticks, no code blocks) matching EXACTLY this structure:
    {{
        "product_name": "Product Name",
        "brand": "Brand Name",
        "ethics_score": 42,
        "ethics_status": "Poor", 
        "health_match": false,
        "health_status": "Allergen Alert",
        "key_findings": [
            {{
                "type": "danger", 
                "title": "Health Alert", 
                "description": "Contains [Ingredient] which conflicts with your profile."
            }}
        ],
        "alternatives": [
            {{"name": "Safe Alternative 1", "brand": "Good Brand"}},
            {{"name": "Safe Alternative 2", "brand": "Better Brand"}}
        ]
    }}
    
    Rules:
    1. If the product violates ANY of the user's allergies or diets, "health_match" MUST be false and "health_status" must be "Allergen Alert" or "Diet Violation".
    2. Make the "type" in key_findings either "danger", "warning", or "success".
    """
    
    # Call the model using the new SDK syntax
    response = client.models.generate_content(
        model='gemini-2.5-flash',
        contents=prompt,
    )
    
    # Strip any accidental markdown formatting the AI tries to sneak in
    clean_json = response.text.replace("```json", "").replace("```", "").strip()
    
    return clean_json