2.1. Получение информации о сумме товаров заказанных
под каждого клиента (Наименование клиента, сумма)

SELECT 
    c.name AS client_name,
    SUM(oi.quantity * oi.price_at_moment) AS total_amount
FROM clients c
JOIN orders o ON o.client_id = c.client_ID
JOIN order_items oi ON oi.order_id = o.order_ID
GROUP BY c.client_ID, c.name;

2.2. Найти количество дочерних элементов первого уровня
 вложенности для категорий номенклатуры.

SELECT 
    c.category_ID,
    c.name AS category_name,
    COUNT(child.category_ID) AS children_count
FROM categories c
LEFT JOIN categories child
    ON child.parent_id = c.category_ID
GROUP BY c.category_ID, c.name;

2.3.
2.3.1. Написать текст запроса для отчета (view)
 «Топ-5 самых покупаемых товаров за последний месяц» (по количеству штук в заказах).
  В отчете должны быть: Наименование товара, Категория 1-го уровня,
   Общее количество проданных штук.

CREATE OR REPLACE VIEW top_5_products_last_month AS
SELECT 
    p.name AS product_name,
    root_cat.name AS root_category,
    SUM(oi.quantity) AS total_sold
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_ID
JOIN products p ON oi.product_id = p.product_ID
JOIN categories cat ON p.category_id = cat.category_ID
LEFT JOIN categories root_cat 
       ON (cat.parent_id IS NULL AND root_cat.category_ID = cat.category_ID)
       OR (cat.parent_id IS NOT NULL AND root_cat.category_ID = cat.parent_id)
WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY p.name, root_cat.name
ORDER BY total_sold DESC
LIMIT 5;

2.3.2. Проанализировать написанный в п. 
2.3.1 запрос и структуру БД. Предложить варианты оптимизации этого запроса
 и общей схемы данных для повышения производительности системы
  в условиях роста данных (тысячи заказов в день).

Варианты оптимизации:
1. Индексы на ключевых полях
Добавить индексы на:
orders(order_date)
order_items(order_id, product_id)
products(category_id)
categories(parent_id)
Это снимает основную нагрузку с JOIN и фильтрации по дате.

2. Материализованное представление
Для отчёта «топ-5 за месяц» сделать materialized view с периодическим обновлением.
Частые запросы перестанут каждый раз пересчитывать агрегаты по огромному числу заказов.

3. Упростить работу с категориями
Избавиться от поиска родительской категории «на лету».
Хранить root_category_id прямо в products или использовать структуру дерева, рассчитанную на быстрые запросы (closure table / nested sets).
Это убирает лишние JOIN и ускоряет выборку.

4. Партиционирование заказов
Разбить orders по датам (месячные партиции).
Когда заказов тысячи в день, это резко ускоряет выборку «за последний месяц».

5. Кэширование горячих данных
Сам отчёт или его результаты можно класть в Redis и обновлять по расписанию.
Это помогает, если отчёты вызываются постоянно.