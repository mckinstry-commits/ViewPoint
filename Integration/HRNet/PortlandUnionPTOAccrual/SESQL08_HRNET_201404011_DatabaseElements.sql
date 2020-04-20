USE HRNET
go

--TODO:
--Get Manual Entries working. ?? Trigger ?? 
--Change DNN Queries to use new [LogicalKey] and set session variables OnClick to allow cross page navigation.
--Create local Function to Contain iSeries call outside of the core procedure


/*  SECURITY AND LINKED SERVER PRE-REQUISITES */
--sp_dropuser nsproportaluser
/****** Object:  Login [nsproportaluser]    Script Date: 04/03/2014 14:56:04 ******/
--CREATE LOGIN [nsproportaluser] WITH PASSWORD=N'LCKZPR1z4m5HBtyUHZA2', DEFAULT_DATABASE=[HRNET], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
--CREATE USER [nsproportaluser] FOR LOGIN [nsproportaluser] WITH DEFAULT_SCHEMA=[mnepto]

--IF EXISTS ( SELECT * FROM sys.schemas WHERE name='mnepto')
--BEGIN
--	PRINT 'SCHEMA [mnepto] Exists'
--END
--ELSE
--BEGIN
--	PRINT 'CREATE SCHEMA [mnepto]'
--	--CREATE SCHEMA [mnepto] AUTHORIZATION dbo
--END
--go

/*
/****** Object:  LinkedServer [SESQL08]    Script Date: 04/05/2014 11:28:33 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'SESQL08', @srvproduct=N'SQL Server'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'SESQL08',@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL
EXEC master.dbo.sp_serveroption @server=N'SESQL08', @optname=N'collation compatible', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'SESQL08', @optname=N'data access', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'SESQL08', @optname=N'dist', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'SESQL08', @optname=N'pub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'SESQL08', @optname=N'rpc', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'SESQL08', @optname=N'rpc out', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'SESQL08', @optname=N'sub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'SESQL08', @optname=N'connect timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'SESQL08', @optname=N'collation name', @optvalue=null
EXEC master.dbo.sp_serveroption @server=N'SESQL08', @optname=N'lazy schema validation', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'SESQL08', @optname=N'query timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'SESQL08', @optname=N'use remote collation', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'SESQL08', @optname=N'remote proc transaction promotion', @optvalue=N'true'
*/
--BEGIN REBUILD

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='AccrualSettings' AND TABLE_SCHEMA='mnepto')
BEGIN
	PRINT 'DROP TABLE [mnepto].[AccrualSettings]'
	DROP TABLE [mnepto].[AccrualSettings]
END
go

PRINT 'CREATE TABLE [mnepto].[AccrualSettings]'
go

CREATE TABLE [mnepto].[AccrualSettings](
	[GroupIdentifier]		[varchar](3)	NOT NULL,
	[GroupDescription]		[varchar](30)	NOT NULL,
	[EffectiveDate]			datetime		NOT NULL,
	[UseIdentifier]			[varchar](3)	NOT NULL,
	[EligibleWorkDays]		[int]			NOT NULL,
	[EligibleWorkHours]		[int]			NOT NULL,
	[AllowedGapInService]	[int]			NOT NULL,
	[AccrualRatePerSet]		[int]			NOT NULL,
	[AccrualSet]			[int]			NOT NULL,
	[MaxAccrual]			[int]			NOT NULL	
)
go

ALTER TABLE [mnepto].[AccrualSettings] ADD  CONSTRAINT [PK_mnepto_AccrualSettings] PRIMARY KEY CLUSTERED 
(
	[GroupIdentifier] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

PRINT 'Populate [mnepto].[AccrualSettings]'
INSERT [mnepto].[AccrualSettings] SELECT '38','Portland City Ordinance','1/1/2014','38',90,240,180,1,30,40
go


IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Personnel' AND TABLE_SCHEMA='mnepto')
BEGIN
	PRINT 'DROP TABLE [mnepto].[Personnel]'
	DROP TABLE [mnepto].[Personnel]
END
go

PRINT 'CREATE TABLE [mnepto].[Personnel]'
go

CREATE TABLE [mnepto].[Personnel]
(
	CompanyNumber	int			NOT NULL 
,	EmployeeNumber	int			NOT NULL
,	EmployeeName	varchar(50)	NOT NULL
,	EmployeeDept	varchar(10)	NOT NULL
,	EmployeeClass	varchar(10)	NOT NULL
,	EmployeeType	varchar(10)	NOT NULL
,	EmployeeUnion	varchar(10)	NOT NULL
,	EmployeeUnionName VARCHAR(30) NOT null
,	EmployeeStatus	varchar(5)	NOT NULL
,	EmployeeExemptClassification	varchar(20)	NOT NULL 
,	LogicalKey AS CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10))
)
GO

ALTER TABLE [mnepto].[Personnel] ADD  CONSTRAINT [PK_mnepto_Personnel] PRIMARY KEY CLUSTERED 
(
	[CompanyNumber] ASC
,	[EmployeeNumber] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

--SELECT * FROM mnepto.TimeCardHistory WHERE EmployeeNumber=68221
--SELECT * FROM mnepto.TimeCardManualEntries WHERE EmployeeNumber=68221
--SELECT * FROM mnepto.TimeCardAggregateView WHERE EmployeeName LIKE '%OREBA%'

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='AccrualSummary' AND TABLE_SCHEMA='mnepto')
BEGIN
	PRINT 'DROP TABLE [mnepto].[AccrualSummary]'
	DROP TABLE [mnepto].[AccrualSummary]
END
go

PRINT 'CREATE TABLE [mnepto].[AccrualSummary]'
go

CREATE TABLE [mnepto].[AccrualSummary]
(
	[CompanyNumber]			[int] NOT NULL,
	[EmployeeNumber]		[int] NOT NULL,
	[Year]					[char](4) NOT NULL,
	[GroupIdentifier]		[varchar](3) NOT NULL,
	[EffectiveWorkDays]		[int] NULL,
	[EffectiveStartDate]	[datetime] NULL,
	[EligibleStatus]		[varchar](30) NOT NULL,
	[AccumulatedHours]		[decimal](18, 3) NOT NULL,
	[PrevCarryOverPTOHours] [decimal](4, 2) NOT NULL,
	[AccruedPTOHours]		[decimal](4, 2) NOT NULL,
	[UsedPTOHours]			[decimal](4, 2) NOT NULL,
	[AvailablePTOHours]		as CASE WHEN [EligibleStatus]='E' THEN ([AccruedPTOHours] + [PrevCarryOverPTOHours]) - [UsedPTOHours] ELSE 0 END,
	[RunDate]				[datetime] NOT NULL,
	LogicalKey AS CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10))	 + '.' + CAST([GroupIdentifier] AS VARCHAR(10))  + '.' + CAST([Year] AS VARCHAR(10)),
	EmployeeLogicalKey AS CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10))
)
GO

ALTER TABLE [mnepto].[AccrualSummary] ADD  CONSTRAINT [PK_mnepto_AccrualSummary] PRIMARY KEY CLUSTERED 
(
	[CompanyNumber] ASC
,	[EmployeeNumber] ASC
,	[Year] ASC
,	[GroupIdentifier] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='TimeCardHistory' AND TABLE_SCHEMA='mnepto')
BEGIN
	PRINT 'DROP TABLE [mnepto].[TimeCardHistory]'
	DROP TABLE [mnepto].[TimeCardHistory]
END
go

PRINT 'CREATE TABLE [mnepto].[TimeCardHistory]'
GO

CREATE TABLE [mnepto].[TimeCardHistory]
(
	CompanyNumber	int				NOT NULL 
,	EmployeeNumber	int				NOT NULL
,	RegularHours	[numeric](5, 2) NOT NULL
,	OvertimeHours	[numeric](5, 2) NOT NULL
,	OtherHours		[numeric](5, 2)	NOT NULL
,	OtherHoursType	[varchar](10)	NOT NULL
,	TotalHours AS [RegularHours]+[OvertimeHours]+[OtherHours]
,	WeekEnding		[numeric](8, 0) NOT NULL
,	[Year] AS CAST(WeekEnding/10000 AS INT)
,	GroupID			[numeric](2, 0) NOT NULL
,	LogicalKey AS CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10))	 + '.' + CAST(COALESCE([GroupID],[OtherHoursType]) AS VARCHAR(10))  + '.' + CAST(CAST(WeekEnding/10000 AS INT) AS VARCHAR(10))
,	EmployeeLogicalKey AS CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10))
) 
GO

PRINT 'Populate [mnepto].[TimeCardHistory]'
go

INSERT [mnepto].[TimeCardHistory]
(
	CompanyNumber	--int				NOT NULL 
,	EmployeeNumber	--int				NOT NULL
,	RegularHours	--[numeric](5, 2) NOT NULL
,	OvertimeHours	--[numeric](5, 2) NOT NULL
,	OtherHours		--[numeric](5, 2)	NOT NULL
,	OtherHoursType	--[varchar](10)	NOT NULL
--,	TotalHours AS [RegularHours]+[OvertimeHours]+[OtherHours]
,	WeekEnding		--[numeric](8, 0) NOT NULL
,	GroupID			--[numeric](2, 0) NOT NULL
)
SELECT 
	tch.CHCONO
,	tch.CHEENO
,	tch.CHRGHR
,	tch.CHOVHR
,	tch.CHOTHR
,	tch.CHOTTY
,	tch.CHDTWE
,	tch.CHCRNO
FROM 
	CMS.S1017192.BILLO.PRPTCHS tch 
go

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='TimeCardManualEntries' AND TABLE_SCHEMA='mnepto')
BEGIN
	PRINT 'DROP TABLE [mnepto].[TimeCardManualEntries]'
	DROP TABLE [mnepto].[TimeCardManualEntries]
END
go

PRINT 'CREATE TABLE [mnepto].[TimeCardManualEntries]'
go

