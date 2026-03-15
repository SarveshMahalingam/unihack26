import os
import json
import math
import concurrent.futures
from dotenv import load_dotenv
from gnews import GNews
from google import genai
from google.genai import types

# 1. Load the variables from the .env file
load_dotenv()

# 2. Safely grab the key from the environment
GEMINI_API_KEY = os.getenv("GEM_API")

if not GEMINI_API_KEY:
    raise ValueError("🚨 GEMINI_API_KEY is missing! Check your .env file.")

# 3. Initialize the SDK
client = genai.Client(api_key=GEMINI_API_KEY)

class GeminiParallelAuditor:
    def __init__(self, period='1y', max_results=30):
        self.gn = GNews(language='en', period=period, max_results=max_results)
        self.pillars = {
            "Environment": "(pollution OR emissions OR deforestation OR 'plastic waste' OR greenwashing OR sustainability OR award)",
            "Social": "(labor OR 'human rights' OR wages OR strike OR diversity OR community OR safety OR contamination)",
            "Governance": "(lawsuit OR fine OR corruption OR ethics OR transparency OR probe OR investigation)"
        }

    def resolve_entity(self, brand_name):
        if not brand_name or brand_name.lower() == "unknown":
            return "Unknown Company"

        prompt = f"""
        You are a Corporate Entity Resolution Engine. 
        A user scanned a product with the brand name '{brand_name}'. 
        Identify the ultimate parent corporation that owns this brand. 
        RULES:
        1. If owned by a larger conglomerate (e.g., 'Sprite' -> 'Coca-Cola', 'Ben & Jerry's' -> 'Unilever'), return ONLY the parent corporation name.
        2. If independent or unknown, return the original brand name.
        3. Return ONLY the company name, no punctuation.
        """
        try:
            response = client.models.generate_content(
                model='gemini-2.5-flash',
                contents=prompt,
                config=types.GenerateContentConfig(temperature=0.0)
            )
            return response.text.strip()
        except Exception:
            return brand_name

    def _process_single_pillar(self, company, pillar, query):
        search_query = f"\"{company}\" (brand OR company OR corporation) {query} -stock -shares"
        raw_results = self.gn.get_news(search_query)
        
        # Deduplicate
        unique = {}
        for art in raw_results:
            title_key = art['title'].lower().strip()
            if title_key not in unique:
                unique[title_key] = art
        articles = list(unique.values())
        
        if not articles:
            return pillar, {
                "score": 100, 
                "reasoning": f"No significant recent {pillar.lower()} controversies found.", 
                "key_events_spotted": []
            }

        news_text = "\n".join([f"- [{a['published date']}] {a['title']}" for a in articles])

        prompt = f"""
        You are a Consumer Ethics and ESG Risk Assessor evaluating {company}'s news over the past year specifically for the '{pillar}' pillar.
        Start with a baseline score of 100. 

        RULE 1: THE MATERIALITY FILTER
        Do NOT deduct points for standard corporate noise that does not harm society, the planet, or consumers. 
        IGNORE: Internal C-suite drama, stock market fluctuations, or harmless restructuring.

        RULE 2: EVENT CONSOLIDATION
        If multiple articles talk about the exact same event, only deduct points ONCE for that event.

        RULE 3: CONSUMER-CENTRIC DEDUCTION TIERS
        - CRITICAL HARM (-30 to -40 points): Deaths, forced/child labor, severe environmental destruction, massive fraud, or dangerous product contamination.
        - MODERATE HARM (-15 to -20 points): Verified employee strikes, significant fines, discriminatory practices, or moderate pollution.
        - MINOR HARM (-5 to -10 points): Minor consumer complaints, small fines, or unproven allegations.

        ADDITIONS: 
        - Add +5 to +15 points for proactive positive impacts (e.g., net-zero milestones, resolved lawsuits, verified awards). Max score is 100.

        Here is the 1-Year historical record for {pillar}:
        {news_text}

        Respond ONLY with a valid JSON object matching this EXACT schema:
        {{
            "score": [integer 0-100],
            "reasoning": "[2-3 sentences explaining exact events penalized or rewarded]",
            "key_events_spotted": ["[Event 1]", "[Event 2]"]
        }}
        """
        try:
            response = client.models.generate_content(
                model='gemini-2.5-flash',
                contents=prompt,
                config=types.GenerateContentConfig(response_mime_type="application/json", temperature=0.1)
            )
            return pillar, json.loads(response.text)
        except Exception:
            return pillar, {"score": 50, "reasoning": "Error analyzing news data.", "key_events_spotted": []}

    # --- NEW: The Synthesis Engine ---
    def _generate_overall_summary(self, company, overall_score, report_data):
        env_reasoning = report_data["Environment"].get("reasoning", "No data.")
        soc_reasoning = report_data["Social"].get("reasoning", "No data.")
        gov_reasoning = report_data["Governance"].get("reasoning", "No data.")

        prompt = f"""
        You are an Executive ESG Analyst summarizing a 1-year corporate audit of {company}.
        The company received a final ethical rating of {overall_score}/10.

        Here are the detailed findings from the three pillars:
        - Environment: {env_reasoning}
        - Social: {soc_reasoning}
        - Governance: {gov_reasoning}

        Write a concise, 2-to-3 sentence overarching summary synthesizing their ethical standing. 
        Mention the specific major controversies or positive initiatives that drove their score.
        Be objective, professional, and direct. Do not use generic filler words.
        """
        try:
            response = client.models.generate_content(
                model='gemini-2.5-flash',
                contents=prompt,
                config=types.GenerateContentConfig(temperature=0.3)
            )
            return response.text.strip()
        except Exception:
            return f"{company} received an overall score of {overall_score}/10. Review individual pillars for details."

    def run_audit(self, target_brand):
        parent_company = self.resolve_entity(target_brand)
        
        if parent_company == "Unknown Company":
            return {
                "parent_company": "Unknown",
                "environment_score": 0, "environment_summary": "Brand not identified.",
                "social_score": 0, "social_summary": "Brand not identified.",
                "governance_score": 0, "governance_summary": "Brand not identified.",
                "overall_score": 0, "overall_summary": "Could not identify the brand from the barcode."
            }

        report_data = {}
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
            futures = [executor.submit(self._process_single_pillar, parent_company, p, q) for p, q in self.pillars.items()]
            for future in concurrent.futures.as_completed(futures):
                pillar_name, ai_data = future.result()
                report_data[pillar_name] = ai_data

        # Math & Aggregation (using the 100-point scale for weakest link math)
        env_score_100 = report_data["Environment"].get("score", 100)
        soc_score_100 = report_data["Social"].get("score", 100)
        gov_score_100 = report_data["Governance"].get("score", 100)

        pillar_scores = [env_score_100, soc_score_100, gov_score_100]
        pillar_scores.sort() 
        weighted_overall_100 = (pillar_scores[0] * 0.50) + (pillar_scores[1] * 0.25) + (pillar_scores[2] * 0.25)
        
        # Convert to 10-point scale
        overall_10 = math.floor(weighted_overall_100 / 10)

        # Call the Synthesis Engine to generate a smart summary
        dynamic_summary = self._generate_overall_summary(parent_company, overall_10, report_data)

        # Return exact requested JSON structure for the API response
        return {
            "parent_company": parent_company,
            "environment_score": math.floor(env_score_100 / 10),
            "environment_summary": report_data["Environment"].get("reasoning", "No data available."),
            "social_score": math.floor(soc_score_100 / 10),
            "social_summary": report_data["Social"].get("reasoning", "No data available."),
            "governance_score": math.floor(gov_score_100 / 10),
            "governance_summary": report_data["Governance"].get("reasoning", "No data available."),
            "overall_score": overall_10,
            "overall_summary": dynamic_summary
        }

# Instantiate once so FastAPI can import it
auditor = GeminiParallelAuditor()