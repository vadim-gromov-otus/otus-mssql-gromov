/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/


INSERT INTO Sales.Customers
           (CustomerName,BillToCustomerID,CustomerCategoryID,BuyingGroupID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,DeliveryCityID,PostalCityID,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,PaymentDays,PhoneNumber,FaxNumber,WebsiteURL,DeliveryAddressLine1 ,DeliveryAddressLine2,DeliveryPostalCode,PostalAddressLine1 ,PostalAddressLine2,PostalPostalCode,LastEditedBy)
     VALUES ('Tailspin Toys (Head Office)1' ,1,3,1, 1001, 1002,	3,	19586 ,	19586,	'2013-01-01',	0.000,	0,	0,	7,	'(308) 555-0100',	'(308) 555-0101', 'http://www.tailspintoys.com',	'Shop 38' ,	'1877 Mittal Road',	90410,	'PO Box 8975',	'Ribeiroville',	90410,	1),
     ('Tailspin Toys (Head Office)2' ,1,3,1, 1001, 1002,	3,	19586 ,	19586,	'2013-01-01',	0.000,	0,	0,	7,	'(308) 555-0100',	'(308) 555-0101', 'http://www.tailspintoys.com',	'Shop 38' ,	'1877 Mittal Road',	90410,	'PO Box 8975',	'Ribeiroville',	90410,	1),
     ('Tailspin Toys (Head Office)3' ,1,3,1, 1001, 1002,	3,	19586 ,	19586,	'2013-01-01',	0.000,	0,	0,	7,	'(308) 555-0100',	'(308) 555-0101', 'http://www.tailspintoys.com',	'Shop 38' ,	'1877 Mittal Road',	90410,	'PO Box 8975',	'Ribeiroville',	90410,	1),
     ('Tailspin Toys (Head Office)4' ,1,3,1, 1001, 1002,	3,	19586 ,	19586,	'2013-01-01',	0.000,	0,	0,	7,	'(308) 555-0100',	'(308) 555-0101', 'http://www.tailspintoys.com',	'Shop 38' ,	'1877 Mittal Road',	90410,	'PO Box 8975',	'Ribeiroville',	90410,	1),
     ('Tailspin Toys (Head Office)5' ,1,3,1, 1001, 1002,	3,	19586 ,	19586,	'2013-01-01',	0.000,	0,	0,	7,	'(308) 555-0100',	'(308) 555-0101', 'http://www.tailspintoys.com',	'Shop 38' ,	'1877 Mittal Road',	90410,	'PO Box 8975',	'Ribeiroville',	90410,	1)


/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

delete [Sales].[Customers] where CustomerName = 'Tailspin Toys (Head Office)1'


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

update [Sales].[Customers] set CustomerName = 'Tailspin Toys (Head Office)22' where CustomerName = 'Tailspin Toys (Head Office)2'

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

MERGE Sales.Customers AS Target
USING Sales.Customers2 AS Source
    ON (Target.CustomerName = Source.CustomerName)
WHEN MATCHED 
    THEN UPDATE 
        SET CustomerName = Source.CustomerName
WHEN NOT MATCHED 
    THEN INSERT 
        VALUES (source. CustomerName, source.BillToCustomerID, source.CustomerCategoryID, source.BuyingGroupID, source.PrimaryContactPersonID, source.AlternateContactPersonID, source.DeliveryMethodID, source.DeliveryCityID, source.PostalCityID, source.AccountOpenedDate, source.StandardDiscountPercentage, source.IsStatementSent, source.IsOnCreditHold, source.PaymentDays, source.PhoneNumber, source.FaxNumber, source.WebsiteURL, source.DeliveryAddressLine1 , source.DeliveryAddressLine2, source.DeliveryPostalCode, source.PostalAddressLine1 , source.PostalAddressLine2, source.PostalPostalCode, source.LastEditedBy)

WHEN NOT MATCHED BY SOURCE
    THEN 
        DELETE
OUTPUT deleted.*, $action, inserted.*;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

bcp Sales.Customers out "C:\Tmp\SalesCustomers.csv" -N -T -S "DESKTOP-7AMDOR5" -d "WideWorldImporters" -c

select * 
into #import
from Sales.Customers 
where 1=2



BULK INSERT #import
   FROM 'C:\Tmp\SalesCustomers.csv';