CREATE TABLE [mnepto].[TimeCardManualEntries]
(
	[RowId]	INT	NOT NULL IDENTITY,
	[CompanyNumber] [numeric](2, 0) NOT NULL,
	[EmployeeNumber] [numeric](5, 0) NOT NULL,
	[EmployeeName] [char](25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[WeekEnding] [numeric](8, 0) NOT NULL,
	[Year] AS CAST(WeekEnding/10000 AS INT),
	[GroupID] [numeric](2, 0) NULL,
	[RegularHours] [numeric](5, 2) DEFAULT 0 NOT NULL,
	[OvertimeHours] [numeric](5, 2) DEFAULT 0 NOT NULL,
	[OtherHours] [numeric](5, 2) DEFAULT 0 NOT NULL,
	[OtherHoursType] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TotalHours] AS [RegularHours]+[OvertimeHours]+[OtherHours],
	LogicalKey AS CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10))	 + '.' + CAST(COALESCE([GroupID],[OtherHoursType]) AS VARCHAR(10))  + '.' + CAST(CAST(WeekEnding/10000 AS INT) AS VARCHAR(10)),
	EmployeeLogicalKey AS CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10)),
	InitialLoad		int NOT NULL DEFAULT 0
) 
go

ALTER TABLE [mnepto].[TimeCardManualEntries] ADD  CONSTRAINT [PK_mnepto_TimeCardManualEntries] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/*
Adding and updatable view to the dbo Schema as a workaround to the Onyaktech Data Viewer issue of not being able to add/update/delete
when teh Table is in a non-dbo schema.
*/
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME='mvwTimeCardManualEntries' AND TABLE_SCHEMA='dbo')
BEGIN
	PRINT 'DROP VIEW [dbo].[mvwTimeCardManualEntries]'
	DROP VIEW [dbo].[mvwTimeCardManualEntries]
END
go

PRINT 'CREATE VIEW [dbo].[mvwTimeCardManualEntries]'
go

CREATE VIEW [dbo].[mvwTimeCardManualEntries]
AS
SELECT [RowId]
      ,[CompanyNumber]
      ,[EmployeeNumber]
      ,[EmployeeName]
      ,[WeekEnding]
      ,[Year]
      ,[GroupID]
      ,[RegularHours]
      ,[OvertimeHours]
      ,[OtherHours]
      ,[OtherHoursType]
      ,[TotalHours]
      ,[LogicalKey]
      ,[EmployeeLogicalKey]
      ,[InitialLoad]
  FROM [mnepto].[TimeCardManualEntries]
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME='mvwActiveEmployees' AND TABLE_SCHEMA='mnepto')
BEGIN
	PRINT 'DROP VIEW [mnepto].[mvwActiveEmployees]'
	DROP VIEW [mnepto].[mvwActiveEmployees]
END
go

PRINT 'CREATE VIEW [mnepto].[mvwActiveEmployees]'
go

CREATE VIEW [mnepto].[mvwActiveEmployees]
AS
SELECT
	PEOPLE_ID
,	REFERENCENUMBER
,	KNOWNAS
,	FIRSTNAME
,	LASTNAME
,	EMAILPRIMARY
,	EMAILSECONDARY
,	STATUS
FROM 
	dbo.PEOPLE

GO

GRANT SELECT ON [mnepto].[mvwActiveEmployees] TO nsproportaluser
go

PRINT 'Populate [mnepto].[TimeCardManualEntries]'
go

--DECLARE @tmpRowId INT
--SELECT @tmpRowId=0


insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 184,'',20140112,38,36,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 184,'',20140119,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 184,'',20140126,38,41,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 184,'',20140202,38,42,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 184,'',20140209,38,37,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 184,'',20140216,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 185,'',20140112,38,4,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 188,'',20140112,38,45,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 188,'',20140119,38,30,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 188,'',20140126,38,44,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 188,'',20140105,38,18,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 188,'',20140202,38,35,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 188,'',20140209,38,30,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 190,'',20140112,38,4,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 190,'',20140119,38,2,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 195,'',20140112,38,24,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 195,'',20140119,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 195,'',20140126,38,27,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 195,'',20140202,38,10,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 195,'',20140209,38,11,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 195,'',20140216,38,13.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 352,'',20140126,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 352,'',20140202,38,42,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 352,'',20140209,38,36,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 352,'',20140216,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 394,'',20140202,38,5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 426,'',20140119,38,24,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 426,'',20140126,38,26,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 426,'',20140209,38,2.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 426,'',20140216,38,46,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 444,'',20140112,38,18.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 444,'',20140119,38,44,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 444,'',20140105,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 444,'',20140202,38,21.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 444,'',20140209,38,19,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 444,'',20140216,38,28,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 465,'',20140112,38,3,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 465,'',20140209,38,10,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 465,'',20140216,38,14,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 750,'',20140119,38,11,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 750,'',20140126,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 750,'',20140105,38,17,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 750,'',20140202,38,11,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 750,'',20140209,38,9,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 750,'',20140216,38,7,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 838,'',20140112,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 838,'',20140119,38,4,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 838,'',20140126,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 838,'',20140105,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 838,'',20140202,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 838,'',20140209,38,4,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 838,'',20140216,38,4,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 845,'',20140112,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 845,'',20140119,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 845,'',20140126,38,42,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 845,'',20140105,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 845,'',20140202,38,42,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 845,'',20140209,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 845,'',20140216,38,51,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 952,'',20140119,38,2.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 958,'',20140112,38,37.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 958,'',20140119,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 958,'',20140126,38,35,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 958,'',20140105,38,9.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 958,'',20140202,38,21,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 958,'',20140209,38,10,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 958,'',20140216,38,36,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 984,'',20140112,38,12,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 984,'',20140119,38,25,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 984,'',20140126,38,7,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 984,'',20140105,38,20,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 984,'',20140202,38,16.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 984,'',20140209,38,8.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1003,'',20140112,38,9.25,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1003,'',20140119,38,24,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1003,'',20140126,38,30.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1003,'',20140105,38,2.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1003,'',20140202,38,29.75,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1003,'',20140209,38,7.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1003,'',20140216,38,18,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1123,'',20140112,38,11.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1123,'',20140119,38,20.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1123,'',20140126,38,29,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1123,'',20140105,38,31,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1123,'',20140216,38,20,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1125,'',20140112,38,2.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1125,'',20140119,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1125,'',20140126,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1125,'',20140202,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1125,'',20140209,38,12,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1125,'',20140216,38,2,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1139,'',20140126,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1139,'',20140202,38,18,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1301,'',20140216,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1302,'',20140112,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1302,'',20140119,38,50,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1302,'',20140126,38,13,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1302,'',20140105,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1302,'',20140202,38,33,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1302,'',20140209,38,17,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1311,'',20140112,38,48,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1311,'',20140119,38,50,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1311,'',20140126,38,49,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1311,'',20140105,38,20,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1311,'',20140202,38,50,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1311,'',20140209,38,44,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1311,'',20140216,38,60,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1356,'',20140112,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1356,'',20140119,38,17.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1356,'',20140126,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1356,'',20140202,38,37.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1356,'',20140209,38,33,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1356,'',20140216,38,30,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1380,'',20140119,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1380,'',20140126,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1380,'',20140105,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1380,'',20140202,38,6,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1380,'',20140209,38,14,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1380,'',20140216,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1460,'',20140119,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1513,'',20140119,38,9,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1513,'',20140105,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1552,'',20140112,38,28.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1552,'',20140119,38,27.25,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1552,'',20140126,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1552,'',20140105,38,6.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1552,'',20140202,38,20,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1552,'',20140209,38,13.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1656,'',20140119,38,3,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1728,'',20140209,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1728,'',20140216,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1755,'',20140216,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1950,'',20140112,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1950,'',20140119,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1950,'',20140126,38,42,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1950,'',20140202,38,37,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1950,'',20140209,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 1950,'',20140216,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2014,'',20140126,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2014,'',20140202,38,10,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2026,'',20140126,38,24,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2026,'',20140202,38,25,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2026,'',20140209,38,14,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2026,'',20140216,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2032,'',20140119,38,9,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2038,'',20140112,38,21,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2038,'',20140119,38,33,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2038,'',20140126,38,22,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2038,'',20140202,38,39.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2038,'',20140209,38,34.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2038,'',20140216,38,35,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2051,'',20140112,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2051,'',20140119,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2051,'',20140126,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2051,'',20140105,38,26,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2051,'',20140202,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2051,'',20140209,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2051,'',20140216,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2073,'',20140216,38,7,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2076,'',20140112,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2076,'',20140119,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2076,'',20140126,38,6,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2076,'',20140105,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2076,'',20140202,38,15,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2094,'',20140119,38,21,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2094,'',20140105,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2094,'',20140216,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2843,'',20140202,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2843,'',20140209,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 2843,'',20140216,38,33,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 6271,'',20140112,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 6271,'',20140119,38,23,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 6271,'',20140126,38,31,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 6271,'',20140105,38,24,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 6271,'',20140209,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 6271,'',20140216,38,21.75,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 16744,'',20140112,38,35,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 16744,'',20140119,38,41,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 16744,'',20140126,38,26.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 16744,'',20140105,38,17,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 16744,'',20140202,38,44,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 16744,'',20140209,38,43,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 16744,'',20140216,38,24.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 17121,'',20140119,38,1,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 19278,'',20140112,38,28.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 19278,'',20140119,38,35,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 19278,'',20140126,38,34,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 19278,'',20140105,38,14,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 19278,'',20140202,38,63.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 19278,'',20140209,38,26,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 19278,'',20140216,38,35,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 20421,'',20140112,38,24,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 20421,'',20140126,38,1,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 29732,'',20140209,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 29732,'',20140216,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 32431,'',20140112,38,2,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 32431,'',20140119,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 32431,'',20140126,38,10,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 32431,'',20140105,38,2,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 32431,'',20140202,38,10,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 32431,'',20140209,38,14,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 32431,'',20140216,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 34833,'',20140112,38,2,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 34833,'',20140119,38,30.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 34833,'',20140126,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 34833,'',20140105,38,20,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 34833,'',20140202,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 34833,'',20140209,38,23,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 34833,'',20140216,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 36201,'',20140119,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 36201,'',20140126,38,4,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 36201,'',20140105,38,5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 36201,'',20140202,38,5.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 36227,'',20140112,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 36227,'',20140119,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 36227,'',20140126,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 36227,'',20140105,38,10,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 36227,'',20140202,38,30,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 36227,'',20140209,38,30,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 36227,'',20140216,38,45.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 46306,'',20140112,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 46306,'',20140119,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 46306,'',20140126,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 46306,'',20140202,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 46306,'',20140209,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 46306,'',20140216,38,50,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 49681,'',20140112,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 49681,'',20140126,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 49681,'',20140105,38,26,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 49681,'',20140202,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 49681,'',20140209,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 49681,'',20140216,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 51677,'',20140119,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 51677,'',20140126,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 51677,'',20140105,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 51677,'',20140209,38,41,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 51677,'',20140216,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 51942,'',20140112,38,5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 52931,'',20140112,38,29,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 52931,'',20140119,38,13.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 52931,'',20140126,38,47,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 52931,'',20140105,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 52931,'',20140202,38,14,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 52931,'',20140209,38,18,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 61977,'',20140112,38,36,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 61977,'',20140119,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 61977,'',20140126,38,38,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 61977,'',20140105,38,21,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 61977,'',20140202,38,25.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 61977,'',20140209,38,24,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 61977,'',20140216,38,44,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 64714,'',20140119,38,4,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 64714,'',20140202,38,10,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 64714,'',20140209,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 64714,'',20140216,38,43,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 65808,'',20140126,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 65808,'',20140202,38,6,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 65808,'',20140216,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 68194,'',20140112,38,47,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 68194,'',20140119,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 68194,'',20140126,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 68194,'',20140202,38,48,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 68194,'',20140209,38,48,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 68194,'',20140216,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 70324,'',20140112,38,29.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 70324,'',20140119,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 70324,'',20140126,38,20,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 70324,'',20140105,38,20,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 70324,'',20140202,38,36,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 70324,'',20140209,38,31,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 70324,'',20140216,38,46,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 72616,'',20140112,38,10,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 72616,'',20140119,38,10,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 72616,'',20140126,38,24,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 72616,'',20140105,38,3,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 72616,'',20140202,38,18,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 72616,'',20140209,38,12,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 72616,'',20140216,38,24,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 76263,'',20140112,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 76263,'',20140119,38,36,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 76263,'',20140126,38,39,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 76263,'',20140202,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 76263,'',20140209,38,24.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 76263,'',20140216,38,19.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 78861,'',20140112,38,14,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 78861,'',20140119,38,22,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 78861,'',20140105,38,15,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 78861,'',20140202,38,17,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 78861,'',20140209,38,14,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 78861,'',20140216,38,14,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 79388,'',20140216,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 82691,'',20140112,38,56,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 82691,'',20140119,38,56,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 82691,'',20140126,38,52,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 82881,'',20140119,38,5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 84859,'',20140112,38,13,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 84859,'',20140119,38,17,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 84859,'',20140105,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 84859,'',20140202,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 84859,'',20140209,38,6,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 84859,'',20140216,38,7,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 86026,'',20140112,38,24,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 86026,'',20140126,38,33,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 86026,'',20140105,38,8,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 86026,'',20140202,38,38,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 86026,'',20140209,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 86026,'',20140216,38,29,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 89278,'',20140112,38,17.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 89278,'',20140119,38,34,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 89278,'',20140126,38,39,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 89278,'',20140105,38,23,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 89278,'',20140202,38,36.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 89278,'',20140209,38,29.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 89278,'',20140216,38,28,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95034,'',20140126,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95034,'',20140202,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95034,'',20140209,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95034,'',20140216,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95037,'',20140112,38,41.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95037,'',20140119,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95037,'',20140126,38,54,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95037,'',20140105,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95037,'',20140202,38,47,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95037,'',20140209,38,38,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95037,'',20140216,38,55,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95078,'',20140112,38,13.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95078,'',20140119,38,26.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95078,'',20140126,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95078,'',20140105,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95078,'',20140202,38,40,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95078,'',20140209,38,21.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95078,'',20140216,38,32,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95245,'',20140112,38,31.5,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95245,'',20140119,38,17,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95245,'',20140126,38,35,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95245,'',20140202,38,38,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95335,'',20140112,38,35,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95335,'',20140119,38,23,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95335,'',20140105,38,16,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95335,'',20140202,38,13.75,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95335,'',20140209,38,20,0,0,''

insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 95335,'',20140216,38,16,0,0,''


insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, -1,'PLACEHOLDER',20140105,38,0,0,0,'38'

--insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 68221,'',20140216,38,23,0,0,null

--insert [mnepto].[TimeCardManualEntries] ( CompanyNumber, EmployeeNumber, EmployeeName, WeekEnding, GroupID, RegularHours, OvertimeHours, OtherHours, OtherHoursType )  select /*@tmpRowId,*/ 1, 68221,'',20140223,null,0,0,4,'38'
go

UPDATE [mnepto].[TimeCardManualEntries] SET 
	[EmployeeName]= e.MNM25
from CMS.S1017192.CMSFIL.PRPMST e 
WHERE 
	TimeCardManualEntries.[CompanyNumber]=e.MCONO
AND e.MDVNO=0
AND TimeCardManualEntries.[EmployeeNumber]=e.MEENO
AND [EmployeeName]=''
GO

UPDATE mnepto.TimeCardManualEntries SET InitialLoad=1 WHERE RowId NOT IN (343,344,345)
go

PRINT 'Populate [mnepto].[Personnel]'
go
-- LWO
INSERT [mnepto].[Personnel]
(
	CompanyNumber	--int			NOT NULL 
,	EmployeeNumber	--int			NOT NULL
,	EmployeeName	--varchar(50)	NOT NULL
,	EmployeeDept	--varchar(10)	NOT NULL
,	EmployeeClass	--varchar(10)	NOT NULL
,	EmployeeType	--varchar(10)	NOT NULL
,	EmployeeUnion	--varchar(10)	NOT NULL
,	EmployeeUnionName
,	EmployeeStatus	--varchar(5)	NOT NULL
,	EmployeeExemptClassification	--varchar(20)	NOT NULL 
)

SELECT
	prpmst.MCONO
,	prpmst.MEENO
,	prpmst.MNM25
,	SUBSTRING(CAST(prplbr.LGLAN AS CHAR(15)),5,3)  --prpmst.MSDDP  -- TODO: Chage view on iSeries to get GL Dept, not PR Dept
,	prpmst.MEECL
,	prpmst.MEETY
,	prpmst.MUNNO
,	coalesce(prpunm.QD15A,prpmst.MUNNO)
,	prpmst.MSTAT
,	COALESCE(p.EXEMPTSTATUS,'Unknown')
FROM 
	CMS.S1017192.CMSFIL.PRPMST prpmst LEFT OUTER JOIN
	CMS.S1017192.CMSFIL.PRPLBR prplbr ON
		prpmst.MCONO=prplbr.LCONO
	AND prpmst.MDVNO=prplbr.LDVNO
	AND prpmst.MSDDP=prplbr.LDPNO LEFT OUTER JOIN
	CMS.S1017192.CMSFIL.PRPUNM prpunm ON
		prpmst.MCONO=prpunm.QCONO
	AND prpmst.MDVNO=prpunm.QDVNO
	AND prpmst.MUNNO=prpunm.QUNNO
	AND prpunm.QUDTY=0
	AND LTRIM(RTRIM(prpunm.QJBNO)) = ''
	AND LTRIM(RTRIM(prpunm.QSJNO)) = '' LEFT OUTER JOIN
	[mnepto].[mvwActiveEmployees] /* dbo.PEOPLE */ e ON
		CAST(prpmst.MEENO AS NVARCHAR(10))=e.REFERENCENUMBER 
	AND e.STATUS = 'A' LEFT OUTER JOIN
	dbo.JOBDETAIL jd ON
		e.PEOPLE_ID=jd.PEOPLE_ID 
	AND jd.TOPJOB='T' LEFT OUTER JOIN
	dbo.POST p ON
		jd.JOBTITLE=p.POST_ID	
WHERE
(
(	prpmst.MSTAT='A'
AND prpmst.MCONO IN (1,15,20,30,50,60)
AND p.EXEMPTSTATUS = 'NonExempt' )

OR 	CAST(prpmst.MCONO AS VARCHAR(5)) + '.' + CAST(prpmst.MEENO AS VARCHAR(10)) IN
	(
		SELECT DISTINCT CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10)) FROM mnepto.TimeCardManualEntries
	)
)
AND CAST(prpmst.MCONO AS VARCHAR(5)) + '.' + CAST(prpmst.MEENO AS VARCHAR(10)) NOT IN (
	SELECT DISTINCT CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10)) FROM mnepto.Personnel
)

/*
SELECT
	prpmst.MCONO
,	prpmst.MEENO
,	prpmst.MNM25
,	prpmst.MSDDP
,	prpmst.MEECL
,	prpmst.MEETY
,	prpmst.MUNNO
,	COALESCE(prpunm.QD15A,prpmst.MUNNO)
,	prpmst.MSTAT
,	COALESCE(p.EXEMPTSTATUS,'Unknown')
FROM 
	CMS.S1017192.CMSFIL.PRPMST prpmst LEFT OUTER JOIN
	CMS.S1017192.CMSFIL.PRPUNM prpunm ON
		prpmst.MCONO=prpunm.QCONO
	AND prpmst.MDVNO=prpunm.QDVNO
	AND prpmst.MUNNO=prpunm.QUNNO
	AND prpunm.QUDTY=0
	AND LTRIM(RTRIM(prpunm.QJBNO)) = ''
	AND LTRIM(RTRIM(prpunm.QSJNO)) = '' LEFT OUTER JOIN
	dbo.PEOPLE e ON
		CAST(prpmst.MEENO AS NVARCHAR(10))=e.REFERENCENUMBER 
	AND e.STATUS = 'A' LEFT OUTER JOIN
	dbo.JOBDETAIL jd ON
		e.PEOPLE_ID=jd.PEOPLE_ID 
	AND jd.TOPJOB='T' LEFT OUTER JOIN
	dbo.POST p ON
		jd.JOBTITLE=p.POST_ID	
WHERE
(	prpmst.MSTAT='A'
AND prpmst.MCONO IN (1,15,20,30,50,60)
AND p.EXEMPTSTATUS = 'NonExempt' )
OR 	CAST(prpmst.MCONO AS VARCHAR(5)) + '.' + CAST(prpmst.MEENO AS VARCHAR(10)) IN
	(
		SELECT DISTINCT CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10)) FROM mnepto.TimeCardManualEntries
	)
*/
go


--IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='mtr_TimeCardManualEntries' AND TABLE_SCHEMA='mnepto')
--BEGIN
--	PRINT 'DROP TRIGGER [mnepto].[mtr_TimeCardManualEntries]'
--	DROP TRIGGER [mnepto].[mtr_TimeCardManualEntries]
--END
--go



