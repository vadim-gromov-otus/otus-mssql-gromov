/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

Select DATEPART (year, InvoiceDate) as 'Год',
DATEPART (month, InvoiceDate) as  'Месяц',
sum(ol.Quantity * UnitPrice) as 'Общая сумма продаж за месяц' ,
avg(ol.UnitPrice) as 'Средняя цена за месяц по всем товарам' 
from [Sales].[Invoices] i
inner join [Sales].[OrderLines] ol on i.OrderID = ol.OrderID
group by DATEPART (year, InvoiceDate),DATEPART (month, InvoiceDate)
order by 1,2
/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

Select DATEPART (year, InvoiceDate) as 'Год',
DATEPART (month, InvoiceDate) as  'Месяц',
sum(ol.Quantity * UnitPrice) as 'Общая сумма продаж за месяц' 
from [Sales].[Invoices] i
inner join [Sales].[OrderLines] ol on i.OrderID = ol.OrderID
group by DATEPART (year, InvoiceDate),DATEPART (month, InvoiceDate)
having sum(ol.Quantity * UnitPrice) > 4600000
order by 1,2

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

Select 
DATEPART (year, InvoiceDate) as 'Год продажи',
DATEPART (month, InvoiceDate) as  'Месяц продажи',
si.StockItemName as 'Наименование товара', 
sum(ol.Quantity * ol.UnitPrice) as 'Сумма продаж' ,
min (InvoiceDate) as 'Дата первой продажи',
sum(ol.Quantity) as 'Количество проданного'
from [Sales].[Invoices] i
inner join [Sales].[OrderLines] ol on i.OrderID = ol.OrderID
inner join [Warehouse].[StockItems] si  on ol.StockItemID = si.StockItemID
group by DATEPART (year, InvoiceDate),DATEPART (month, InvoiceDate), si.StockItemName
having sum(ol.Quantity) < 50
order by 1,2

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
