SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[DDNotificationPrefs] as select * from vDDNotificationPrefs

GO
GRANT SELECT ON  [dbo].[DDNotificationPrefs] TO [public]
GRANT INSERT ON  [dbo].[DDNotificationPrefs] TO [public]
GRANT DELETE ON  [dbo].[DDNotificationPrefs] TO [public]
GRANT UPDATE ON  [dbo].[DDNotificationPrefs] TO [public]
GRANT SELECT ON  [dbo].[DDNotificationPrefs] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDNotificationPrefs] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDNotificationPrefs] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDNotificationPrefs] TO [Viewpoint]
GO
