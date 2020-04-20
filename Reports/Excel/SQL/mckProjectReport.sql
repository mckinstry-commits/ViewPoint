--DROP TABLE mckProjectReport
IF EXISTS ( SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='mckProjectReport')
BEGIN
	PRINT 'DROP TABLE mckProjectReport'
	DROP TABLE dbo.mckProjectReport
END
go

--create table mckProjectReport
PRINT 'CREATE TABLE mckProjectReport'
go
CREATE TABLE dbo.mckProjectReport
(
	[Month] smalldatetime NOT NULL
,	[JCCo] [tinyint] NOT NULL
,	[GL Department] [varchar](4) NOT NULL
,	[GL Department Name] [varchar](60) NULL
,	[Contract] [varchar](10) NOT NULL
, 	[Contract Description] [varchar](60) NULL
,	[Contract Status] tinyint NULL
,	[Revenue Type] [varchar](10) NULL
,	[Completion Date] smalldatetime
,	[Last Revenue Projection] smalldatetime NULL
,	[Last Cost Projection] smalldatetime NULL
,	[Original Gross Margin] [decimal] (18, 2) NULL
,	[Original Gross Margin %] [decimal](18,10) NULL
,	[Projected Final Billing] [decimal] (18, 2) NULL
,	[POC] [varchar](30) NULL
,	[Sales Person] [varchar](30) NULL
,	[Customer #] int NULL
,	[Customer Name] [varchar](60) NULL
,	[Customer Contact Name] [varchar](30) NULL
,	[Customer Phone Number] [varchar](20) NULL
,	[Customer Email Address] [varchar](60) NULL
,   [Current Contract Value] [decimal](18, 2) NULL
,	[Projected Final Contract Amount] [decimal](18, 2) NULL
,	[Projected COs] [decimal](18, 2) NULL
,	[Previous Month Projected Final Contract Amount] [decimal](18, 2) NULL
,	[JTD Costs Previous Month] [decimal](18, 2) NULL
,	[Previous Month Projected Final Cost] [decimal](18, 2) NULL
,	[% Complete Previous Month] [numeric](18, 10) NULL
,	[Current JTD Costs] [decimal](18, 2) NULL
,	[Current Remaining Committed Cost] [decimal](18, 2) NULL
,	[Current JTD Amount Billed] [decimal](18, 2) NULL
,	[Current JTD Revenue Earned] [numeric](38, 8) NULL
,	[Current JTD Net Under Over Billed] [decimal](18, 2) NULL
,	[JTD Net Cash Position] [numeric](38, 2) NULL
,	[Current Retention Unbilled] [numeric](12, 2) NULL
,	[Partition Ratio] [decimal](18,15)	NULL
,	[Unpaid A/R Balance] [numeric](38, 2) NULL
,	[AR Current Amount] [numeric](38, 2) NULL
,	[AR 31-60 Days Amount] [numeric](38, 2) NULL
,	[AR 61-90 Days Amount] [numeric](38, 2) NULL
,	[AR Over 90 Amount] [numeric](38, 2) NULL
,	[Current Projected Final Cost] [decimal](37, 17) NULL
,	[Current Projected Final Gross Margin] [numeric](38, 17) NULL
,	[Current Projected Final Gross Margin %] [decimal](18,10) NULL
,	[MOM Variance of Projected Final Contract Amount] [numeric](29, 8) NULL
,	[MOM Variance of Projected Final Cost] [decimal](37, 17) NULL
,	[MOM Variance of Projected Final Gross Margin] [numeric](38, 17) NULL
,	[MOM Variance of Projected Final Gross Margin %] [decimal](18,10) NULL
,	[Processed On] [datetime] NULL
)
go

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckProjectReport_Month_JCCo_GLDepartment_Contract')
    DROP INDEX IX_mckProjectReport_Month_JCCo_GLDepartment_Contract ON dbo.mckProjectReport;
GO
CREATE NONCLUSTERED INDEX IX_mckProjectReport_Month_JCCo_GLDepartment_Contract
    ON dbo.mckProjectReport (Month, JCCo, [GL Department], Contract);
GO

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckProjectReport_Month_JCCo')
    DROP INDEX IX_mckProjectReport_Month_JCCo ON 
dbo.mckProjectReport;
GO
CREATE NONCLUSTERED INDEX IX_mckProjectReport_Month_JCCo
    ON dbo.mckProjectReport (Month, JCCo);
GO

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckProjectReport_Month_JCCo_Contract')
    DROP INDEX IX_mckProjectReport_Month_JCCo_Contract ON 
dbo.mckProjectReport;
GO
CREATE NONCLUSTERED INDEX IX_mckProjectReport_Month_JCCo_Contract
    ON dbo.mckProjectReport (Month, JCCo, Contract);
GO

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckProjectReport_Month_JCCo_GLDepartment')
    DROP INDEX IX_mckProjectReport_Month_JCCo_GLDepartment ON 
dbo.mckProjectReport;
GO
CREATE NONCLUSTERED INDEX IX_mckProjectReport_Month_JCCo_GLDepartment
    ON dbo.mckProjectReport (Month, JCCo, [GL Department]);
GO

GRANT SELECT ON dbo.mckProjectReport TO [public]
GO