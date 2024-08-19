/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

with cte_t1 as
(select 
 DATETRUNC(month, o.orderdate) as Mon,
 left ([CustomerName], charindex('(',[CustomerName])-2) +', '+ left (right ([CustomerName], len ([CustomerName])-charindex(',',[CustomerName])), charindex(')',right ([CustomerName], len ([CustomerName])-charindex(',',[CustomerName])))-1) as CustomerName ,
 ol.OrderLineID
from [Sales].[Orders] o
inner join [Sales].[OrderLines] ol on o.orderid = ol.orderid
inner join [Sales].[Customers] c on o.CustomerID = c.CustomerID 
where  c.CustomerID in (2,3,4,5,6)
)

select FORMAT( Mon, 'd', 'ru-RU' ) as  Mon , [Tailspin Toys,  KS],  [Tailspin Toys,  ND], [Tailspin Toys,  AZ], [Tailspin Toys,  MT], [Tailspin Toys,  NY]
from
(select Mon, CustomerName ,OrderLineID from cte_t1) 
as SourceTable
pivot
(
count(OrderLineID)
for [CustomerName] 
in ( [Tailspin Toys,  KS],  [Tailspin Toys,  ND], [Tailspin Toys,  AZ], [Tailspin Toys,  MT], [Tailspin Toys,  NY]) 
)
as PivotTable
order by YEAR(Mon),month(Mon)

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select CustomerName , AddressLine from [Sales].[Customers] C

cross apply (select [DeliveryAddressLine1] as AddressLine
					from [Sales].[Customers] 
					 ) as o
 where c.CustomerName like 'Tailspin Toys%'		
 order by CustomerName

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select [CountryID],[CountryName],code
from  
		(select [CountryID],[CountryName],cast (IsoAlpha3Code as varchar(12)) as IsoAlpha3Code, cast (IsoNumericCode as varchar(12)) as IsoNumericCode from [Application].[Countries]) as t1

unpivot
(
code for columnname in (IsoAlpha3Code, IsoNumericCode)
) as T_unpivot

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select c.CustomerID, c.CustomerName, t1.* from [Sales].[Customers] c
cross apply 
(select top 2 [StockItemID],max([UnitPrice]) as UnitPrice, max([OrderDate]) as OrderDate
from [Sales].[Orders] O
inner join  [Sales].[OrderLines] OL on o.OrderID = ol.OrderID
where o.CustomerID = c.CustomerID
group by [StockItemID]
order by UnitPrice desc) as t1

