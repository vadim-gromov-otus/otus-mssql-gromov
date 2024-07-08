/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName
  FROM [WideWorldImporters].[Warehouse].[StockItems]
  WHERE StockItemName like '%urgent%'
  OR StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT s.SupplierID, s.SupplierName
FROM Purchasing.Suppliers S
LEFT JOIN Purchasing.PurchaseOrders PS ON s.SupplierID = ps.SupplierID
WHERE ps.SupplierID IS NULL

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT 
o.OrderID,
FORMAT(o.OrderDate,'dd.MM.yyyy') as 'OrderDate',
FORMAT(o.OrderDate,'MMMM', 'RU-ru') as 'MonthName',
datepart(QUARTER, o.OrderDate) as 'NumberQuarter',
       CASE
         WHEN datepart(month, o.OrderDate) <= 4 THEN 1
         WHEN datepart(month, o.OrderDate) <= 8 THEN 3
         ELSE 3
       END AS 'ThirdOfYear',
	   C.CustomerName,
ol.Quantity * ol.UnitPrice as 'sumorder', * FROM Sales.Customers C
inner join Sales.Orders o on c.CustomerID = o.CustomerID
inner join Sales.OrderLines ol on o.OrderID = ol.OrderID
WHERE (UnitPrice > 100 or Quantity > 20) and ol.PickingCompletedWhen IS NOT NULL
ORDER BY NumberQuarter, ThirdOfYear, o.OrderDate OFFSET 100 ROW
FETCH NEXT 1000 ROWS ONLY
 

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/


SELECT 
adm.DeliveryMethodName,
ppo.ExpectedDeliveryDate ,
ps.SupplierName,
ap.FullName FROM Purchasing.Suppliers  PS
INNER JOIN Purchasing.PurchaseOrders PPO ON ps.SupplierID = PPO.SupplierID
INNER JOIN Application.DeliveryMethods ADM ON PPO.DeliveryMethodID = adm.DeliveryMethodID
INNER JOIN Application.People AP ON ppo.ContactPersonID = AP.PersonID
WHERE ppo.ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31'
AND ppo.IsOrderFinalized = 1 
AND adm.DeliveryMethodName IN ('Air Freight','Refrigerated Air Freight')

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10 c.CustomerName, ap.FullName
FROM [Sales].[Orders] o
INNER JOIN [Sales].[Customers]  C ON o.CustomerID = c.CustomerID
INNER JOIN Application.People AP ON o.SalespersonPersonID = AP.PersonID
ORDER BY OrderDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT [PersonID], [PreferredName], [PhoneNumber]  FROM [Application].[People] P
WHERE EXISTS (SELECT 1 FROM  [Sales].[Orders] O 
INNER JOIN [Sales].[OrderLines] OL ON ol.OrderID = o.OrderID
INNER JOIN [Warehouse].[StockItems] SI ON SI.StockItemID = OL.StockItemID
WHERE  p.PersonID = o.ContactPersonID AND SI.StockItemName = 'Chocolate frogs 250g')