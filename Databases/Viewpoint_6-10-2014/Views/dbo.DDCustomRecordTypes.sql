SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDCustomRecordTypes
AS
SELECT     Id, Name
FROM         dbo.vDDCustomRecordTypes

GO
GRANT SELECT ON  [dbo].[DDCustomRecordTypes] TO [public]
GRANT INSERT ON  [dbo].[DDCustomRecordTypes] TO [public]
GRANT DELETE ON  [dbo].[DDCustomRecordTypes] TO [public]
GRANT UPDATE ON  [dbo].[DDCustomRecordTypes] TO [public]
GRANT SELECT ON  [dbo].[DDCustomRecordTypes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDCustomRecordTypes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDCustomRecordTypes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDCustomRecordTypes] TO [Viewpoint]
GO
