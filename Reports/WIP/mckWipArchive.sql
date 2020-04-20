--DROP TABLE mckWipArchive
IF EXISTS ( SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND 
TABLE_NAME='mckWipArchive')
BEGIN
	PRINT 'DROP TABLE mckWipArchive'
	DROP TABLE dbo.mckWipArchive
END
go

--create table mckWipArchive
PRINT 'CREATE TABLE mckWipArchive'
go
CREATE TABLE dbo.mckWipArchive
(
	[JCCo] [tinyint] NULL,
	[WorkOrder] [int] NULL,
	[Contract] [varchar](10) NULL,
	[CGCJobNumber] [varchar](20) NULL,
	[ThroughMonth] [smalldatetime] NULL,
	[ContractDesc] [varchar](60) NULL,
	[IsLocked] [char](1) NULL,
	[RevenueType] [varchar](10) NULL,
	[RevenueTypeName] [varchar](60) NULL,
	[ContractStatus] [varchar](10) NULL,
	[ContractStatusDesc] [varchar](60) NULL,
	[GLDepartment] [varchar](4) NULL,
	[GLDepartmentName] [varchar](60) NULL,
	[POC] [int] NULL,
	[POCName] [varchar](60) NULL,
	[OrigContractAmt] [decimal](18, 2) NULL,
	[CurrContractAmt] [decimal](18, 2) NULL,
	[ProjContractAmt] [decimal](18, 2) NULL,
	[RevenueIsOverride] [char](1) NULL,
	[OverrideRevenueTotal] [decimal](18, 2) NULL,
	[RevenueOverridePercent] [decimal](18, 15) NULL,
	[RevenueOverrideAmount] [decimal](18, 2) NULL,
	[RevenueWIPAmount] [numeric](29, 8) NULL,
	[JTDBilled] [decimal](18, 2) NULL,
	[SalesPersonID] [int] NULL,
	[SalesPerson] [varchar](30) NULL,
	[VerticalMarket] [varchar](255) NULL,
	[MarkUpRate] [numeric](8, 6) NULL,
	[StrLineTermStart] [smalldatetime] NULL,
	[StrLineTerm] [tinyint] NULL,
	[StrLineMTDEarnedRev] [decimal](18, 2) NULL,
	[StrLinePrevJTDEarnedRev] [decimal](18, 2) NULL,
	[CurrEarnedRevenue] [decimal](18, 2) NULL,
	[PrevEarnedRevenue] [decimal](18, 2) NULL,
	[YTDEarnedRev] [decimal](18, 2) NULL,
	[OriginalCost] [decimal](18, 2) NULL,
	[CurrentEstCost] [decimal](18, 2) NULL,
	[JTDActualCost] [decimal](18, 2) NULL,
	[ProjectedCost] [decimal](18, 2) NULL,
	[CostIsOverride] [char](1) NULL,
	[OverrideCostTotal] [decimal](18, 2) NULL,
	[CostOverridePercent] [decimal](18, 15) NULL,
	[OverrideCost] [decimal](37, 17) NULL,
	[CommittedCost] [decimal](18, 2) NULL,
	[CostWIPAmount] [decimal](37, 17) NULL,
	[CurrMonthCost] [decimal](18, 2) NULL,
	[PrevCost] [decimal](18, 2) NULL,
	[YTDActualCost] [decimal](18, 2) NULL,
	[RevenueProcessedOn] [datetime] NULL,
	[CostProcessedOn] [datetime] NULL,
	[ProjFinalGM] [numeric](38, 17) NULL,
	[EstimatedCostToComplete] [decimal](38, 17) NULL,
	[JTDEarnedRev] [numeric](38, 8) NULL,
	[PercentComplete] [numeric](18, 10) NULL,
	[MTDEarnedRev] [decimal](19, 2) NULL,
	[MTDActualCost] [decimal](19, 2) NULL,
	[ContractIsPositive] bit NULL,
	[ProjFinalGMPerc] DECIMAL(18,10) NULL,
	[JTDEarnedGM] [decimal](18, 2) NULL,
	[Overbilled] [decimal](18, 2) NULL,
	[Underbilled] [decimal](18, 2) NULL,
	[Department] VARCHAR(5) NULL
)
go

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckWipArchive_ThroughMonth_JCCo_Contract_WorkOrder_GLDepartment_RevenueType_IsLocked_POC')
    DROP INDEX IX_mckWipArchive_ThroughMonth_JCCo_Contract_WorkOrder_GLDepartment_RevenueType_IsLocked_POC ON 
dbo.mckWipArchive;
GO
CREATE NONCLUSTERED INDEX IX_mckWipArchive_ThroughMonth_JCCo_Contract_WorkOrder_GLDepartment_RevenueType_IsLocked_POC
    ON dbo.mckWipArchive (ThroughMonth, JCCo, Contract, WorkOrder, GLDepartment, RevenueType, IsLocked, POC);
GO

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckWipArchive_ThroughMonth_JCCo')
    DROP INDEX IX_mckWipArchive_ThroughMonth_JCCo ON 
dbo.mckWipArchive;
GO
CREATE NONCLUSTERED INDEX IX_mckWipArchive_ThroughMonth_JCCo
    ON dbo.mckWipArchive (ThroughMonth, JCCo);
GO

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckWipArchive_ThroughMonth_JCCo_Contract')
    DROP INDEX IX_mckWipArchive_ThroughMonth_JCCo_Contract ON 
dbo.mckWipArchive;
GO
CREATE NONCLUSTERED INDEX IX_mckWipArchive_ThroughMonth_JCCo_Contract
    ON dbo.mckWipArchive (ThroughMonth, JCCo, Contract);
GO

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckWipArchive_ThroughMonth_JCCo_WorkOrder')
    DROP INDEX IX_mckWipArchive_ThroughMonth_JCCo_WorkOrder ON 
dbo.mckWipArchive;
GO
CREATE NONCLUSTERED INDEX IX_mckWipArchive_ThroughMonth_JCCo_WorkOrder
    ON dbo.mckWipArchive (ThroughMonth, JCCo, WorkOrder);
GO

GRANT SELECT ON dbo.mckWipArchive TO [public]
GO