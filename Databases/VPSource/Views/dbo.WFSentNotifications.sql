SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WFSentNotifications] as select a.* From vWFSentNotifications a
GO
GRANT SELECT ON  [dbo].[WFSentNotifications] TO [public]
GRANT INSERT ON  [dbo].[WFSentNotifications] TO [public]
GRANT DELETE ON  [dbo].[WFSentNotifications] TO [public]
GRANT UPDATE ON  [dbo].[WFSentNotifications] TO [public]
GO
