CREATE TABLE [dbo].[vBITargetBudget]
(
[BICo] [dbo].[bCompany] NOT NULL,
[TargetName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Revision] [int] NOT NULL,
[TargetDate] [dbo].[bDate] NOT NULL,
[DayOfWeek] [tinyint] NULL,
[DayNameOfWeek] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[DayOfMonth] [tinyint] NULL,
[DayOfYear] [smallint] NULL,
[WeekdayWeekend] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[WeekOfYear] [tinyint] NULL,
[MonthName] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[MonthOfYear] [tinyint] NULL,
[IsLastDayOfMonth] [dbo].[bYN] NULL,
[CalendarQuarter] [tinyint] NULL,
[CalendarYear] [smallint] NULL,
[Goal] [bigint] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vBITargetBudget] ADD CONSTRAINT [PK_vBITargetBudget] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vBITargetBudget_TargetName_Revision_TargetDate] ON [dbo].[vBITargetBudget] ([BICo], [TargetName], [Revision], [TargetDate]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
