SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMStandardTaskMaterial]
AS
SELECT     *
FROM         dbo.vSMStandardTaskMaterial
GO
GRANT SELECT ON  [dbo].[SMStandardTaskMaterial] TO [public]
GRANT INSERT ON  [dbo].[SMStandardTaskMaterial] TO [public]
GRANT DELETE ON  [dbo].[SMStandardTaskMaterial] TO [public]
GRANT UPDATE ON  [dbo].[SMStandardTaskMaterial] TO [public]
GRANT SELECT ON  [dbo].[SMStandardTaskMaterial] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMStandardTaskMaterial] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMStandardTaskMaterial] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMStandardTaskMaterial] TO [Viewpoint]
GO
