--DROP TABLE mckWipCostData
IF EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='mckWipCostData')
BEGIN
	PRINT 'DROP TABLE mckWipCostData'
	DROP TABLE dbo.mckWipCostData
END
go

--create table mckWipCostData
PRINT 'CREATE TABLE mckWipCostData'
go
CREATE TABLE dbo.mckWipCostData
(
	ThroughMonth			SMALLDATETIME	null
,	JCCo					TINYINT			null
,	Contract				VARCHAR(10)		NULL
,	ContractDesc			VARCHAR(60)  	NULL
,	WorkOrder				INT				null
,	IsLocked				CHAR(1)			NULL	--bYN			
,	RevenueType				varchar(10)		null
,	RevenueTypeName			VARCHAR(60)		null
,	ContractStatus			varchar(10)		null
,	ContractStatusDesc		VARCHAR(60)		null
,	GLDepartment			VARCHAR(4)		null
,	GLDepartmentName		VARCHAR(60)		null
,	POC						INT				NULL	--bEmployee
,	POCName					VARCHAR(60)		null
,	OriginalCost			decimal(18,2)	null
,	CurrentCost				decimal(18,2)	null	
,	CurrentEstCost			decimal(18,2)	null
,	CurrMonthCost			decimal(18,2)	null	
,	PrevCost				decimal(18,2)	null	
,	ProjectedCost			decimal(18,2)	null	
,	CostIsOverride			CHAR(1)			NULL	--bYN
,	OverrideCostTotal		decimal(18,2)	null
,	CostOverridePercent		decimal(18,15)	NULL
,	OverrideCost			decimal(18,2)	NULL
,	CommittedCost			decimal(18,2)	null
,	ProcessedOn				DateTime		null
)
GO

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckWipCostData_ThroughMonth_JCCo_Contract_WorkOrder_GLDepartment_RevenueType_IsLocked_POC')
    DROP INDEX IX_mckWipCostData_ThroughMonth_JCCo_Contract_WorkOrder_GLDepartment_RevenueType_IsLocked_POC ON dbo.mckWipCostData;
GO
CREATE NONCLUSTERED INDEX IX_mckWipCostData_ThroughMonth_JCCo_Contract_WorkOrder_GLDepartment_RevenueType_IsLocked_POC
    ON dbo.mckWipCostData (ThroughMonth, JCCo, Contract, WorkOrder, GLDepartment, RevenueType, IsLocked, POC);
GO

GRANT SELECT ON dbo.mckWipCostData TO [public]
GO