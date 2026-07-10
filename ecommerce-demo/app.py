from fastapi import FastAPI, Depends, HTTPException, Request, Query
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from database import engine, get_db, Base
from models import Item, CartItem, Order
from schemas import (
    ItemSummary,
    ItemDetail,
    AddToCartRequest,
    CartResponse,
    CartItemResponse,
    OrderResponse,
    OrderListItem,
)
from seed import seed_items

# Create tables and seed on startup
Base.metadata.create_all(bind=engine)

app = FastAPI(title="E-Commerce Demo")
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")


@app.on_event("startup")
def startup():
    from database import SessionLocal

    db = SessionLocal()
    try:
        seed_items(db)
    finally:
        db.close()


# ---------------------------------------------------------------------------
# REST APIs
# ---------------------------------------------------------------------------


@app.get("/api/items", response_model=list[ItemSummary])
def list_items(
    q: str | None = Query(
        default=None, description="Search by name, description, or tags"
    ),
    category: str | None = Query(default=None, description="Filter by category"),
    db: Session = Depends(get_db),
):
    query = db.query(Item)
    if category:
        query = query.filter(Item.category.ilike(f"%{category}%"))
    if q:
        like = f"%{q}%"
        query = query.filter(
            Item.name.ilike(like)
            | Item.description.ilike(like)
            | Item.tags.ilike(like)
            | Item.semantic_description.ilike(like)
        )
    return query.all()


@app.get("/api/items/{item_id}", response_model=ItemDetail)
def get_item(item_id: int, db: Session = Depends(get_db)):
    item = db.query(Item).filter(Item.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return item


@app.post("/api/cart")
def add_to_cart(body: AddToCartRequest, db: Session = Depends(get_db)):
    item = db.query(Item).filter(Item.id == body.item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    cart_item = db.query(CartItem).filter(CartItem.item_id == body.item_id).first()
    if cart_item:
        cart_item.quantity += body.quantity
    else:
        cart_item = CartItem(item_id=body.item_id, quantity=body.quantity)
        db.add(cart_item)
    db.commit()
    return {"message": "Item added"}


@app.get("/api/cart", response_model=CartResponse)
def get_cart(db: Session = Depends(get_db)):
    cart_items = db.query(CartItem).all()
    result = []
    grand_total = 0.0
    for ci in cart_items:
        item = db.query(Item).filter(Item.id == ci.item_id).first()
        if item:
            total = item.price * ci.quantity
            grand_total += total
            result.append(
                CartItemResponse(
                    item_id=item.id,
                    name=item.name,
                    price=item.price,
                    quantity=ci.quantity,
                    total=total,
                )
            )
    return CartResponse(items=result, grand_total=grand_total)


@app.get("/api/categories")
def list_categories(db: Session = Depends(get_db)):
    rows = db.query(Item.category).distinct().order_by(Item.category).all()
    return [r[0] for r in rows]


@app.get("/api/orders", response_model=list[OrderListItem])
def list_orders(db: Session = Depends(get_db)):
    return db.query(Order).order_by(Order.id.desc()).all()


@app.post("/api/orders", response_model=OrderResponse)
def place_order(db: Session = Depends(get_db)):
    cart_items = db.query(CartItem).all()
    if not cart_items:
        raise HTTPException(status_code=400, detail="Cart is empty")

    grand_total = 0.0
    for ci in cart_items:
        item = db.query(Item).filter(Item.id == ci.item_id).first()
        if item:
            grand_total += item.price * ci.quantity

    order = Order(total_amount=grand_total, payment_mode="Cash on Delivery")
    db.add(order)
    db.query(CartItem).delete()
    db.commit()
    db.refresh(order)

    return OrderResponse(
        order_id=order.id,
        payment_mode=order.payment_mode,
        total_amount=order.total_amount,
    )


# ---------------------------------------------------------------------------
# HTML Pages
# ---------------------------------------------------------------------------


@app.get("/")
def home(request: Request, db: Session = Depends(get_db)):
    items = db.query(Item).all()
    return templates.TemplateResponse(request, "index.html", {"items": items})


@app.get("/products/{item_id}")
def product_page(item_id: int, request: Request, db: Session = Depends(get_db)):
    item = db.query(Item).filter(Item.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Product not found")
    return templates.TemplateResponse(request, "product.html", {"item": item})


@app.post("/cart/add")
async def cart_add_form(request: Request, db: Session = Depends(get_db)):
    form = await request.form()
    item_id = int(form.get("item_id"))
    quantity = int(form.get("quantity", 1))

    item = db.query(Item).filter(Item.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    cart_item = db.query(CartItem).filter(CartItem.item_id == item_id).first()
    if cart_item:
        cart_item.quantity += quantity
    else:
        cart_item = CartItem(item_id=item_id, quantity=quantity)
        db.add(cart_item)
    db.commit()
    return RedirectResponse(url="/cart", status_code=303)


@app.get("/cart")
def cart_page(request: Request, db: Session = Depends(get_db)):
    cart_items = db.query(CartItem).all()
    result = []
    grand_total = 0.0
    for ci in cart_items:
        item = db.query(Item).filter(Item.id == ci.item_id).first()
        if item:
            total = item.price * ci.quantity
            grand_total += total
            result.append({"item": item, "quantity": ci.quantity, "total": total})
    return templates.TemplateResponse(
        request,
        "cart.html",
        {
            "cart_items": result,
            "grand_total": grand_total,
        },
    )


@app.post("/cart/checkout")
def checkout(request: Request, db: Session = Depends(get_db)):
    cart_items = db.query(CartItem).all()
    if not cart_items:
        return RedirectResponse(url="/cart", status_code=303)

    grand_total = 0.0
    for ci in cart_items:
        item = db.query(Item).filter(Item.id == ci.item_id).first()
        if item:
            grand_total += item.price * ci.quantity

    order = Order(total_amount=grand_total, payment_mode="Cash on Delivery")
    db.add(order)
    db.query(CartItem).delete()
    db.commit()
    return RedirectResponse(url="/order-success", status_code=303)


@app.get("/order-success")
def order_success(request: Request):
    return templates.TemplateResponse(request, "order_success.html")


@app.get("/orders")
def orders_page(request: Request, db: Session = Depends(get_db)):
    orders = db.query(Order).order_by(Order.id.desc()).all()
    return templates.TemplateResponse(request, "orders.html", {"orders": orders})


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
