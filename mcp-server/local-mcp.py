from fastmcp import FastMCP
from datetime import datetime
import httpx
# Create MCP server
mcp = FastMCP("my ecommerce server, you can use this to make orders online")
BASE_ECOM_URL = "http://0.0.0.0:8000"

@mcp.tool
def getCategories() -> list[str]:
    """Get the list of categories of items which can be purchased."""
    return httpx.get(f"{BASE_ECOM_URL}/api/categories").json()

@mcp.tool
def searchItem(category: str, query: str) -> list[dict]:
    """Search for items in a specific category and text query"""
    if category:
        response = httpx.get(
            f"{BASE_ECOM_URL}/api/items?q={query}&category={category}").json()
    else:
        response = httpx.get(f"{BASE_ECOM_URL}/api/items?q={query}").json()
    return response

@mcp.tool
def greet(name: str) -> str:
    """Greets a person by name."""
    return f"Hello, {name}! 👋 Welcome to MCP."

if __name__ == "__main__":
    mcp.run() # this runs on STDIO interface unless explicitly specified