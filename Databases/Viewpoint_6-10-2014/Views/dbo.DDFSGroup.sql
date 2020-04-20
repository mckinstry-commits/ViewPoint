SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDFSGroup
AS
SELECT     TOP (100) PERCENT f.Co, f.SecurityGroup, g.Name AS Names, f.VPUserName, f.Form, f.Access, f.RecAdd, f.RecUpdate, f.RecDelete, h.Mod
FROM         dbo.DDFS AS f INNER JOIN
                      dbo.DDSG AS g ON f.SecurityGroup = g.SecurityGroup LEFT OUTER JOIN
                      dbo.DDFH AS h ON f.Form = h.Form
ORDER BY f.SecurityGroup

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<AL, vtuDDFSGroup>
-- Create date: <5/25/07>
-- Description:	<Instead of trigger used to add to DDFS>
-- =============================================
CREATE TRIGGER [dbo].[vtuDDFSGroup] on [dbo].[DDFSGroup] INSTEAD OF UPDATE AS

declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on

UPDATE dbo.vDDFS
SET Co = i.Co, [SecurityGroup] = i.SecurityGroup, [VPUserName] = i.VPUserName, 
[Access] = i.Access, [RecAdd] = i.RecAdd, [RecDelete] = i.RecDelete, [RecUpdate] = i.RecUpdate
FROM inserted i


return

GO
GRANT SELECT ON  [dbo].[DDFSGroup] TO [public]
GRANT INSERT ON  [dbo].[DDFSGroup] TO [public]
GRANT DELETE ON  [dbo].[DDFSGroup] TO [public]
GRANT UPDATE ON  [dbo].[DDFSGroup] TO [public]
GRANT SELECT ON  [dbo].[DDFSGroup] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDFSGroup] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDFSGroup] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDFSGroup] TO [Viewpoint]
GO
