SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.BITargetHeader
AS
SELECT * FROM dbo.vBITargetHeader
GO
GRANT SELECT ON  [dbo].[BITargetHeader] TO [public]
GRANT INSERT ON  [dbo].[BITargetHeader] TO [public]
GRANT DELETE ON  [dbo].[BITargetHeader] TO [public]
GRANT UPDATE ON  [dbo].[BITargetHeader] TO [public]
GRANT SELECT ON  [dbo].[BITargetHeader] TO [Viewpoint]
GRANT INSERT ON  [dbo].[BITargetHeader] TO [Viewpoint]
GRANT DELETE ON  [dbo].[BITargetHeader] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[BITargetHeader] TO [Viewpoint]
GO
