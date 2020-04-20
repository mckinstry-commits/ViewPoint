SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDFSUsers
AS
SELECT     TOP (100) PERCENT f.Co, f.VPUserName, f.Form, h.Mod, f.Access, f.RecAdd, f.RecDelete, f.RecUpdate, f.SecurityGroup
FROM         dbo.DDFS AS f INNER JOIN
                      dbo.DDFH AS h ON f.Form = h.Form
WHERE     (f.SecurityGroup = - 1)
ORDER BY f.VPUserName

GO
GRANT SELECT ON  [dbo].[DDFSUsers] TO [public]
GRANT INSERT ON  [dbo].[DDFSUsers] TO [public]
GRANT DELETE ON  [dbo].[DDFSUsers] TO [public]
GRANT UPDATE ON  [dbo].[DDFSUsers] TO [public]
GRANT SELECT ON  [dbo].[DDFSUsers] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDFSUsers] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDFSUsers] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDFSUsers] TO [Viewpoint]
GO
