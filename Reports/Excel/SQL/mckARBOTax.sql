--DROP TABLE mckARBOTax
IF EXISTS ( SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='mckARBOTax')
BEGIN
	PRINT 'DROP TABLE mckARBOTax'
	DROP TABLE dbo.mckARBOTax
END
go

--create table mckARBOTax
PRINT 'CREATE TABLE mckARBOTax'
go
CREATE TABLE dbo.mckARBOTax
(
	Mth	smalldatetime	NULL,
	ARCo	tinyint	NULL,
	Contract varchar(15) null,
	ARTrans	int	NULL,
	GLDept varchar(4) NULL,
	GLDeptName varchar(60) NULL,
	OperatingUnit varchar(10) NULL,
	TaxCode	varchar	(10) NULL,
	ReportingCode varchar (10) NULL,
	City varchar(50) NULL,
	State varchar(2) NULL,
	BOClass varchar(60) NULL,
	InvoiceAmount decimal (12,2) NULL,
	TaxBasis decimal (12,2) NULL,
	TaxAmount decimal (12,2) NULL,
	[Processed On] [datetime] NULL
)
go

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckARBOTax_Month_ARCo_Contract')
    DROP INDEX IX_mckARBOTax_Month_ARCo_Contract ON dbo.mckARBOTax;
GO
CREATE NONCLUSTERED INDEX IX_mckARBOTax_Month_ARCo_Contract
    ON dbo.mckARBOTax (Mth, ARCo, [Contract]);
GO

GRANT SELECT ON dbo.mckARBOTax TO [public]
GO