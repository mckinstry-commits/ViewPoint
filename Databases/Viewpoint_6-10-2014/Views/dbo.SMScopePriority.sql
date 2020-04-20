SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[SMScopePriority]
AS
SELECT *
FROM dbo.vSMScopePriority



GO
GRANT SELECT ON  [dbo].[SMScopePriority] TO [public]
GRANT INSERT ON  [dbo].[SMScopePriority] TO [public]
GRANT DELETE ON  [dbo].[SMScopePriority] TO [public]
GRANT UPDATE ON  [dbo].[SMScopePriority] TO [public]
GRANT SELECT ON  [dbo].[SMScopePriority] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMScopePriority] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMScopePriority] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMScopePriority] TO [Viewpoint]
GO
