SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDCustomActions
AS
SELECT     Id AS ActionId, Name, Description, ImageKey, ActionType, Action, KeyID, RequiresRecords
FROM         dbo.vDDCustomActions
GO
GRANT SELECT ON  [dbo].[DDCustomActions] TO [public]
GRANT INSERT ON  [dbo].[DDCustomActions] TO [public]
GRANT DELETE ON  [dbo].[DDCustomActions] TO [public]
GRANT UPDATE ON  [dbo].[DDCustomActions] TO [public]
GO
