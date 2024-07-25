/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

select  
o.OrderDate as OrderDay
,(select  sum(UnitPrice*PickedQuantity) 	
		from [Sales].[Orders] o1
		inner join 	sales.OrderLines OL1 on o1.OrderID = ol1.OrderID
		where o1.OrderDate between '2015-01-01' and '2015-12-31' and  MONTH(o1.OrderDate) <=MONTH(o.OrderDate)
		) as total
from [Sales].[Orders] O
inner join 	sales.OrderLines OL on o.OrderID = ol.OrderID
where o.OrderDate between '2015-01-01' and '2015-12-31'
order by 1

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

select OrderDay, sum(sum) over( order by month(OrderDay)) as TotalSumm
from 
(
select 
o.OrderDate as OrderDay
,(UnitPrice*PickedQuantity) as sum
		from [Sales].[Orders] o
		inner join 	sales.OrderLines OL on o.OrderID = ol.OrderID
		where o.OrderDate between '2015-01-01' and '2015-12-31' 
		) as t1
order by 1

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

select MONTH, si.StockItemName, count from
(
select 
MONTH(o.OrderDate) as MONTH,
StockItemID,
count(*) as count,
DENSE_RANK() over (partition by MONTH(o.OrderDate) order by count(*) desc) as rang

		from [Sales].[Orders] o
		inner join 	sales.OrderLines OL on o.OrderID = ol.OrderID
		where o.OrderDate between '2016-01-01' and '2016-12-31'
		group by MONTH(o.OrderDate),StockItemID
		
) as t1
inner join [Warehouse].[StockItems] SI on t1.StockItemID = si.StockItemID
where rang <=2
order by month, count desc

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select 
row_number() over (partition by SUBSTRING(StockItemName, 1, 1) order by StockItemName) as '1',
COUNT(*) OVER()  as '2',
COUNT(*) OVER(order  by SUBSTRING(StockItemName, 1, 1)) AS '3',
lead([StockItemID]) OVER(order  by StockItemName) as '4',
lag([StockItemID]) OVER(order  by StockItemName) as '5',
isnull (lag(StockItemName,2) OVER(order  by StockItemName),'No items') as '6',
ntile(30) over (order by TypicalWeightPerUnit) as '7',
[StockItemID],
[StockItemName],
[Brand],
[UnitPrice]
 from [Warehouse].[StockItems]

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

;with CTE as (
select distinct
first_value (CustomerID) over  (partition by [SalespersonPersonID] order by orderDate desc, o.OrderID desc) as LastCustomerID,
first_value (OrderDate) over  (partition by [SalespersonPersonID] order by orderDate desc, o.OrderID desc) as LastOrderDate,
first_value (OrderID) over  (partition by [SalespersonPersonID] order by orderDate desc, o.OrderID desc) as LastOrderid,
SalespersonPersonID from [Sales].[Orders] o)

Select LastOrderDate, p.PersonID, p.FullName, c.CustomerID, c.CustomerName , sum([Quantity]*[UnitPrice]) as SummOrder
from [Sales].[Customers] C
inner join  CTE on c.CustomerID = CTE.LastCustomerID
inner join [Application].[People] P on P.PersonID = CTE.SalespersonPersonID
inner join [Sales].[OrderLines] OL on ol.OrderID = CTE.LastOrderid
group by LastOrderDate, p.PersonID, p.FullName, c.CustomerID, c.CustomerName

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select c.CustomerID, c.CustomerName, UnitPrice, OrderDate from [Sales].[Customers] C 
inner join 
(select UnitPrice,
DENSE_RANK() over (partition by [CustomerID] order by ([UnitPrice]) desc) as rang,
CustomerID,
StockItemID,
OrderDate
from [Sales].[Orders] o
inner join 	sales.OrderLines OL on o.OrderID = ol.OrderID) as  t1 on t1.CustomerID = c.CustomerID
where t1.rang <=2
