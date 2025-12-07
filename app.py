from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, ForeignKey
from sqlalchemy.orm import sessionmaker, relationship, declarative_base

DATABASE_URL = "sqlite:///./test.db"  # для примера

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()


class Order(Base):
    __tablename__ = "orders"

    order_ID = Column(Integer, primary_key=True, index=True)


class Product(Base):
    __tablename__ = "products"

    product_ID = Column(Integer, primary_key=True, index=True)
    quantity = Column(Integer, nullable=False)  # остаток на складе


class OrderItem(Base):
    __tablename__ = "order_items"

    order_item_ID = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.order_ID"))
    product_id = Column(Integer, ForeignKey("products.product_ID"))
    quantity = Column(Integer, nullable=False, default=1)

    order = relationship("Order")
    product = relationship("Product")


Base.metadata.create_all(bind=engine)


app = FastAPI()


class AddItemRequest(BaseModel):
    order_id: int
    product_id: int
    quantity: int


@app.post("/add_item")
def add_item_to_order(data: AddItemRequest):
    db = SessionLocal()

    order = db.query(Order).filter(Order.order_ID == data.order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    product = db.query(Product).filter(Product.product_ID == data.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    if product.quantity < data.quantity:
        raise HTTPException(status_code=400, detail="Not enough product in stock")

    order_item = (
        db.query(OrderItem)
        .filter(
            OrderItem.order_id == data.order_id,
            OrderItem.product_id == data.product_id
        )
        .first()
    )

    if order_item:
        order_item.quantity += data.quantity
    else:
        order_item = OrderItem(
            order_id=data.order_id,
            product_id=data.product_id,
            quantity=data.quantity
        )
        db.add(order_item)

    product.quantity -= data.quantity
    db.commit()

    return {"status": "ok", "message": "Product added to order"}
