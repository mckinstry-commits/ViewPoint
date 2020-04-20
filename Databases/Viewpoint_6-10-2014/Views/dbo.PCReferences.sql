SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PCReferences]
AS

SELECT		a.*
FROM		dbo.vPCReferences AS a


GO
GRANT SELECT ON  [dbo].[PCReferences] TO [public]
GRANT INSERT ON  [dbo].[PCReferences] TO [public]
GRANT DELETE ON  [dbo].[PCReferences] TO [public]
GRANT UPDATE ON  [dbo].[PCReferences] TO [public]
GRANT SELECT ON  [dbo].[PCReferences] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCReferences] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCReferences] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCReferences] TO [Viewpoint]
GO
