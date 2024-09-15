/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

CREATE PROCEDURE GetCustomerIDMaxSumm
	AS

	Select top 1 CustomerID, summ from [Sales].[Orders] o
	inner join (
	Select OrderID, sum(Quantity*UnitPrice) as summ
	from [Sales].[OrderLines] OL 
	group by OrderID) as OL on o.OrderID = ol.OrderID
	order by summ desc
	

	EXECUTE GetCustomerIDMaxSumm

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

CREATE PROCEDURE GetCustomerIDSumm
@CustemerID int
	AS

	Select SUM(summ) as 'sum' from [Sales].[Invoices] i
	inner join (
	Select InvoiceID, sum(Quantity*UnitPrice) as summ
	from [Sales].[InvoiceLines] IL 
	group by InvoiceID) as iL on i.OrderID = il.InvoiceID
	where i.CustomerID = @CustemerID

	EXECUTE GetCustomerIDSumm @CustemerID = 18



/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/
--создал функцию аналогичную процедуре из п.2 
-- признаться я разницы в производителлности не заметил, возможно если бы она была тяжелее то было бы заметнее. 

CREATE FUNCTION dbo.FnGetCustomerIDSumm (@CustemerID int)
RETURNS decimal(18,2)
	as
	begin
	declare @sum decimal(18,2)
	Select @sum = SUM(summ)
	from [Sales].[Invoices] i
	inner join (
	Select InvoiceID, sum(Quantity*UnitPrice) as summ
	from [Sales].[InvoiceLines] IL 
	group by InvoiceID) as iL on i.OrderID = il.InvoiceID
	where i.CustomerID = @CustemerID
	RETURN @sum;
	end

	select dbo.FnGetCustomerIDSumm(18) as 'sum'

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/


CREATE FUNCTION dbo.FnGetCustomerIDSummTable (@CustemerID int)
RETURNS TABLE
as
return(
	select SUM(summ) as 'summ'
	from [Sales].[Invoices] i
	inner join (
	Select InvoiceID, sum(Quantity*UnitPrice) as summ
	from [Sales].[InvoiceLines] IL 
	group by InvoiceID) as iL on i.OrderID = il.InvoiceID
	where i.CustomerID = @CustemerID
	)


	select top 10 c.CustomerName, s.* from [Sales].[Customers] C
	cross apply dbo.FnGetCustomerIDSummTable(c.CustomerID) s

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
--Я бы использвал везде read committed
