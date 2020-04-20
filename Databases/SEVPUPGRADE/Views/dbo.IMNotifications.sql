SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[IMNotifications] as

select * from vIMNotifications


GO
GRANT SELECT ON  [dbo].[IMNotifications] TO [public]
GRANT INSERT ON  [dbo].[IMNotifications] TO [public]
GRANT DELETE ON  [dbo].[IMNotifications] TO [public]
GRANT UPDATE ON  [dbo].[IMNotifications] TO [public]
GO
