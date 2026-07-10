from datetime import datetime

from pydantic import BaseModel, field_validator
from typing import List


class ItemSummary(BaseModel):
    id: int
    name: str
    price: float
    category: str
    tags: List[str]

    @field_validator("tags", mode="before")
    @classmethod
    def split_tags(cls, v):
        if isinstance(v, str):
            return [t.strip() for t in v.split(",") if t.strip()]
        return v

    class Config:
        from_attributes = True


class ItemDetail(BaseModel):
    id: int
    name: str
    description: str
    price: float
    category: str
    tags: List[str]
    semantic_description: str

    @field_validator("tags", mode="before")
    @classmethod
    def split_tags(cls, v):
        if isinstance(v, str):
            return [t.strip() for t in v.split(",") if t.strip()]
        return v

    class Config:
        from_attributes = True


class AddToCartRequest(BaseModel):
    item_id: int
    quantity: int


class CartItemResponse(BaseModel):
    item_id: int
    name: str
    price: float
    quantity: int
    total: float


class CartResponse(BaseModel):
    items: List[CartItemResponse]
    grand_total: float


class OrderResponse(BaseModel):
    order_id: int
    payment_mode: str
    total_amount: float


class OrderItemResponse(BaseModel):
    item_name: str
    price: float
    quantity: int

    class Config:
        from_attributes = True


class OrderListItem(BaseModel):
    id: int
    total_amount: float
    payment_mode: str
    created_at: datetime
    items: List[OrderItemResponse]

    class Config:
        from_attributes = True
