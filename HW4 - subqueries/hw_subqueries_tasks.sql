/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT p.PersonID, p.FullName from  Application.People p
where IsSalesperson = 1
and not exists (select  * from Sales.Invoices
where InvoiceDate = '2015-07-04' and SalespersonPersonID =  p.PersonID)

---
; WITH InvoicesCTE (SalespersonPersonID) AS (
	Select SalespersonPersonID
	FROM Sales.Invoices
	where InvoiceDate = '2015-07-04'
	)


SELECT P.PersonID, P.FullName
FROM Application.People AS P
left JOIN InvoicesCTE AS I ON P.PersonID = I.SalespersonPersonID
where IsSalesperson = 1 and I.SalespersonPersonID is null 

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
select si.StockItemID, si.StockItemName, si.UnitPrice from [Warehouse].[StockItems] si
where UnitPrice = (select min( unitprice) from [Warehouse].[StockItems])


select si.StockItemID, si.StockItemName, si.UnitPrice from [Warehouse].[StockItems] si
where UnitPrice = (select top 1 unitprice from [Warehouse].[StockItems] order by unitprice asc)



/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

select CustomerID, CustomerName from [Sales].[Customers] c
where c.CustomerID in (
select top 5 WITH TIES  CustomerID from [Sales].[CustomerTransactions] ct 
order by TransactionAmount desc)


;with cte as
(
select top 5 WITH TIES  CustomerID from [Sales].[CustomerTransactions] ct 
order by TransactionAmount desc)


select CustomerID, CustomerName from [Sales].[Customers] c
where exists ( select * from cte where CustomerID = c.CustomerID)

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

--только подзапросы
select 
(select CityID from  [Application].[Cities] where CityID in (select DeliveryCityID from [Sales].[Customers] where  CustomerID = t1.CustomerID)) as CityID,
(select CityName from  [Application].[Cities] where CityID in (select DeliveryCityID from [Sales].[Customers] where  CustomerID = t1.CustomerID)) CityName,
(select FullName from [Application].[People]  where  PersonID = t1.PickedByPersonID) as FullName
from 
(select PickedByPersonID, CustomerID from [Sales].[Orders]
					where orderid in 
											(select top 3 WITH TIES orderid from [Sales].[OrderLines] 
												order by UnitPrice desc 
											)
					) as t1
order by CityID, FullName

--СTE
; with CTE_top_Price as (
	select PickedByPersonID, CustomerID from [Sales].[Orders]
	where orderid in 
						(select top 3 WITH TIES orderid from [Sales].[OrderLines] 
							order by UnitPrice desc 
						)
	)
					
, CTE_City_Cuctumer as 
					(select CityID, CityName, CustomerID,CustomerName from  [Application].[Cities] C
					inner join [Sales].[Customers] CU on c.CityID = CU.DeliveryCityID				
					)
--
Select CityID,CityName,p.FullName from CTE_top_Price CTP
inner join CTE_City_Cuctumer CCC on ctp.CustomerID = ccc.CustomerID
Left join [Application].[People] p on CTP.PickedByPersonID = p.PersonID
order by CityID,FullName

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --
--мой вариант
;with cte_1 as (
SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000
				)
, cte_2 as (
		SELECT ol.OrderID, SUM(ol.PickedQuantity*ol.UnitPrice) AS TotalSummForPickedItems
		FROM Sales.OrderLines OL
		inner join Sales.Orders O on o.OrderID = ol.OrderID
		where o.PickingCompletedWhen IS NOT NULL
		group by ol.OrderID
			)


			select i.InvoiceID, i.InvoiceDate, p.FullName, cte_1.TotalSumm,  cte_2.TotalSummForPickedItems 
			from Sales.Invoices i
			inner join cte_1 on cte_1.InvoiceID = i.InvoiceID
			inner join cte_2 on  cte_2.OrderID = i.OrderID
			inner join Application.People p on i.SalespersonPersonID = p.PersonID
				ORDER BY TotalSumm DESC

