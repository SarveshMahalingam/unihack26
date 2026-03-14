import httpx

async def get_product_data(barcode: str):
    url = f"https://world.openfoodfacts.org/api/v0/product/{barcode}"
    headers = {
        "User-Agent": "EthicalScannerApp/1.0 - macOS - Development"
    }
    
    # 2. Give the API 15 seconds to respond instead of the default 5
    timeout_settings = httpx.Timeout(15.0)
    
    try:
        async with httpx.AsyncClient(timeout=timeout_settings) as client:
            response = await client.get(url)
            response.raise_for_status() # Checks for 404, 500, etc.
            return response.json()
            
    except httpx.ReadTimeout:
        print(f"⏳ TIMEOUT: Open Food Facts took too long for barcode {barcode}")
        return None
    except httpx.RequestError as e:
        print(f"❌ NETWORK ERROR: Failed to reach Open Food Facts: {e}")
        return None