PRINT 'CREATE TRIGGER [mnepto].[mtr_TimeCardManualEntries]'
go

CREATE TRIGGER [mnepto].[mtr_TimeCardManualEntries]
   ON  [mnepto].[TimeCardManualEntries] 
   AFTER INSERT,UPDATE,DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--INSERT mnepto.TriggerLog(EmployeeNumber,RowId,LogText) select null, null, 'Recalc Trigger Fired'

		
	DECLARE icur CURSOR FOR
	SELECT EmployeeNumber, RowId, cast(GroupID AS varchar(5)) 
	from inserted
	UNION
	SELECT EmployeeNumber, RowId, cast(GroupID AS varchar(5)) 
	from deleted
	ORDER BY 1,2
	FOR READ ONLY
	
	DECLARE @gr  varchar(5)
	DECLARE @em numeric(5,0)
	DECLARE @r  INT
	
	OPEN icur
	FETCH icur INTO @em,@r,@gr
	WHILE @@fetch_status=0
	BEGIN
		PRINT 'Trigger Fire - ' + CAST(COALESCE(@em,0) AS VARCHAR(10)) + ':' + COALESCE(@gr,'')
		
		--INSERT mnepto.TriggerLog(EmployeeNumber,RowId,LogText) select @em, @r, 'Recalc Trigger Fired'
		
		EXEC mnepto.mspRecalculateAccruals
			 @EmployeeNumber = @em 
		,    @GroupIdentifier = null 
		,    @DoRefresh = 0
		,    @SimPriorYearRate = 0 

		FETCH icur INTO @em,@r,@gr		
	END
	
	CLOSE icur
	DEALLOCATE icur   


END
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME='TimeCardAggregateView' AND TABLE_SCHEMA='mnepto')
BEGIN
	PRINT 'DROP TABLE [mnepto].[TimeCardAggregateView]'
	DROP VIEW [mnepto].[TimeCardAggregateView]
END
go


PRINT 'CREATE VIEW [mnepto].[TimeCardAggregateView]'
go

CREATE VIEW [mnepto].[TimeCardAggregateView]
as
SELECT 
	tc.[CompanyNumber]
,	tc.[EmployeeNumber]
,	p.[EmployeeName]
,	tc.[RegularHours]
,	tc.[OvertimeHours]
,	tc.[OtherHours]
,	tc.[OtherHoursType] COLLATE SQL_Latin1_General_CP1_CI_AS AS OtherHoursType
,	tc.[TotalHours] --	([RegularHours] + [OvertimeHours] + [OtherHours]) AS [TotalHours]
,	tc.[WeekEnding]
,	tc.[Year]
,	tc.[GroupId]
,	tc.LogicalKey
,	tc.EmployeeLogicalKey
,	'TC' AS Source
FROM 
	[mnepto].[TimeCardHistory] tc JOIN
	[mnepto].[Personnel] p ON
		tc.CompanyNumber=p.CompanyNumber 
	AND	tc.EmployeeNumber=p.EmployeeNumber 
	AND 
	(
		CAST(tc.[GroupId] AS VARCHAR(3))  IN ( SELECT DISTINCT [GroupIdentifier] FROM [mnepto].[AccrualSettings] )
	OR  CAST(tc.[OtherHoursType] AS VARCHAR(3))  IN ( SELECT DISTINCT [UseIdentifier] FROM [mnepto].[AccrualSettings] )
	)
UNION --COLLATE SQL_Latin1_General_CP1_CI_AS
SELECT 
	tc.[CompanyNumber]
,	tc.[EmployeeNumber]
,	p.[EmployeeName]
,	tc.[RegularHours]
,	tc.[OvertimeHours]
,	tc.[OtherHours]
,	tc.[OtherHoursType] COLLATE SQL_Latin1_General_CP1_CI_AS AS OtherHoursType
,	tc.[TotalHours] --	([RegularHours] + [OvertimeHours] + [OtherHours]) AS [TotalHours]
,	tc.[WeekEnding]
,	tc.[Year]
,	tc.[GroupId]
,	tc.LogicalKey
,	tc.EmployeeLogicalKey
,	CASE WHEN tc.InitialLoad=1 THEN 'IL' ELSE 'ME' END AS Source
FROM 
	[mnepto].[TimeCardManualEntries] tc JOIN
	[mnepto].[Personnel] p ON
		tc.CompanyNumber=p.CompanyNumber
	AND	tc.EmployeeNumber=p.EmployeeNumber	
	AND 
	(
		CAST(tc.[GroupId] AS VARCHAR(3))  IN ( SELECT DISTINCT [GroupIdentifier] FROM [mnepto].[AccrualSettings] )
	OR  CAST(tc.[OtherHoursType] AS VARCHAR(3)) COLLATE SQL_Latin1_General_CP1_CI_AS IN ( SELECT DISTINCT [UseIdentifier] FROM [mnepto].[AccrualSettings] )
	)	
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME='mfnEffectiveStartDate' AND ROUTINE_SCHEMA='mnepto' AND ROUTINE_TYPE='FUNCTION')
BEGIN
	PRINT 'DROP function [mnepto].[mfnEffectiveStartDate]'
	DROP FUNCTION [mnepto].[mfnEffectiveStartDate]
END
go

print 'create FUNCTION [mnepto].[mfnEffectiveStartDate]'
go

create FUNCTION [mnepto].[mfnEffectiveStartDate]
(
	@EmployeeNumber		INT
,	@Days		INT = 180
)
RETURNS  DATETIME
AS
BEGIN
	DECLARE @PeopleId	UNIQUEIDENTIFIER
	DECLARE @EffectiveStartDate DATETIME
	DECLARE @sdate DATETIME
	DECLARE @edate DATETIME
	
	SELECT @PeopleId=PEOPLE_ID FROM PEOPLE WHERE REFERENCENUMBER=CAST(@EmployeeNumber AS VARCHAR(10))
	SELECT @EffectiveStartDate = MAX(EFFECTIVEDATE) FROM dbo.JOBDETAIL WHERE PEOPLE_ID=@PeopleId AND ENDDATE IS null
	
	DECLARE dtcur CURSOR FOR
	SELECT
		EFFECTIVEDATE
	,	ENDDATE
	FROM 
		dbo.JOBDETAIL
	WHERE
		PEOPLE_ID=@PeopleId
	ORDER BY
		EFFECTIVEDATE DESC
	FOR READ ONLY
	
	OPEN dtcur
	FETCH dtcur INTO
		@sdate
	,	@edate
	
	WHILE @@fetch_status=0
	BEGIN 
		IF @edate IS NOT NULL AND (DATEDIFF(day,@EffectiveStartDate,@edate) <= @Days)
		BEGIN
			SELECT @EffectiveStartDate=@sdate
		END

		FETCH dtcur INTO
			@sdate
		,	@edate	
	END 
	
	CLOSE dtcur
	DEALLOCATE dtcur
	
		
	--SELECT @EffectiveStartDate = GETDATE()
	
	RETURN @EffectiveStartDate	
END

go

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME='mfnMyTeamPersonnel' AND ROUTINE_SCHEMA='mnepto' AND ROUTINE_TYPE='FUNCTION')
BEGIN
	PRINT 'DROP function [mnepto].[mfnMyTeamPersonnel]'
	DROP FUNCTION [mnepto].[mfnMyTeamPersonnel]
END
go

print 'create FUNCTION [mnepto].[mfnMyTeamPersonnel]'
go

create FUNCTION [mnepto].[mfnMyTeamPersonnel]
(
	@EmployeeNumber		INT
)
RETURNS TABLE
AS
RETURN
SELECT
	p.*,	eh.MRGREFERENCENUMBER AS ManagerNumber,eh.MGRFULLNAME AS ManagerName
FROM 
	mnepto.Personnel p JOIN
	HRNET.dbo.fnEmployeeHierarchy(@EmployeeNumber) eh ON
		p.EmployeeNumber=eh.REFERENCENUMBER

GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME='mfnMyTeamAccrualSummary' AND ROUTINE_SCHEMA='mnepto' AND ROUTINE_TYPE='FUNCTION')
BEGIN
	PRINT 'DROP function [mnepto].[mfnMyTeamAccrualSummary]'
	DROP FUNCTION [mnepto].[mfnMyTeamAccrualSummary]
END
go

print 'create FUNCTION [mnepto].[mfnMyTeamAccrualSummary]'
go

create FUNCTION [mnepto].[mfnMyTeamAccrualSummary]
(
	@EmployeeNumber		INT
)
RETURNS TABLE
AS
RETURN
SELECT
	p.*,	p2.EmployeeName
FROM 
	mnepto.AccrualSummary p JOIN
	mnepto.Personnel p2 ON
		p.EmployeeNumber=p2.EmployeeNumber
	AND p.CompanyNumber=p2.CompanyNumber join
	HRNET.dbo.fnEmployeeHierarchy(@EmployeeNumber) eh ON
		p.EmployeeNumber=eh.REFERENCENUMBER

GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME='mfnMyTeamTimeCardAggregateView' AND ROUTINE_SCHEMA='mnepto' AND ROUTINE_TYPE='FUNCTION')
BEGIN
	PRINT 'DROP function [mnepto].[mfnMyTeamTimeCardAggregateView]'
	DROP FUNCTION [mnepto].[mfnMyTeamTimeCardAggregateView]
END
go

print 'create FUNCTION [mnepto].[mfnMyTeamTimeCardAggregateView]'
go

create FUNCTION [mnepto].[mfnMyTeamTimeCardAggregateView]
(
	@EmployeeNumber		INT
)
RETURNS TABLE
as
RETURN
SELECT
	p.*
FROM 
	mnepto.TimeCardAggregateView p JOIN
	HRNET.dbo.fnEmployeeHierarchy(@EmployeeNumber) eh ON
		p.EmployeeNumber=eh.REFERENCENUMBER
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME='mfnMyTeamTimeCardManualEntries' AND ROUTINE_SCHEMA='mnepto' AND ROUTINE_TYPE='FUNCTION')
BEGIN
	PRINT 'DROP function [mnepto].[mfnMyTeamTimeCardManualEntries]'
	DROP FUNCTION [mnepto].[mfnMyTeamTimeCardManualEntries]
