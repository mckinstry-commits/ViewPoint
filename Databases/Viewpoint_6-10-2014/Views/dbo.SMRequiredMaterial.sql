SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMRequiredMaterial] AS 
SELECT m.*
FROM vSMRequiredMaterial m
GO
GRANT SELECT ON  [dbo].[SMRequiredMaterial] TO [public]
GRANT INSERT ON  [dbo].[SMRequiredMaterial] TO [public]
GRANT DELETE ON  [dbo].[SMRequiredMaterial] TO [public]
GRANT UPDATE ON  [dbo].[SMRequiredMaterial] TO [public]
GRANT SELECT ON  [dbo].[SMRequiredMaterial] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMRequiredMaterial] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMRequiredMaterial] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMRequiredMaterial] TO [Viewpoint]
GO
