import os

from fastapi.responses import JSONResponse
from fastmcp import FastMCP
import httpx

BASE_ECOM_URL = os.getenv("ECOMMERCE_BASE_URL", "https://ecommerce-demo-production-f799.up.railway.app")
mcp = FastMCP("E-commerce Assistant, whenever you are using tool and data, make sure only requireed information is visible, ex, id of each items not required for users to see, dont show them, dont ask for cross confirmation")

@mcp.custom_route("/health", methods=["GET"])
async def health(request):
    return JSONResponse({
        "status": "healthy",
        "service": "my-mcp-server"
    })

@mcp.tool
def list_categories(name: str) -> str:
    """List all the categories of items which can be purchased."""
    response = httpx.get(f"{BASE_ECOM_URL}/api/categories")
    return response.text


@mcp.tool
def search_items(category: str, query: str) -> str:
    """Search for items in a specific category."""
    if category:
        response = httpx.get(
            f"{BASE_ECOM_URL}/api/items?q={query}&category={category}",
        )
    else:
        response = httpx.get(
            f"{BASE_ECOM_URL}/api/items?q={query}",
        )
    return response.text


@mcp.tool
def get_item_details(item_id: str) -> str:
    """Get details of a specific item by its ID."""
    response = httpx.get(f"{BASE_ECOM_URL}/api/items/{item_id}")
    return response.text


@mcp.tool
def add_to_cart(item_id: str, quantity: int) -> str:
    """Add an item to the cart."""
    response = httpx.post(
        f"{BASE_ECOM_URL}/api/cart", json={"item_id": item_id, "quantity": quantity}
    )
    return response.text


@mcp.tool
def view_cart() -> str:
    """View the contents of the cart."""
    response = httpx.get(f"{BASE_ECOM_URL}/api/cart")
    return response.text


@mcp.tool
def place_order() -> str:
    """Place an order for the items in the cart"""
    response = httpx.post(f"{BASE_ECOM_URL}/api/orders")
    return response.text


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8081"))
    mcp.run(
        transport="http",
        host="0.0.0.0",
        port=port,
        allowed_hosts=["*"],
        allowed_origins=["*"],
    )