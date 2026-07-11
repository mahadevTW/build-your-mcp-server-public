from fastmcp import FastMCP
from datetime import datetime

# Create MCP server
mcp = FastMCP("My First MCP Server")

@mcp.tool
def get_current_time() -> str:
    """Get the current time in ISO format, this will read the date from local machine where this tool is running"""
    return datetime.now().isoformat()

@mcp.tool
def greet(name: str) -> str:
    """Greets a person by name."""
    return f"Hello, {name}! 👋 Welcome to MCP."

if __name__ == "__main__":
    mcp.run()