--DROP TABLE mckARBOTax
IF EXISTS ( SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='mckRevGM')
BEGIN
	PRINT 'DROP TABLE mckRevGM'
	DROP TABLE dbo.mckRevGM
END
go

--create table mckARBOTax
PRINT 'CREATE TABLE mckRevGM'
go
	
CREATE TABLE dbo.mckRevGM (
	[SessionId] [uniqueidentifier] NOT NULL,
	[JCCo] [tinyint] NULL,
	[GL Dept.] [varchar](4) NULL,
	[GL Dept. Name] [varchar](60) NULL,
	[Contract] [varchar](10) NULL,
	[Work Order] [int] NULL,
	[Contract Description] [varchar](60) NULL,
	[Contract Status] [varchar](60) NULL,
	[Customer Number] [int] NULL,
	[Customer Name] [varchar](60) NULL,
	[POC Name] [varchar](60) NULL,
	[Sales Person] [varchar](30) NULL,
	[Vertical Market] [varchar](255) NULL,
	[CRM Oppty Numbers] [varchar](255) NULL,
	[Revenue Type] [varchar](60) NULL,

	[Original Contract Amount] [decimal](18, 2) NULL,
	[Original Cost] [decimal](18, 2) NULL,
	[Original Gross Margin] [decimal](18, 2) NULL,
	[Original Gross Margin %] [decimal](18, 15) NULL,

	[Projected Final Contract Amount] [numeric](29, 8) NULL,
	[Projected Final Cost] [decimal](37, 17) NULL,
	[Projected Final Gross Margin] [numeric](38, 17) NULL,
	[Projected Final Gross Margin %] [decimal](18, 10) NULL,

	[Period Change in Projected Contract Amount] [numeric](29, 8) NULL,
	[Period Change in Projected Final Gross Margin] [numeric](38, 17) NULL,
	[Period Change in Projected Final Gross Margin %] [decimal](18, 10) NULL,

	[New Projected Final Contract Amount] [numeric](29, 8) NULL,
	[New Projected Final Gross Margin] [numeric](38, 17) NULL,
	[New Projected Final Gross Margin %] [decimal](18, 10) NULL,

	[Period Earned Revenue] [decimal](18, 2) NULL,
	[Period Earned Gross Margin] [numeric](38, 17) NULL,
	[Period Earned Gross Margin %] [decimal](18, 2) NULL
)
go

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckRevGM_SessionId_JCCo_GLDept_Contract_WorkOrder')
    DROP INDEX IX_mckRevGM_SessionId_JCCo_GLDept_Contract_WorkOrder ON dbo.mckRevGM;
GO
CREATE NONCLUSTERED INDEX IX_mckRevGM_SessionId_JCCo_GLDept_Contract_WorkOrder
    ON dbo.mckRevGM ([SessionId], [JCCo], [GL Dept.], [Contract], [Work Order]);
GO

--GRANT ALL ON dbo.mckRevGM TO [public]
GRANT INSERT, UPDATE, DELETE ON dbo.mckRevGM TO [public]
GO
GRANT INSERT, UPDATE, DELETE ON dbo.mckRevGM TO [MCKINSTRY\ViewpointUsers]
GO