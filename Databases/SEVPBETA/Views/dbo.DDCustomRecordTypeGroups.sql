SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDCustomRecordTypeGroups
AS
SELECT     GroupId, RecordTypeId
FROM         dbo.vDDCustomRecordTypeGroups

GO
GRANT SELECT ON  [dbo].[DDCustomRecordTypeGroups] TO [public]
GRANT INSERT ON  [dbo].[DDCustomRecordTypeGroups] TO [public]
GRANT DELETE ON  [dbo].[DDCustomRecordTypeGroups] TO [public]
GRANT UPDATE ON  [dbo].[DDCustomRecordTypeGroups] TO [public]
GO
