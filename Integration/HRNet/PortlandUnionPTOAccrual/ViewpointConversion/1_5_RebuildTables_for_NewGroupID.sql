SELECT * INTO mnepto.AccrualSettings_BU FROM mnepto.AccrualSettings
GO

DROP TABLE mnepto.AccrualSettings
GO

USE [HRNET]
GO

CREATE TABLE [mnepto].[AccrualSettings](
	[GroupIdentifier] [varchar](10) NOT NULL,
	[GroupDescription] [varchar](30) NOT NULL,
	[EffectiveDate] [datetime] NOT NULL,
	[UseIdentifier] [varchar](3) NOT NULL,
	[EligibleWorkDays] [int] NOT NULL,
	[EligibleWorkHours] [int] NOT NULL,
	[AllowedGapInService] [int] NOT NULL,
	[AccrualRatePerSet] [int] NOT NULL,
	[AccrualSet] [int] NOT NULL,
	[MaxAccrual] [int] NOT NULL,
	[EligibleWorkHoursAnnual] [char](1) NOT NULL,
	[EligibleWorkDaysLegacyWaiver] [char](1) NOT NULL,
	[MaxAnnualUse] [int] NOT NULL,
 CONSTRAINT [PK_mnepto_AccrualSettings] PRIMARY KEY CLUSTERED 
(
	[GroupIdentifier] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [mnepto].[AccrualSettings] ADD  CONSTRAINT [DF_AccrualSettings_EligibleWorkHoursAnnual]  DEFAULT ('N') FOR [EligibleWorkHoursAnnual]
GO

ALTER TABLE [mnepto].[AccrualSettings] ADD  CONSTRAINT [DF_AccrualSettings_EligibleWorkDaysLegacyWaiver]  DEFAULT ('N') FOR [EligibleWorkDaysLegacyWaiver]
GO

ALTER TABLE [mnepto].[AccrualSettings] ADD  CONSTRAINT [DF_AccrualSettings_MaxAnnualUse]  DEFAULT ((0)) FOR [MaxAnnualUse]
GO

INSERT [mnepto].[AccrualSettings] SELECT * FROM mnepto.AccrualSettings_BU
GO


SELECT * INTO mnepto.TimeCardHistory_BU FROM mnepto.TimeCardHistory
go

DROP TABLE mnepto.TimeCardHistory
go


CREATE TABLE [mnepto].[TimeCardHistory](
	[CompanyNumber] [int] NOT NULL,
	[EmployeeNumber] [int] NOT NULL,
	[RegularHours] [numeric](5, 2) NOT NULL,
	[OvertimeHours] [numeric](5, 2) NOT NULL,
	[OtherHours] [numeric](5, 2) NOT NULL,
	[OtherHoursType] [varchar](10) NOT NULL,
	[TotalHours]  AS (([RegularHours]+[OvertimeHours])+[OtherHours]),
	[WeekEnding] [numeric](8, 0) NOT NULL,
	[Year]  AS (CONVERT([int],[WeekEnding]/(10000),0)),
	[GroupID] [varchar](10) NOT NULL,
	[LogicalKey]  AS ((((((CONVERT([varchar](5),[CompanyNumber],0)+'.')+CONVERT([varchar](10),[EmployeeNumber],0))+'.')+CONVERT([varchar](10),coalesce([GroupID],[OtherHoursType]),0))+'.')+CONVERT([varchar](10),CONVERT([int],[WeekEnding]/(10000),0),0)),
	[EmployeeLogicalKey]  AS ((CONVERT([varchar](5),[CompanyNumber],0)+'.')+CONVERT([varchar](10),[EmployeeNumber],0))
) ON [PRIMARY]

GO

INSERT mnepto.TimeCardHistory
        ( CompanyNumber ,
          EmployeeNumber ,
          RegularHours ,
          OvertimeHours ,
          OtherHours ,
          OtherHoursType ,
          WeekEnding ,
          GroupID
        )
SELECT [CompanyNumber]
      ,[EmployeeNumber]
      ,[RegularHours]
      ,[OvertimeHours]
      ,[OtherHours]
      ,[OtherHoursType]
      ,[WeekEnding]
      ,[GroupID]
  FROM [HRNET].[mnepto].[TimeCardHistory_BU]
GO


SELECT * into  mnepto.TimeCardManualEntries_BU FROM mnepto.TimeCardManualEntries
go

DROP TABLE mnepto.TimeCardManualEntries
go

CREATE TABLE [mnepto].[TimeCardManualEntries](
	[RowId] [int] IDENTITY(1,1) NOT NULL,
	[CompanyNumber] [numeric](2, 0) NOT NULL,
	[EmployeeNumber] [numeric](5, 0) NOT NULL,
	[EmployeeName] [char](25) NOT NULL,
	[WeekEnding] [numeric](8, 0) NOT NULL,
	[Year]  AS (CONVERT([int],[WeekEnding]/(10000),0)),
	[GroupID] [varchar](10) NULL,
	[RegularHours] [numeric](5, 2) NOT NULL,
	[OvertimeHours] [numeric](5, 2) NOT NULL,
	[OtherHours] [numeric](5, 2) NOT NULL,
	[OtherHoursType] [char](2) NULL,
	[TotalHours]  AS (([RegularHours]+[OvertimeHours])+[OtherHours]),
	[LogicalKey]  AS ((((((CONVERT([varchar](5),[CompanyNumber],0)+'.')+CONVERT([varchar](10),[EmployeeNumber],0))+'.')+CONVERT([varchar](10),coalesce([GroupID],[OtherHoursType]),0))+'.')+CONVERT([varchar](10),CONVERT([int],[WeekEnding]/(10000),0),0)),
	[EmployeeLogicalKey]  AS ((CONVERT([varchar](5),[CompanyNumber],0)+'.')+CONVERT([varchar](10),[EmployeeNumber],0)),
	[InitialLoad] [int] NOT NULL,
 CONSTRAINT [PK_mnepto_TimeCardManualEntries] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [mnepto].[TimeCardManualEntries] ADD  DEFAULT ((0)) FOR [RegularHours]
GO

ALTER TABLE [mnepto].[TimeCardManualEntries] ADD  DEFAULT ((0)) FOR [OvertimeHours]
GO

ALTER TABLE [mnepto].[TimeCardManualEntries] ADD  DEFAULT ((0)) FOR [OtherHours]
GO

ALTER TABLE [mnepto].[TimeCardManualEntries] ADD  DEFAULT ((0)) FOR [InitialLoad]
GO


INSERT [mnepto].[TimeCardManualEntries]
        ( [CompanyNumber] ,
          [EmployeeNumber] ,
          [EmployeeName] ,
          [WeekEnding] ,
          [GroupID] ,
          [RegularHours] ,
          [OvertimeHours] ,
          [OtherHours] ,
          [OtherHoursType] ,
          [InitialLoad]
        )
SELECT [CompanyNumber] ,
          [EmployeeNumber] ,
          [EmployeeName] ,
          [WeekEnding] ,
          [GroupID] ,
          [RegularHours] ,
          [OvertimeHours] ,
          [OtherHours] ,
          [OtherHoursType] ,
          [InitialLoad]
FROM   [mnepto].[TimeCardManualEntries_BU]        
GO




SELECT * INTO mnepto.AccrualSettings_20141031_BU FROM mnepto.AccrualSettings
GO
SELECT * INTO mnepto.TimeCardHistory_BU_20141031_BU FROM mnepto.TimeCardHistory
GO
SELECT * into  mnepto.TimeCardManualEntries_20141031_BU FROM mnepto.TimeCardManualEntries
go


GRANT SELECT ON [mnepto].[mvwActiveEmployees] TO nsproportaluser
GO
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

GO


--sp_recompile mnepto.TimeCardAggregateView --TO nsproportaluser
--sp_recompile mnepto.mfnEffectiveStartDate  --TO nsproportaluser
--sp_recompile mnepto.mfnMyTeamPersonnel --TO nsproportaluser
--sp_recompile mnepto.mfnMyTeamAccrualSummary --TO nsproportaluser
--sp_recompile mnepto.mfnMyTeamTimeCardAggregateView --TO nsproportaluser
--sp_recompile mnepto.mfnMyTeamTimeCardManualEntries --TO nsproportaluser
--sp_recompile mnepto.mspRecalculateAccruals  --TO nsproportaluser
--sp_recompile mnepto.mspSyncPersonnel  --TO nsproportaluser
--sp_recompile mnepto.mspSyncDNNAccounts --TO nsproportaluser
--sp_recompile mnepto.mvwActiveEmployees --TO nsproportaluser

