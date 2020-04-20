SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDCustomGroups
AS
SELECT     Id, Name, [Order], ImageKey, RecordTypeId
FROM         dbo.vDDCustomGroups

GO
GRANT SELECT ON  [dbo].[DDCustomGroups] TO [public]
GRANT INSERT ON  [dbo].[DDCustomGroups] TO [public]
GRANT DELETE ON  [dbo].[DDCustomGroups] TO [public]
GRANT UPDATE ON  [dbo].[DDCustomGroups] TO [public]
GO
