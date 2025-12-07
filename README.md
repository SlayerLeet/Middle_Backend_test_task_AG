Простой API для добавления продуктов в заказы.

Запуск:
uvicorn main:app --reload

POST /add_item — добавить продукт в заказ:
{ "order_id": 1, "product_id": 2, "quantity": 3 }

Ответ:
{ "status": "ok", "message": "Product added to order" }