--DROP TABLE mckWipCostByJobData
IF EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='mckWipCostByJobData')
BEGIN
	PRINT 'DROP TABLE mckWipCostByJobData'
	DROP TABLE dbo.mckWipCostByJobData
END
go

--create table mckWipCostByJobData
PRINT 'CREATE TABLE mckWipCostByJobData'
go
CREATE TABLE dbo.mckWipCostByJobData
(
	ThroughMonth			SMALLDATETIME	null
,	JCCo					TINYINT			null
,	Contract				VARCHAR(10)		NULL
,	ContractDesc			VARCHAR(60)  	NULL
,	Job						VARCHAR(10)		NULL
,	IsLocked				CHAR(1)			NULL --bYN			
,	RevenueType				varchar(10)		null
,	RevenueTypeName			VARCHAR(60)		null
,	ContractStatus			varchar(10)		null
,	ContractStatusDesc		VARCHAR(60)		null
,	GLDepartment			VARCHAR(4)		null
,	GLDepartmentName		VARCHAR(60)		null
,	POC						INT				NULL --bEmployee		
,	POCName					VARCHAR(60)		null
,	OriginalCost			decimal(18,2)	null
,	CurrentEstCost			decimal(18,2)	null
,	CurrentCost				decimal(18,2)	null
,	ProjectedCost			decimal(18,2)	null
,	CommittedCost			decimal(18,2)	null
,	ProcessedOn				DateTime		null
)

IF EXISTS (SELECT name FROM sys.indexes
           WHERE name = N'IX_mckWipCostByJobData_ThroughMonth_JCCo_Contract_GLDepartment_RevenueType_IsLocked_POC')
    DROP INDEX IX_mckWipCostByJobData_ThroughMonth_JCCo_Contract_GLDepartment_RevenueType_IsLocked_POC ON dbo.mckWipCostByJobData;
GO
CREATE NONCLUSTERED INDEX IX_mckWipCostByJobData_ThroughMonth_JCCo_Contract_GLDepartment_RevenueType_IsLocked_POC
    ON dbo.mckWipCostByJobData (ThroughMonth, JCCo, Contract, GLDepartment, RevenueType, IsLocked, POC);
GO

GRANT SELECT ON dbo.mckWipCostByJobData TO [public]
GO