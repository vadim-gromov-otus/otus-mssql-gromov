/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/
--OPENXML
DECLARE @xml xml

SELECT @xml=R
FROM OPENROWSET (BULK 'C:\Users\Vadim\Desktop\hw10\StockItems-188-1fb5df.xml', SINGLE_BLOB) AS XMLPortbase(R)

declare @idoc int
exec sp_xml_preparedocument @idoc out, @xml, '<row xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>'

drop table if exists #StockItems
select *
into #StockItems
from openxml(@idoc, 'StockItems/Item/Package',1) 
  with (
        Name varchar(50) '../@Name',
        SupplierID int '../SupplierID',
		UnitPackageID int 'UnitPackageID',
		OuterPackageID int 'OuterPackageID',
		QuantityPerOuter int 'QuantityPerOuter',
		TypicalWeightPerUnit decimal (18,3) 'TypicalWeightPerUnit',
		LeadTimeDays int '../LeadTimeDays',
		IsChillerStock bit '../IsChillerStock',
		TaxRate decimal (18,3) '../TaxRate',
		UnitPrice decimal (18,2) '../UnitPrice'
       )

exec sp_xml_removedocument @idoc


MERGE Warehouse.StockItems AS Target
USING #StockItems AS Source
    ON (Target.StockItemName = Source.Name)
WHEN MATCHED 
    THEN UPDATE 
        SET StockItemName = Source.Name, SupplierID = Source.SupplierID, UnitPackageID = Source.UnitPackageID, OuterPackageID = Source.OuterPackageID, QuantityPerOuter = Source.QuantityPerOuter, TypicalWeightPerUnit = Source.TypicalWeightPerUnit, LeadTimeDays = Source.LeadTimeDays, IsChillerStock = Source.IsChillerStock, TaxRate = Source.TaxRate, UnitPrice = Source.UnitPrice 
WHEN NOT MATCHED 
    THEN INSERT (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy )
        VALUES (Source.Name, Source.SupplierID, Source.UnitPackageID, Source.OuterPackageID, Source.QuantityPerOuter, Source.TypicalWeightPerUnit, Source.LeadTimeDays, Source.IsChillerStock, Source.TaxRate, Source.UnitPrice, 1)


OUTPUT  $action, inserted.*;

--XQuery
DECLARE @xml xml

SELECT @xml=R
FROM OPENROWSET (BULK 'C:\Users\Vadim\Desktop\hw10\StockItems-188-1fb5df.xml', SINGLE_BLOB) AS XMLPortbase(R)

declare @idoc int
exec sp_xml_preparedocument @idoc out, @xml, '<row xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>'

exec sp_xml_removedocument @idoc


drop table if exists #StockItems
SELECT 
t.c.value('../@Name', 'varchar(50)') as Name,
t.c.value('../SupplierID[1]', 'int') as SupplierID,
t.c.value('UnitPackageID[1]', 'int') as UnitPackageID,
t.c.value('OuterPackageID[1]', 'int') as OuterPackageID,
t.c.value('QuantityPerOuter[1]', 'int') as QuantityPerOuter,
t.c.value('TypicalWeightPerUnit[1]', 'decimal (18,3)') as TypicalWeightPerUnit,
t.c.value('../LeadTimeDays[1]', 'int') as LeadTimeDays,
t.c.value('../IsChillerStock[1]', 'int') as IsChillerStock,
t.c.value('../TaxRate[1]', 'decimal (18,3)') as TaxRate,
t.c.value('../UnitPrice[1]', 'decimal (18,3)') as UnitPrice
into #StockItems
FROM @xml.nodes('StockItems/Item/Package') t(c)

MERGE Warehouse.StockItems AS Target
USING #StockItems AS Source
    ON (Target.StockItemName = Source.Name)
WHEN MATCHED 
    THEN UPDATE 
        SET StockItemName = Source.Name, SupplierID = Source.SupplierID, UnitPackageID = Source.UnitPackageID, OuterPackageID = Source.OuterPackageID, QuantityPerOuter = Source.QuantityPerOuter, TypicalWeightPerUnit = Source.TypicalWeightPerUnit, LeadTimeDays = Source.LeadTimeDays, IsChillerStock = Source.IsChillerStock, TaxRate = Source.TaxRate, UnitPrice = Source.UnitPrice 
WHEN NOT MATCHED 
    THEN INSERT (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy )
        VALUES (Source.Name, Source.SupplierID, Source.UnitPackageID, Source.OuterPackageID, Source.QuantityPerOuter, Source.TypicalWeightPerUnit, Source.LeadTimeDays, Source.IsChillerStock, Source.TaxRate, Source.UnitPrice, 1)


OUTPUT  $action, inserted.*;

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

SELECT 
StockItemName as [@Name],
SupplierID,
UnitPackageID AS [Package/UnitPackageID],
OuterPackageID AS [Package/OuterPackageID],
QuantityPerOuter AS [Package/QuantityPerOuter],
TypicalWeightPerUnit AS [Package/TypicalWeightPerUnit],
LeadTimeDays,
IsChillerStock,
TaxRate,
UnitPrice
FROM [Warehouse].[StockItems] 
FOR XML PATH ('Item'), ROOT ('StockItems')

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT
StockItemID,
StockItemName,
json_value (CustomFields,'$.CountryOfManufacture') as 'CountryOfManufacture',
json_value (CustomFields,'$.Tags[0]') as 'Tags'
 FROM [WideWorldImporters].[Warehouse].[StockItems]

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

 SELECT
StockItemID,
StockItemName,
CF.value,
json_query (CustomFields,'$.Tags') as List
 FROM [WideWorldImporters].[Warehouse].[StockItems]
 CROSS APPLY OPENJSON (CustomFields,'$.Tags') CF
 where CF.value = 'Vintage'
