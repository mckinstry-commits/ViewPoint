SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.APSM
AS
SELECT     dbo.vAPSM.*
FROM         dbo.vAPSM

GO
GRANT SELECT ON  [dbo].[APSM] TO [public]
GRANT INSERT ON  [dbo].[APSM] TO [public]
GRANT DELETE ON  [dbo].[APSM] TO [public]
GRANT UPDATE ON  [dbo].[APSM] TO [public]
GRANT SELECT ON  [dbo].[APSM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APSM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APSM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APSM] TO [Viewpoint]
GO
