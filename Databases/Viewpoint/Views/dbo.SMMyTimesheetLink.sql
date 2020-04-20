SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[SMMyTimesheetLink] as select a.* From vSMMyTimesheetLink a


GO
GRANT SELECT ON  [dbo].[SMMyTimesheetLink] TO [public]
GRANT INSERT ON  [dbo].[SMMyTimesheetLink] TO [public]
GRANT DELETE ON  [dbo].[SMMyTimesheetLink] TO [public]
GRANT UPDATE ON  [dbo].[SMMyTimesheetLink] TO [public]
GO