END
go

print 'create FUNCTION [mnepto].[mfnMyTeamTimeCardManualEntries]'
go

create FUNCTION [mnepto].[mfnMyTeamTimeCardManualEntries]
(
	@EmployeeNumber		INT
)
RETURNS TABLE
AS
RETURN		
SELECT
	p.*
FROM 
	mnepto.TimeCardManualEntries p JOIN
	HRNET.dbo.fnEmployeeHierarchy(@EmployeeNumber) eh ON
		p.EmployeeNumber=eh.REFERENCENUMBER		
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='PROCEDURE' AND ROUTINE_NAME='mspSyncPersonnel' AND ROUTINE_SCHEMA='mnepto')
BEGIN
PRINT 'DROP PROCEDURE [mnepto].[mspSyncPersonnel]'
DROP PROCEDURE [mnepto].[mspSyncPersonnel]
END
go

PRINT 'CREATE PROCEDURE [mnepto].[mspSyncPersonnel]'
go

CREATE PROCEDURE [mnepto].[mspSyncPersonnel]
(
	@EmployeeNumber  INT = NULL
)
as

-- INSERT MISSING
INSERT [mnepto].[Personnel]
(
	CompanyNumber	--int			NOT NULL 
,	EmployeeNumber	--int			NOT NULL
,	EmployeeName	--varchar(50)	NOT NULL
,	EmployeeDept	--varchar(10)	NOT NULL
,	EmployeeClass	--varchar(10)	NOT NULL
,	EmployeeType	--varchar(10)	NOT NULL
,	EmployeeUnion	--varchar(10)	NOT NULL
,	EmployeeUnionName
,	EmployeeStatus	--varchar(5)	NOT NULL
,	EmployeeExemptClassification	--varchar(20)	NOT NULL 
)
SELECT
	prpmst.MCONO
,	prpmst.MEENO
,	prpmst.MNM25
,	SUBSTRING(CAST(prplbr.LGLAN AS CHAR(15)),5,3)  --prpmst.MSDDP  -- TODO: Chage view on iSeries to get GL Dept, not PR Dept
,	prpmst.MEECL
,	prpmst.MEETY
,	prpmst.MUNNO
,	coalesce(prpunm.QD15A,prpmst.MUNNO)
,	prpmst.MSTAT
,	COALESCE(p.EXEMPTSTATUS,'Unknown')
FROM 
	CMS.S1017192.CMSFIL.PRPMST prpmst LEFT OUTER JOIN
	CMS.S1017192.CMSFIL.PRPLBR prplbr ON
		prpmst.MCONO=prplbr.LCONO
	AND prpmst.MDVNO=prplbr.LDVNO
	AND prpmst.MSDDP=prplbr.LDPNO LEFT OUTER JOIN
	CMS.S1017192.CMSFIL.PRPUNM prpunm ON
		prpmst.MCONO=prpunm.QCONO
	AND prpmst.MDVNO=prpunm.QDVNO
	AND prpmst.MUNNO=prpunm.QUNNO
	AND prpunm.QUDTY=0
	AND LTRIM(RTRIM(prpunm.QJBNO)) = ''
	AND LTRIM(RTRIM(prpunm.QSJNO)) = '' LEFT OUTER JOIN
	dbo.PEOPLE e ON
		CAST(prpmst.MEENO AS NVARCHAR(10))=e.REFERENCENUMBER 
	AND e.STATUS = 'A' LEFT OUTER JOIN
	dbo.JOBDETAIL jd ON
		e.PEOPLE_ID=jd.PEOPLE_ID 
	AND jd.TOPJOB='T' LEFT OUTER JOIN
	dbo.POST p ON
		jd.JOBTITLE=p.POST_ID	
WHERE
(
(	prpmst.MSTAT='A'
AND prpmst.MCONO IN (1,15,20,30,50,60)
AND p.EXEMPTSTATUS = 'NonExempt' )

OR 	CAST(prpmst.MCONO AS VARCHAR(5)) + '.' + CAST(prpmst.MEENO AS VARCHAR(10)) IN
	(
		SELECT DISTINCT CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10)) FROM mnepto.TimeCardManualEntries
	)
)
AND CAST(prpmst.MCONO AS VARCHAR(5)) + '.' + CAST(prpmst.MEENO AS VARCHAR(10)) NOT IN (
	SELECT DISTINCT CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10)) FROM mnepto.Personnel
)

-- UPDATE EXISTING
UPDATE mnepto.Personnel SET
	EmployeeName=t1.MNM25
,	EmployeeDept=t1.MSDDP
,	EmployeeClass=t1.MEECL
,	EmployeeType=t1.MEETY
,	EmployeeUnion=t1.MUNNO
,	EmployeeUnionName=t1.QD15A
,	EmployeeStatus=t1.MSTAT
,	EmployeeExemptClassification=t1.EXEMPTSTATUS
FROM 
	mnepto.Personnel p JOIN
	(
		SELECT
		prpmst.MCONO
	,	prpmst.MEENO
	,	prpmst.MNM25 COLLATE SQL_Latin1_General_CP1_CI_AS AS MNM25
	,	SUBSTRING(CAST(prplbr.LGLAN AS CHAR(15)),5,3) AS MSDDP
	,	prpmst.MEECL 
	,	prpmst.MEETY COLLATE SQL_Latin1_General_CP1_CI_AS AS MEETY
	,	prpmst.MUNNO COLLATE SQL_Latin1_General_CP1_CI_AS AS MUNNO
	,	coalesce(prpunm.QD15A,prpmst.MUNNO)  COLLATE SQL_Latin1_General_CP1_CI_AS AS QD15A
	,	prpmst.MSTAT COLLATE SQL_Latin1_General_CP1_CI_AS AS MSTAT
	,	COALESCE(p.EXEMPTSTATUS,'Unknown') COLLATE SQL_Latin1_General_CP1_CI_AS AS EXEMPTSTATUS
	,	CAST(prpmst.MCONO AS VARCHAR(5)) + '.' + CAST(prpmst.MEENO AS varchar(10)) AS LogicalKey
	FROM 
		CMS.S1017192.CMSFIL.PRPMST prpmst LEFT OUTER JOIN
		CMS.S1017192.CMSFIL.PRPLBR prplbr ON
			prpmst.MCONO=prplbr.LCONO
		AND prpmst.MDVNO=prplbr.LDVNO
		AND prpmst.MSDDP=prplbr.LDPNO LEFT OUTER JOIN
		CMS.S1017192.CMSFIL.PRPUNM prpunm ON
			prpmst.MCONO=prpunm.QCONO
		AND prpmst.MDVNO=prpunm.QDVNO
		AND prpmst.MUNNO=prpunm.QUNNO
		AND prpunm.QUDTY=0
		AND LTRIM(RTRIM(prpunm.QJBNO)) = ''
		AND LTRIM(RTRIM(prpunm.QSJNO)) = '' LEFT OUTER JOIN
		dbo.PEOPLE e ON
			CAST(prpmst.MEENO AS NVARCHAR(10))=e.REFERENCENUMBER 
		AND e.STATUS = 'A' LEFT OUTER JOIN
		dbo.JOBDETAIL jd ON
			e.PEOPLE_ID=jd.PEOPLE_ID 
		AND jd.TOPJOB='T' LEFT OUTER JOIN
		dbo.POST p ON
			jd.JOBTITLE=p.POST_ID	
	WHERE
	(	prpmst.MSTAT='A'
	AND prpmst.MCONO IN (1,15,20,30,50,60)
	AND p.EXEMPTSTATUS = 'NonExempt' )
	OR 	CAST(prpmst.MCONO AS VARCHAR(5)) + '.' + CAST(prpmst.MEENO AS VARCHAR(10)) IN
		(
			SELECT DISTINCT CAST(CompanyNumber AS VARCHAR(5)) + '.' + CAST(EmployeeNumber AS VARCHAR(10)) FROM mnepto.TimeCardManualEntries
		)
	) t1 ON p.LogicalKey=t1.LogicalKey
	WHERE
	(
		EmployeeName <> t1.MNM25
	OR	EmployeeDept <> t1.MSDDP
	OR	EmployeeClass <> t1.MEECL
	OR	EmployeeType <> t1.MEETY
	OR	EmployeeUnion <> t1.MUNNO
	OR	EmployeeStatus <> t1.MSTAT
	OR	EmployeeExemptClassification <> t1.EXEMPTSTATUS )

go


IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='PROCEDURE' AND ROUTINE_NAME='mspSyncDNNAccounts' AND ROUTINE_SCHEMA='mnepto')
BEGIN
PRINT 'DROP PROCEDURE [mnepto].[mspSyncDNNAccounts]'
DROP PROCEDURE [mnepto].[mspSyncDNNAccounts]
END
go

PRINT 'CREATE PROCEDURE [mnepto].[mspSyncDNNAccounts]'
go

CREATE PROCEDURE [mnepto].[mspSyncDNNAccounts]
(
	@EmployeeNumber  INT = NULL
,	@defaultDNNEmail varchar(100) = ''
,	@DoDNNSync		 INT = 0
)
AS

IF @defaultDNNEmail IS NULL
	SELECT @defaultDNNEmail=''

DECLARE @curDBSVR VARCHAR(60)
SELECT @curDBSVR = CAST(SERVERPROPERTY('MachineName') AS VARCHAR(30)) + '\' + COALESCE(CAST(SERVERPROPERTY('InstanceName') AS VARCHAR(30)),'')

PRINT 'CUR SERVER: ' +	@curDBSVR
DECLARE seccur CURSOR FOR
SELECT 
	CompanyNumber
,	EmployeeNumber
,	EmployeeName
,	EmployeeStatus
,	EmployeeUnionName
,	LogicalKey
FROM 
	mnepto.Personnel
WHERE (
	EmployeeNumber=@EmployeeNumber
OR  @EmployeeNumber IS NULL )

DECLARE @rcnt INT
	
DECLARE @CompanyNumber int
DECLARE @strEmployeeNumber VARCHAR(10)
DECLARE @EmployeeName VARCHAR(50)
DECLARE @EmployeeStatus varchar(5)
DECLARE @EmployeeUnionName VARCHAR(100)
DECLARE @LogicalKey VARCHAR(20)

DECLARE @fname  VARCHAR(50)
DECLARE @lname  VARCHAR(50)

