SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[DDFSForm]
AS
SELECT     TOP (100) PERCENT f.Co, f.Form, f.SecurityGroup, g.Name AS Groups, f.VPUserName, p.FullName AS [Full Name], f.Access, f.RecAdd, f.RecDelete, 
                      f.RecUpdate, h.Mod --, f.AllowAttachments
FROM         dbo.DDFS AS f LEFT OUTER JOIN
                      dbo.DDSG AS g ON f.SecurityGroup = g.SecurityGroup LEFT OUTER JOIN
                      dbo.DDUP AS p ON f.VPUserName = p.VPUserName LEFT OUTER JOIN
                      dbo.DDFH AS h ON f.Form = h.Form
ORDER BY f.Form



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<AL, vtuDDFSForm>
-- Create date: <5/25/07>
-- Description:	<Insted of trigger used to update DDFS>
-- =============================================
CREATE TRIGGER [dbo].[vtuDDFSForm] on [dbo].[DDFSForm] INSTEAD OF UPDATE AS

declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on

UPDATE dbo.vDDFS
SET Co = i.Co, [Form] = i.[Form], [SecurityGroup] = i.[SecurityGroup], [VPUserName] = i.VPUserName, 
[Access] = i.Access, [RecAdd] = i.RecAdd, [RecDelete] = i.RecDelete, [RecUpdate] = i.RecUpdate
FROM inserted i

RETURN

GO
GRANT SELECT ON  [dbo].[DDFSForm] TO [public]
GRANT INSERT ON  [dbo].[DDFSForm] TO [public]
GRANT DELETE ON  [dbo].[DDFSForm] TO [public]
GRANT UPDATE ON  [dbo].[DDFSForm] TO [public]
GO
