/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

declare @dml nvarchar (max),
		@ColumnName nvarchar (max)

select @ColumnName = STRING_AGG (cast (quotename (CustomerName) as nvarchar (max)),',') WITHIN GROUP (ORDER BY CustomerName ASC)
from 
(select distinct  CustomerName
from [Sales].[Orders] o
inner join [Sales].[OrderLines] ol on o.orderid = ol.orderid
inner join [Sales].[Customers] c on o.CustomerID = c.CustomerID ) as t1


set  @dml = N'select FORMAT( Mon, ''d'', ''ru-RU'' ) as  Mon ,' +@ColumnName+'
		from
		(select 
			 DATETRUNC(month, o.orderdate) as Mon,
			CustomerName,
			 ol.OrderLineID
			from [Sales].[Orders] o
			inner join [Sales].[OrderLines] ol on o.orderid = ol.orderid
			inner join [Sales].[Customers] c on o.CustomerID = c.CustomerID 
			) 
		as SourceTable
		pivot
		(
		count(OrderLineID)
		for [CustomerName] 
		in ('+@ColumnName+') 
		)
		as PivotTable
		order by YEAR(Mon),month(Mon)'


exec sp_executesql @dml