TRUNCATE TABLE [mnepto].[TimeCardManualEntries]
go

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

--TRUNCATE TABLE [mnepto].[AccrualSettings]
--go

--INSERT [mnepto].[AccrualSettings] SELECT * FROM mnepto.AccrualSettings_BU
--GO

TRUNCATE TABLE [mnepto].TimeCardHistory
go

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

TRUNCATE TABLE [mnepto].[TimeCardManualEntries]
go

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

TRUNCATE TABLE mnepto.AccrualSummary
go

INSERT  mnepto.AccrualSummary
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
	CompanyNumber ,
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
from 
	mnepto.AccrualSummary_20141107_BU
go


UPDATE mnepto.AccrualSummary SET GroupIdentifier='503' WHERE GroupIdentifier='38'
UPDATE mnepto.AccrualSummary SET GroupIdentifier='206' WHERE GroupIdentifier='66'

UPDATE mnepto.TimeCardHistory SET GroupID='503' WHERE GroupID='38'
UPDATE mnepto.TimeCardHistory SET GroupID='206' WHERE GroupID='66'


UPDATE mnepto.TimeCardManualEntries SET GroupID='503' WHERE GroupID='38'
UPDATE mnepto.TimeCardManualEntries SET GroupID='206' WHERE GroupID='66'

UPDATE mnepto.TimeCardHistory SET OtherHoursType='13' WHERE GroupID='503'
UPDATE mnepto.TimeCardHistory SET OtherHoursType='66' WHERE GroupID='206'
UPDATE mnepto.TimeCardManualEntries SET OtherHoursType='13' WHERE GroupID='503'
UPDATE mnepto.TimeCardManualEntries SET OtherHoursType='66' WHERE GroupID='206'


SELECT * FROM mnepto.AccrualSettings 
SELECT DISTINCT GroupID from mnepto.TimeCardHistory
SELECT DISTINCT GroupID FROM mnepto.TimeCardManualEntries
SELECT distinct GroupIdentifier  FROM mnepto.AccrualSummary