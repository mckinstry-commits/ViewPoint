CREATE TABLE [dbo].[vSMMyTimesheetLink]
(
[SMMyTimesheetLinkID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[PRCo] [dbo].[bCompany] NOT NULL,
[WorkOrder] [int] NOT NULL,
[Scope] [int] NOT NULL,
[WorkCompleted] [int] NOT NULL,
[SMWorkCompletedID] [bigint] NULL,
[EntryEmployee] [int] NOT NULL,
[Employee] [int] NOT NULL,
[StartDate] [smalldatetime] NOT NULL,
[DayNumber] [tinyint] NOT NULL,
[Sheet] [smallint] NOT NULL,
[Seq] [smallint] NOT NULL,
[UpdateInProgress] [bit] NOT NULL CONSTRAINT [DF_vSMMyTimesheetLink_UpdateInProgress] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMMyTimesheetLink] ADD CONSTRAINT [PK_vSMMyTimesheetLink] PRIMARY KEY CLUSTERED  ([SMMyTimesheetLinkID]) ON [PRIMARY]
GO
