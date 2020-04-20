SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.BITargetLevel
AS
SELECT * FROM dbo.vBITargetLevel
GO
GRANT SELECT ON  [dbo].[BITargetLevel] TO [public]
GRANT INSERT ON  [dbo].[BITargetLevel] TO [public]
GRANT DELETE ON  [dbo].[BITargetLevel] TO [public]
GRANT UPDATE ON  [dbo].[BITargetLevel] TO [public]
GRANT SELECT ON  [dbo].[BITargetLevel] TO [Viewpoint]
GRANT INSERT ON  [dbo].[BITargetLevel] TO [Viewpoint]
GRANT DELETE ON  [dbo].[BITargetLevel] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[BITargetLevel] TO [Viewpoint]
GO
