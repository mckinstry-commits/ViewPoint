SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDUserNotification
AS
SELECT     dbo.vDDUserNotification.*
FROM         dbo.vDDUserNotification

GO
GRANT SELECT ON  [dbo].[DDUserNotification] TO [public]
GRANT INSERT ON  [dbo].[DDUserNotification] TO [public]
GRANT DELETE ON  [dbo].[DDUserNotification] TO [public]
GRANT UPDATE ON  [dbo].[DDUserNotification] TO [public]
GO
