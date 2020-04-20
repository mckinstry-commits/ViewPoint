SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRMyTimesheetDetail] as select a.* From bPRMyTimesheetDetail a
GO
GRANT SELECT ON  [dbo].[PRMyTimesheetDetail] TO [public]
GRANT INSERT ON  [dbo].[PRMyTimesheetDetail] TO [public]
GRANT DELETE ON  [dbo].[PRMyTimesheetDetail] TO [public]
GRANT UPDATE ON  [dbo].[PRMyTimesheetDetail] TO [public]
GO