DECLARE @dnnLogin VARCHAR(50)
DECLARE @dnnEmail VARCHAR(50)

SELECT @rcnt = 0

OPEN seccur
FETCH seccur INTO
	@CompanyNumber
,	@EmployeeNumber
,	@EmployeeName
,	@EmployeeStatus
,	@EmployeeUnionName
,	@LogicalKey

WHILE @@fetch_status=0
BEGIN
	SELECT @rcnt = @rcnt+1

	SELECT @strEmployeeNumber = CAST(@EmployeeNumber AS VARCHAR(10))
	
	
	SELECT @dnnLogin=COALESCE(
		CAST('MCKINSTRY\' + CASE WHEN LTRIM(RTRIM(n.USERNAME)) <> '' THEN n.USERNAME ELSE NULL END  AS VARCHAR(50)) --AS DomainLogin
	--,	CAST(n.EMAIL AS VARCHAR(50))	--AS Email1
	--,	CAST(p.EMAILPRIMARY AS VARCHAR(50))	--AS Email2
	--,	CAST(p.EMAILSECONDARY AS VARCHAR(50)) --AS Email3
	,	CAST(@EmployeeNumber AS VARCHAR(50)) )	
	,	@dnnEmail=COALESCE(
		CAST(n.EMAIL AS VARCHAR(50))	--AS Email1
	,	CAST(p.EMAILPRIMARY AS VARCHAR(50))	--AS Email2
	,	CAST(p.EMAILSECONDARY AS VARCHAR(50)) --AS Email3
	,	@defaultDNNEmail
	)	
	FROM 
		dbo.PEOPLE p LEFT OUTER JOIN
		dbo.NEWHIREPROVISIONING	n ON
			p.PEOPLE_ID=n.PEOPLE_ID
	WHERE 
		p.REFERENCENUMBER=CAST(@EmployeeNumber AS VARCHAR(10))
	AND (
		p.EMAILPRIMARY IS NOT NULL
	OR  p.EMAILSECONDARY IS NOT NULL
	OR (
			UPPER(n.DOMAIN)=1
		AND n.USERNAME IS NOT null
		)
	)
	
	IF CHARINDEX(',',@EmployeeName) > 0
	begin
	SELECT @lname = LTRIM(RTRIM(LEFT(@EmployeeName,CHARINDEX(',',@EmployeeName)-1)))
	SELECT @fname = LTRIM(RTRIM(REPLACE(REPLACE(@EmployeeName,@lname,''),',','')))
	END
	ELSE
	BEGIN
	SELECT @lname = LTRIM(RTRIM(LEFT(@EmployeeName,CHARINDEX(' ',@EmployeeName)-1)))
	SELECT @fname = LTRIM(RTRIM(REPLACE(REPLACE(@EmployeeName,@lname,''),',','')))
	END
	
	SELECT @dnnLogin = REPLACE(@dnnLogin,'@mckinstry.com','')
	SELECT @dnnLogin = COALESCE(@dnnLogin,@strEmployeeNumber)
	
	IF @dnnEmail IS NULL OR LTRIM(RTRIM(@dnnEmail)) = ''
		SELECT @dnnEmail=@defaultDNNEmail
		
	PRINT
		CAST(@rcnt AS CHAR(5))
	+	CAST(@EmployeeStatus AS CHAR(10))
	+	CAST(@LogicalKey AS CHAR(20))
	+	CAST(COALESCE(@EmployeeName,'UNDETERMINED') AS CHAR(50))
	+	CAST(COALESCE(@dnnLogin,CAST(@EmployeeNumber AS VARCHAR(10))) AS CHAR(50))
	+	CAST(COALESCE(@dnnEmail,'') AS CHAR(50))
	+	@fname + '/' + @lname
	
	PRINT 'UNION NAME: ' + COALESCE(@EmployeeUnionName,'NULL')	
	IF @DoDNNSync <> 0
	BEGIN	
		if @curDBSVR = 'DEV-HRISSQL02\'
		BEGIN 
		
		PRINT 'Sync Accounts on ' + @curDBSVR  + ' http://dnndev.mckinstry.com'
		
		EXEC sedevsql01.McK_DNN_DB.dbo.mspUpsertDNNUser 
			@UserToCopy = 'mnepto_template' --nvarchar(100)
		,	@UserName = @dnnLogin --nvarchar(100)
		,	@FirstName = @fname --nvarchar(100)
		,	@LastName = @lname --nvarchar(100)
		,	@Email = @dnnEmail --nvarchar(100)
		,	@EmployeeNumber	= @strEmployeeNumber --VARCHAR(20)
		,	@RoleName = 'Non-Staff PTO Users' --	NVARCHAR(100) = 'Non-Staff PTO Users'
		,	@UnionName = @EmployeeUnionName
		,	@Status	= @EmployeeStatus --NVARCHAR(10)
				
		END
		
		if @curDBSVR = 'SESQL08\'
		BEGIN 
		PRINT 'Sync Accounts on ' + @curDBSVR  + ' http://dnn.mckinstry.com'
		EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
			@UserToCopy = 'mnepto_template' --nvarchar(100)
		,	@UserName = @dnnLogin --nvarchar(100)
		,	@FirstName = @fname --nvarchar(100)
		,	@LastName = @lname --nvarchar(100)
		,	@Email = @dnnEmail --nvarchar(100)
		,	@EmployeeNumber	= @strEmployeeNumber --VARCHAR(20)
		,	@RoleName = 'Non-Staff PTO Users' --	NVARCHAR(100) = 'Non-Staff PTO Users'
		,	@UnionName = @EmployeeUnionName
		,	@Status	= @EmployeeStatus --NVARCHAR(10)
		END		
	END
	
	SELECT @dnnLogin=NULL, @dnnEmail=null
	
	FETCH seccur INTO
		@CompanyNumber
	,	@EmployeeNumber
	,	@EmployeeName
	,	@EmployeeStatus
	,	@EmployeeUnionName
	,	@LogicalKey
END

CLOSE seccur
DEALLOCATE seccur

go

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='PROCEDURE' AND ROUTINE_NAME='mspRecalculateAccruals' AND ROUTINE_SCHEMA='mnepto')
BEGIN
PRINT 'DROP PROCEDURE [mnepto].mspRecalculateAccruals'
DROP PROCEDURE [mnepto].mspRecalculateAccruals
END


PRINT 'CREATE PROCEDURE [mnepto].mspRecalculateAccruals'
GO

CREATE PROCEDURE [mnepto].mspRecalculateAccruals
(
	@EmployeeNumber INT = NULL
,	@GroupIdentifier varchar(3) = null
,	@DoRefresh INT = 0
,	@SyncDNNAccount INT = 0	
,	@defaultDNNEmail varchar(100) = ''
,	@SimPriorYearRate decimal(5,2) = 0
)
AS

SET NOCOUNT ON

IF @defaultDNNEmail IS null
	SELECT @defaultDNNEmail = ''

DECLARE @emp_rcnt INT 
DECLARE @pmsg VARCHAR(MAX)

DECLARE @currYear int
DECLARE @prevYear int

SELECT @currYear = YEAR(GETDATE())
SELECT @prevYear = @currYear-1

DECLARE @GroupName VARCHAR(30)
DECLARE @UseIdentifier VARCHAR(3)

DECLARE @GroupEffectiveDate DATETIME
DECLARE @GroupEffectiveDate2 [numeric](8, 0)

DECLARE @EligibleWorkDays	INT	
DECLARE @EligibleWorkHours	INT	
DECLARE @AccrualRatePerSet	INT	
DECLARE @AccrualSet			INT	
DECLARE @MaxAccrual			INT	
DECLARE @AllowedGapInService INT

DECLARE @empcurCompanyNumber	int			
DECLARE @empcurEmployeeNumber	INT
DECLARE @empcurEmployeeName		VARCHAR(50)
DECLARE @empcurEffectiveStartDate DATETIME
DECLARE @empcurEmployedDays	INT
DECLARE @empcurReportedHours INT
DECLARE @empcurEligible CHAR(1)

SELECT @emp_rcnt = 0
-- Loop through each GroupIdentifier ( either the one supplied or All )

DECLARE tcur CURSOR FOR
SELECT
	GroupDescription
,	GroupIdentifier
,	UseIdentifier
,	EffectiveDate
,	EligibleWorkDays
,	EligibleWorkHours
,	AllowedGapInService
,	AccrualRatePerSet
,	AccrualSet
,	MaxAccrual
FROM 
	mnepto.AccrualSettings
WHERE
	(GroupIdentifier=@GroupIdentifier OR @GroupIdentifier IS NULL)
FOR READ ONLY

OPEN tcur
FETCH tcur INTO 
	@GroupName
,	@GroupIdentifier
,	@UseIdentifier
,	@GroupEffectiveDate
,	@EligibleWorkDays	
,	@EligibleWorkHours	
,	@AllowedGapInService 
,	@AccrualRatePerSet
,	@AccrualSet			
,	@MaxAccrual			
	
