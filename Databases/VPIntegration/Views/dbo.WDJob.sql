SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WDJob] as select a.*, a.QueryName as VAQueryName From WDJB a

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: HH 11/13/2012
* Modified: 
*
*	This trigger handles cascading deletes for WDJob
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWDJobd] 
   ON  [dbo].[WDJob] 
   INSTEAD OF DELETE
AS 
BEGIN
	
	DELETE WDJBTableColumns
	FROM WDJBTableColumns
	INNER JOIN deleted d ON WDJBTableColumns.JobName = d.JobName
	
	DELETE WDJBTableLayout
	FROM WDJBTableLayout
	INNER JOIN deleted d ON WDJBTableLayout.JobName = d.JobName
	
	DELETE WDJob
	FROM WDJob
	INNER JOIN deleted d ON WDJob.KeyID = d.KeyID AND WDJob.JobName = d.JobName 
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: HH 10/16/2012
* Modified: HH 11/06/2012 TK-18865 added EmailBodyHtml EmailFormat
*
*	This trigger sends data to the underlying QueryName from the correct
*	QueryName field which is used by both WF Notifier Query and VA Inquiry
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWDJobi] 
   ON  [dbo].[WDJob] 
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
-- WF Notifier Query
IF (SELECT QueryType FROM inserted) = 0
BEGIN
INSERT INTO bWDJB ([JobName],		[WeekTotal],	[Description],		[QueryName],	[FirstRun],		[LastRun],		[Enable],	[Occurs],	[mDay],		[Freq],		[Monday],	[Tuesday],		[Wednesday],	[Thursday],		[Friday],	[Saturday],		[QueryType],	[Sunday],	[DailyInt],		[HourMinute],	[StartTime],	[EndTime],		[StartDate],	[EndDate],		[EmailFormat],		[EmailTo],		[EmailCC],		[BCC],		[EmailSubject],		[EmailBody],	[EmailBodyHtml],	[Notes],	[EmailLine],	[EmailFooter],		[IsConsolidated]) 
	SELECT			i.[JobName],	i.[WeekTotal],	i.[Description],	i.[QueryName],	i.[FirstRun],	i.[LastRun],	i.[Enable],	i.[Occurs],	i.[mDay],	i.[Freq],	i.[Monday],	i.[Tuesday],	i.[Wednesday],	i.[Thursday],	i.[Friday],	i.[Saturday],	i.[QueryType],	i.[Sunday],	i.[DailyInt],	i.[HourMinute],	i.[StartTime],	i.[EndTime],	i.[StartDate],	i.[EndDate],	i.[EmailFormat],	i.[EmailTo],	i.[EmailCC],	i.[BCC],	i.[EmailSubject],	i.[EmailBody],	i.[EmailBody],		i.[Notes],	i.[EmailLine],	i.[EmailFooter],	i.[IsConsolidated]
	FROM inserted AS i
END
-- VA Inquiry
ELSE IF (SELECT QueryType FROM inserted) = 1
INSERT INTO bWDJB ([JobName],		[WeekTotal],	[Description],		[QueryName],	[FirstRun],		[LastRun],		[Enable],	[Occurs],	[mDay],		[Freq],		[Monday],	[Tuesday],		[Wednesday],	[Thursday],		[Friday],	[Saturday],		[QueryType],	[Sunday],	[DailyInt],		[HourMinute],	[StartTime],	[EndTime],		[StartDate],	[EndDate],		[EmailFormat],		[EmailTo],		[EmailCC],		[BCC],		[EmailSubject],		[EmailBody],	[EmailBodyHtml],	[Notes],	[EmailLine],	[EmailFooter],		[IsConsolidated]) 
	SELECT			i.[JobName],	i.[WeekTotal],	i.[Description],  i.[VAQueryName],	i.[FirstRun],	i.[LastRun],	i.[Enable],	i.[Occurs],	i.[mDay],	i.[Freq],	i.[Monday],	i.[Tuesday],	i.[Wednesday],	i.[Thursday],	i.[Friday],	i.[Saturday],	i.[QueryType],	i.[Sunday],	i.[DailyInt],	i.[HourMinute],	i.[StartTime],	i.[EndTime],	i.[StartDate],	i.[EndDate],	i.[EmailFormat],	i.[EmailTo],	i.[EmailCC],	i.[BCC],	i.[EmailSubject],	i.[EmailBody],	i.[EmailBodyHtml],	i.[Notes],	i.[EmailLine],	i.[EmailFooter],	i.[IsConsolidated]
	FROM inserted AS i
END

GO
GRANT SELECT ON  [dbo].[WDJob] TO [public]
GRANT INSERT ON  [dbo].[WDJob] TO [public]
GRANT DELETE ON  [dbo].[WDJob] TO [public]
GRANT UPDATE ON  [dbo].[WDJob] TO [public]
GO
