SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[SMPartType]
AS
SELECT     *
FROM         dbo.vSMPartType



GO
GRANT SELECT ON  [dbo].[SMPartType] TO [public]
GRANT INSERT ON  [dbo].[SMPartType] TO [public]
GRANT DELETE ON  [dbo].[SMPartType] TO [public]
GRANT UPDATE ON  [dbo].[SMPartType] TO [public]
GO