WHILE @@fetch_status=0
BEGIN

	SELECT @GroupEffectiveDate2 = CAST(CONVERT(CHAR(8),@GroupEffectiveDate,112) as [numeric](8, 0))
	
	SELECT @pmsg =
		CAST(@GroupName AS CHAR(31))
	+	CAST(@GroupIdentifier + '/' + @UseIdentifier AS CHAR(10))
	
	-- First Refresh TimeCardHistory
	IF @DoRefresh <> 0
	BEGIN
		PRINT 'REFRESHING SOURCE TIMECARD HISTORY DATA'
		
		PRINT 'REFRESHING PERSONNEL LIST'
		EXEC [mnepto].[mspSyncPersonnel] @EmployeeNumber
		
		DELETE 
			mnepto.TimeCardHistory 
		WHERE	
		(	GroupID = @GroupIdentifier 
		OR  OtherHoursType = @UseIdentifier )			
		AND (EmployeeNumber=@EmployeeNumber OR @EmployeeNumber IS NULL)
		AND CAST(LEFT(CAST(WeekEnding AS CHAR(8)),4) AS INT) IN (@currYear,@prevYear)
		
		print @pmsg + CAST(CAST(@@rowcount AS VARCHAR(10)) + ' rows deleted.' AS CHAR(40)) + CAST(COALESCE(CAST(@EmployeeNumber AS VARCHAR(10)),'') AS CHAR(10))
		
		INSERT [mnepto].[TimeCardHistory]
		(
			CompanyNumber	--int				NOT NULL 
		,	EmployeeNumber	--int				NOT NULL
		,	RegularHours	--[numeric](5, 2) NOT NULL
		,	OvertimeHours	--[numeric](5, 2) NOT NULL
		,	OtherHours		--[numeric](5, 2)	NOT NULL
		,	OtherHoursType	--[varchar](10)	NOT NULL
		--,	TotalHours AS [RegularHours]+[OvertimeHours]+[OtherHours]
		,	WeekEnding		--[numeric](8, 0) NOT NULL
		,	GroupID			--[numeric](2, 0) NOT NULL
		)
		SELECT 
			tch.CHCONO
		,	tch.CHEENO
		,	tch.CHRGHR
		,	tch.CHOVHR
		,	tch.CHOTHR
		,	tch.CHOTTY
		,	tch.CHDTWE
		,	tch.CHCRNO
		FROM 
			CMS.S1017192.BILLO.PRPTCHS tch 	
		WHERE
		(	tch.CHCRNO=@GroupIdentifier 
		OR  tch.CHOTTY=@UseIdentifier )
		AND (tch.CHEENO=@EmployeeNumber OR @EmployeeNumber IS NULL)
		AND CAST(tch.CHDTWE AS INT) >= CAST(@GroupEffectiveDate2 AS INT)
		AND CAST(LEFT(CAST(tch.CHDTWE AS CHAR(8)),4) AS INT) IN (@currYear,@prevYear)

		print @pmsg + CAST(CAST(@@rowcount AS VARCHAR(10)) + ' rows inserted. ' AS CHAR(40)) + CAST(COALESCE(CAST(@EmployeeNumber AS VARCHAR(10)),'') AS CHAR(10))
		PRINT ''
		
	END
	
	SELECT @emp_rcnt = 0
	
	-- GET AGGREGATED ENTRIES FROM VIEW FOR PROCESSING
	DECLARE empcur CURSOR FOR
	SELECT
		CompanyNumber, EmployeeNumber, EmployeeName
	FROM 
		mnepto.Personnel
	WHERE
		( EmployeeNumber = @EmployeeNumber OR @EmployeeNumber IS NULL )
	ORDER BY 
		CompanyNumber
	,	EmployeeNumber
	FOR READ ONLY


	OPEN empcur
	FETCH empcur INTO
		@empcurCompanyNumber
	,	@empcurEmployeeNumber	
	,	@empcurEmployeeName
	
	WHILE @@fetch_status=0
	BEGIN		
		SELECT @emp_rcnt = @emp_rcnt + 1
		-- Get Employee Effective Starting Date
		SELECT @empcurEffectiveStartDate = COALESCE(mnepto.mfnEffectiveStartDate(@empcurEmployeeNumber,@AllowedGapInService),GETDATE())
		SELECT @empcurEmployedDays=COALESCE(DATEDIFF(day,@empcurEffectiveStartDate,GETDATE()),0)
		
		SELECT @empcurReportedHours = COALESCE(SUM(TotalHours),0)
		FROM	
			mnepto.TimeCardAggregateView
		WHERE
			GroupId=@GroupIdentifier
		AND EmployeeNumber=@empcurEmployeeNumber
		AND CompanyNumber=@empcurCompanyNumber			
		
		IF @empcurEmployedDays >= @EligibleWorkDays AND @empcurReportedHours >= @EligibleWorkHours
		BEGIN
			SELECT @empcurEligible='E'
		END
		ELSE
		BEGIN
			SELECT @empcurEligible='I'
		END
		
		PRINT
			CAST(@emp_rcnt AS CHAR(8))
		+	CAST(CAST(@empcurCompanyNumber AS VARCHAR(5)) + '.' + CAST(@empcurEmployeeNumber	AS VARCHAR(10)) AS CHAR(30))
		+	CAST(coalesce(@empcurEligible,'X') AS CHAR(3))
		+	CAST(coalesce(@empcurEmployeeName,'Unknown') AS CHAR(55))	
		+	CONVERT(CHAR(10),COALESCE(@empcurEffectiveStartDate,GETDATE()),102) + ' = '
		+	CAST(COALESCE(@empcurEmployedDays,0) AS CHAR(8)) + ' : '
		+	CAST(COALESCE(@empcurReportedHours,0) AS CHAR(8))
		
		DELETE mnepto.AccrualSummary 
		WHERE
			GroupIdentifier =@GroupIdentifier
		AND EmployeeNumber = @empcurEmployeeNumber
		AND CompanyNumber = @empcurCompanyNumber 
				
		-- Record Current Accumulation of Hours
		INSERT mnepto.AccrualSummary
		        ( CompanyNumber ,
		          EmployeeNumber ,
		          Year ,
		          GroupIdentifier ,
		          EffectiveWorkDays ,
		          EffectiveStartDate ,
		          EligibleStatus ,
		          AccumulatedHours ,
		          PrevCarryOverPTOHours ,
		          AccruedPTOHours ,
		          UsedPTOHours ,
		          RunDate
		        )
		SELECT
			CompanyNumber
		,	EmployeeNumber
		,	Year
		,   GroupId	
		,	@empcurEmployedDays
		,	@empcurEffectiveStartDate
		,	@empcurEligible
		,	SUM(TotalHours)
		,	0
		,	CASE 
				WHEN (@empcurReportedHours/@AccrualSet)*@AccrualRatePerSet > @MaxAccrual THEN @MaxAccrual
				ELSE (@empcurReportedHours/@AccrualSet)*@AccrualRatePerSet
			END
		,	0
		,	GETDATE()
		FROM	
			mnepto.TimeCardAggregateView
		WHERE
			GroupId=@GroupIdentifier
		AND EmployeeNumber = @empcurEmployeeNumber
		AND CompanyNumber = @empcurCompanyNumber
		GROUP BY
			CompanyNumber
		,	EmployeeNumber
		,   GroupId			
		,	Year
		
		IF @SimPriorYearRate <> 0
		BEGIN
		INSERT mnepto.AccrualSummary
		        ( CompanyNumber ,
		          EmployeeNumber ,
		          Year ,
		          GroupIdentifier ,
		          EffectiveWorkDays ,
		          EffectiveStartDate ,
		          EligibleStatus ,
		          AccumulatedHours ,
		          PrevCarryOverPTOHours ,
		          AccruedPTOHours ,
		          UsedPTOHours ,
		          RunDate
		        )
		SELECT
			CompanyNumber
		,	EmployeeNumber
		,	Year-1
		,   GroupId	
		,	@empcurEmployedDays
		,	@empcurEffectiveStartDate
		,	'I'
		,	@empcurReportedHours*@SimPriorYearRate
		,	0
		,	CASE 
				WHEN ((@empcurReportedHours*@SimPriorYearRate)/@AccrualSet)*@AccrualRatePerSet > @MaxAccrual THEN @MaxAccrual
				ELSE ((@empcurReportedHours*@SimPriorYearRate)/@AccrualSet)*@AccrualRatePerSet
			END
		,	0
		,	GETDATE()
		FROM	
			mnepto.TimeCardAggregateView
		WHERE
			GroupId=@GroupIdentifier
		AND EmployeeNumber = @empcurEmployeeNumber
		AND CompanyNumber = @empcurCompanyNumber
		GROUP BY
			CompanyNumber
		,	EmployeeNumber
		,   GroupId			
		,	Year
		END

		--Add People with no submissions
		INSERT mnepto.AccrualSummary
        ( CompanyNumber ,
          EmployeeNumber ,
          Year ,
          GroupIdentifier ,
          EffectiveWorkDays ,
          EffectiveStartDate ,
          EligibleStatus ,
          AccumulatedHours ,
          PrevCarryOverPTOHours ,
          AccruedPTOHours ,
          UsedPTOHours ,
          RunDate
        )		
		SELECT
			@empcurCompanyNumber
		,	@empcurEmployeeNumber	
		,	@currYear
		,	@GroupIdentifier
		,	@empcurEmployedDays
		,	@empcurEffectiveStartDate
		,	@empcurEligible
		,	@empcurReportedHours
		,	0
		,	0
		,	0
		, GETDATE()
		FROM
			mnepto.Personnel p
		WHERE
			p.CompanyNumber=@empcurCompanyNumber
		AND p.EmployeeNumber=@empcurEmployeeNumber
		AND	CAST(@empcurCompanyNumber AS VARCHAR(10)) + '.' + CAST(@empcurEmployeeNumber AS VARCHAR(10)) + '.' + CAST(@GroupIdentifier AS VARCHAR(10))
		NOT IN ( 
			SELECT DISTINCT CAST(CompanyNumber AS VARCHAR(10)) + '.' + CAST(EmployeeNumber AS VARCHAR(10)) + '.' + CAST(GroupIdentifier AS VARCHAR(10)) 
			FROM mnepto.AccrualSummary 
		)
						
		--Update Current Used Hours
		
		UPDATE mnepto.AccrualSummary SET 
			UsedPTOHours=UsedHours
		FROM 
		(
		SELECT
			CompanyNumber
		,	EmployeeNumber
		,	Year
		,   GroupId	
		,	@empcurEmployedDays AS EmployedDays
		,	@empcurEffectiveStartDate AS EffectiveStartDate
		,	@empcurEligible AS Eligible		
		,	SUM(TotalHours) AS UsedHours
		,	GETDATE() AS RunDate
		FROM	
			mnepto.TimeCardAggregateView
		WHERE
			OtherHoursType= @UseIdentifier
		AND EmployeeNumber = @empcurEmployeeNumber
		AND CompanyNumber = @empcurCompanyNumber
		GROUP BY
			CompanyNumber
		,	EmployeeNumber
		,   GroupId			
		,	Year		
		) tblUsed
		WHERE
			mnepto.AccrualSummary.CompanyNumber=tblUsed.CompanyNumber
		AND mnepto.AccrualSummary.EmployeeNumber=tblUsed.EmployeeNumber
		AND mnepto.AccrualSummary.Year=tblUsed.YEAR
		AND mnepto.AccrualSummary.GroupIdentifier=@GroupIdentifier

		--SELECT * FROM mnepto.AccrualSummary WHERE EmployeeNumber=@empcurEmployeeNumber		
		UPDATE 	mnepto.AccrualSummary 
		SET PrevCarryOverPTOHours=
		COALESCE((
			SELECT (PrevCarryOverPTOHours+AccruedPTOHours)-UsedPTOHours 
			FROM mnepto.AccrualSummary
			WHERE GroupIdentifier=@GroupIdentifier
			AND EmployeeNumber = @empcurEmployeeNumber
			AND CompanyNumber = @empcurCompanyNumber
			AND Year=@prevYear
		),0)
		WHERE
			CompanyNumber=@empcurCompanyNumber
		AND EmployeeNumber=@empcurEmployeeNumber
		AND GroupIdentifier=@GroupIdentifier
		AND Year=@currYear

		--Check Max Accrual
		UPDATE mnepto.AccrualSummary
		SET AccruedPTOHours=
			CASE
				WHEN ( PrevCarryOverPTOHours + AccruedPTOHours ) > @MaxAccrual THEN @MaxAccrual-PrevCarryOverPTOHours
				ELSE AccruedPTOHours
		END
		
		-- Run based on on inputparamter.  Dont need to run on trigger fires or other action where the data has alredy been processed.
		-- Also used in debugging to only update data without doing DNN Account management.
		IF @SyncDNNAccount <> 0
		BEGIN
			PRINT 'Do DNN Sync'
			EXEC [mnepto].[mspSyncDNNAccounts] @empcurEmployeeNumber,@defaultDNNEmail,@SyncDNNAccount
		END
					
		FETCH empcur INTO
			@empcurCompanyNumber
		,	@empcurEmployeeNumber
		,	@empcurEmployeeName
	END
	
	CLOSE empcur
	DEALLOCATE empcur
		
	--SELECT
	--	p.CompanyNumber
	--,	p.EmployeeName
	--,	p.EmployeeExemptClassification	
	--,	tca.Year
	--,	tca.*
	--FROM 
	--	mnepto.Personnel p LEFT OUTER JOIN
	--	mnepto.TimeCardAggregateView tca ON
	--		p.CompanyNumber=tca.CompanyNumber
	--	AND p.EmployeeNumber=tca.EmployeeNumber
	--WHERE
	--(	tca.GroupId = @GroupIdentifier
	--OR  tca.OtherHoursType = @UseIdentifier )
	--AND	( p.EmployeeNumber=@EmployeeNumber OR @EmployeeNumber IS NULL )	
		

	FETCH tcur INTO 
		@GroupName
	,	@GroupIdentifier
	,	@UseIdentifier
	,	@GroupEffectiveDate
	,	@EligibleWorkDays	
	,	@EligibleWorkHours	
	,	@AllowedGapInService 
	,	@AccrualRatePerSet
	,	@AccrualSet			
	,	@MaxAccrual	

