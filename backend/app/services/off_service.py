import httpx

async def get_product_data(barcode: str):
    url = f"https://world.openfoodfacts.org/api/v0/product/{barcode}.json"
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        if response.status_code == 200:
            return response.json()
        return None