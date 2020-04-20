--DROP TABLE mckWipRevenueData
IF EXISTS ( SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND 
TABLE_NAME='mckWipRevenueData')
BEGIN
	PRINT 'DROP TABLE mckWipRevenueData'
	DROP TABLE dbo.mckWipRevenueData
END
go

--create table mckWipRevenueData
PRINT 'CREATE TABLE mckWipRevenueData'
go
CREATE TABLE dbo.mckWipRevenueData
(
	ThroughMonth			SMALLDATETIME	null
,	JCCo					TINYINT			null
,	Contract				VARCHAR(10)		NULL
,	ContractDesc			VARCHAR(60)  	null
,	CGCJobNumber			VARCHAR(20)		null
,	WorkOrder				INT				null
,	IsLocked				CHAR(1)			NULL --bYN		
,	RevenueType				varchar(10)		null
,	RevenueTypeName			VARCHAR(60)		null
,	ContractStatus			varchar(10)		null
,	ContractStatusDesc		VARCHAR(60)		null
,	GLDepartment			VARCHAR(4)		null
,	GLDepartmentName		VARCHAR(60)		null
,	POC						INT				NULL --bEmployee		
,	POCName					VARCHAR(60)		null
,	OrigContractAmt			decimal(18,2)	null
,	CurrContractAmt			decimal(18,2)	null
,	CurrEarnedRevenue		decimal(18,2)	null
,	PrevEarnedRevenue		decimal(18,2)	null
,	ProjContractAmt			decimal(18,2)	null	
,	RevenueIsOverride		CHAR(1)			NULL --bYN			
,	OverrideRevenueTotal	decimal(18,2)	null
,	RevenueOverridePercent	decimal(18,15)	NULL
,	RevenueOverrideAmount	decimal(18,2)	NULL
,	CurrentBilledAmount		decimal(18,2)	null
,	RevenueWIPAmount		decimal(18,2)	null
,	SalesPersonID			INT				NULL --bEmployee		
,	SalesPerson				varchar(30)		null
,	VerticalMarket			varchar(255)	null
,	MarkUpRate				numeric(8,6)	null
,	StrLineTermStart		SMALLDATETIME	null
,	StrLineTerm				tinyint			null
,	StrLineMTDEarnedRev		decimal(18,2)	null
,	StrLinePrevJTDEarnedRev	decimal(18,2)	null
,	ProcessedOn				DateTime		null
,	Department				VARCHAR(5)		null
)
go

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckWipRevenueData_ThroughMonth_JCCo_Contract_WorkOrder_GLDepartment_RevenueType_IsLocked_POC')
    DROP INDEX IX_mckWipRevenueData_ThroughMonth_JCCo_Contract_WorkOrder_GLDepartment_RevenueType_IsLocked_POC ON 
dbo.mckWipRevenueData;
GO
CREATE NONCLUSTERED INDEX IX_mckWipRevenueData_ThroughMonth_JCCo_Contract_WorkOrder_GLDepartment_RevenueType_IsLocked_POC
    ON dbo.mckWipRevenueData (ThroughMonth, JCCo, Contract, WorkOrder, GLDepartment, RevenueType, IsLocked, POC);
GO

GRANT SELECT ON dbo.mckWipRevenueData TO [public]
GO