END 

CLOSE tcur
DEALLOCATE tcur


SELECT * FROM mnepto.AccrualSummary 
WHERE
	(GroupIdentifier=@GroupIdentifier OR @GroupIdentifier IS NULL)
AND (EmployeeNumber=@EmployeeNumber OR @EmployeeNumber IS NULL)
ORDER BY 1,2
go

GRANT SELECT on mnepto.Personnel TO nsproportaluser
GRANT SELECT, INSERT, UPDATE, DELETE ON mnepto.TimeCardHistory TO nsproportaluser
GRANT SELECT, INSERT, UPDATE, DELETE ON mnepto.TimeCardManualEntries TO nsproportaluser
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.mvwTimeCardManualEntries TO nsproportaluser
GRANT SELECT on mnepto.AccrualSummary TO nsproportaluser
GRANT SELECT on [mnepto].[TimeCardAggregateView] TO nsproportaluser
GRANT EXECUTE ON [mnepto].[mfnEffectiveStartDate]  TO nsproportaluser
GRANT SELECT ON [mnepto].[mfnMyTeamPersonnel] TO nsproportaluser
GRANT SELECT ON [mnepto].[mfnMyTeamAccrualSummary] TO nsproportaluser
GRANT SELECT ON [mnepto].[mfnMyTeamTimeCardAggregateView] TO nsproportaluser
GRANT SELECT ON [mnepto].[mfnMyTeamTimeCardManualEntries] TO nsproportaluser
GRANT EXECUTE ON [mnepto].mspRecalculateAccruals  TO nsproportaluser
GRANT EXECUTE ON [mnepto].[mspSyncPersonnel]  TO nsproportaluser
GRANT EXECUTE ON [mnepto].[mspSyncDNNAccounts] TO nsproportaluser
GRANT SELECT ON mnepto.AccrualSettings TO nsproportaluser
GRANT SELECT ON [mnepto].[mvwActiveEmployees] TO nsproportaluser
GRANT SELECT ON dbo.JOBDETAIL TO nsproportaluser 
GRANT SELECT ON dbo.POST TO nsproportaluser
go

--  ADD ADMIN & SUPER ACCOUNTS

EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\LORAINEW' --nvarchar(100)
,	@FirstName = 'Loraine' --nvarchar(100)
,	@LastName = 'White' --nvarchar(100)
,	@Email = 'lorainew@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '94418' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Admins' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)
go		

EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\lindaw' --nvarchar(100)
,	@FirstName = 'Linda' --nvarchar(100)
,	@LastName = 'Wiacek' --nvarchar(100)
,	@Email = 'lindaw@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '681' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Admins' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)
go

EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\patrickk' --nvarchar(100)
,	@FirstName = 'Patrick' --nvarchar(100)
,	@LastName = 'Kirschner' --nvarchar(100)
,	@Email = 'patrickk@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '48154' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Admins' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)
go
	
EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\BethR' --nvarchar(100)
,	@FirstName = 'Beth' --nvarchar(100)
,	@LastName = 'Roe' --nvarchar(100)
,	@Email = 'BethR@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '77873' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Supervisors' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)	
go

EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\DarinB' --nvarchar(100)
,	@FirstName = 'Darin' --nvarchar(100)
,	@LastName = 'Borden' --nvarchar(100)
,	@Email = 'darinb@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '9896' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Supervisors' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)	
go

EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\DamonC' --nvarchar(100)
,	@FirstName = 'Damon' --nvarchar(100)
,	@LastName = 'Cannon' --nvarchar(100)
,	@Email = 'DamonC@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '15159' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Supervisors' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)						
go

EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\NinaD' --nvarchar(100)
,	@FirstName = 'Nina' --nvarchar(100)
,	@LastName = 'Davey' --nvarchar(100)
,	@Email = 'NinaD@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '21381' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Supervisors' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)	
go

EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\mikepi' --nvarchar(100)
,	@FirstName = 'Mike' --nvarchar(100)
,	@LastName = 'Piggott' --nvarchar(100)
,	@Email = 'mikepi@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '72616' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Supervisors' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)
go

EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\daveste' --nvarchar(100)
,	@FirstName = 'Dave' --nvarchar(100)
,	@LastName = 'Stevens' --nvarchar(100)
,	@Email = 'daveste@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '84859' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Supervisors' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)		
go

EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\BobBl' --nvarchar(100)
,	@FirstName = 'Bob' --nvarchar(100)
,	@LastName = 'Blodgette' --nvarchar(100)
,	@Email = 'BobBl@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '8826' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Supervisors' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)			
go

EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\henryg' --nvarchar(100)
,	@FirstName = 'Henry' --nvarchar(100)
,	@LastName = 'Gowen' --nvarchar(100)
,	@Email = 'henryg@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '32431' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Supervisors' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)	
go

EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\andiv' --nvarchar(100)
,	@FirstName = 'Andi' --nvarchar(100)
,	@LastName = 'Van Blaricom' --nvarchar(100)
,	@Email = 'andiv@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '90358' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Supervisors' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)
go

EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\waydem' --nvarchar(100)
,	@FirstName = 'Wayde' --nvarchar(100)
,	@LastName = 'Miller' --nvarchar(100)
,	@Email = 'waydem@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '60812' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Supervisors' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)			
go


EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\HowardS' --nvarchar(100)
,	@FirstName = 'Howard' --nvarchar(100)
,	@LastName = 'Snow' --nvarchar(100)
,	@Email = 'howards@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '82958' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Supervisors' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)			
go

EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'MCKINSTRY\allisonf' --nvarchar(100)
,	@FirstName = 'Allison' --nvarchar(100)
,	@LastName = 'Floe' --nvarchar(100)
,	@Email = 'allisonf@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '562' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Supervisors' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)		
go

EXEC McK_DNN_DB.dbo.mspUpsertDNNUser 
	@UserToCopy = 'mnepto_template' --nvarchar(100)
,	@UserName = 'veronicar' --nvarchar(100)
,	@FirstName = 'Veronica' --nvarchar(100)
,	@LastName = 'Ramirez' --nvarchar(100)
,	@Email = 't-veronicar@mckinstry.com' --nvarchar(100)
,	@EmployeeNumber	= '0' --VARCHAR(20)
,	@RoleName = 'Non-Staff PTO Supervisors' --	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName = null
,	@Status	= 'A' --NVARCHAR(10)	
go
					
					
EXEC [mnepto].mspRecalculateAccruals
	@EmployeeNumber = null
,	@GroupIdentifier ='38'
,	@DoRefresh = 1
,	@SyncDNNAccount =1
,	@defaultDNNEmail = ''
,	@SimPriorYearRate=0
go


-- END REBUILD

--EXEC [mnepto].[mspSyncPersonnel] @EmployeeNumber=null
--EXEC [mnepto].[mspSyncDNNAccounts]
--	@EmployeeNumber  = NULL
--,	@DoDNNSync		 = 0


--INSERT mnepto.TimeCardManualEntries
--        ( CompanyNumber ,
--          EmployeeNumber ,
--          EmployeeName ,
--          WeekEnding ,
--          GroupID ,
--          RegularHours ,
--          OvertimeHours ,
--          OtherHours ,
--          OtherHoursType
--        )
--VALUES  ( 1 , -- CompanyNumber - numeric
--          184 , -- EmployeeNumber - numeric
--          'GALVIN, THOMAS MICHAEL' , -- EmployeeName - char(25)
--          20131201 , -- WeekEnding - numeric
--          null , -- GroupID - numeric
--          0 , -- RegularHours - numeric
--          0 , -- OvertimeHours - numeric
--          6 , -- OtherHours - numeric
--          '38'  -- OtherHoursType - char(2)
--        )

