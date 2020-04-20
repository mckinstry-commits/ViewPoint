SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE View [dbo].[RFSceneUsage] as

select * from vRFSceneUsage


GO
GRANT SELECT ON  [dbo].[RFSceneUsage] TO [public]
GRANT INSERT ON  [dbo].[RFSceneUsage] TO [public]
GRANT DELETE ON  [dbo].[RFSceneUsage] TO [public]
GRANT UPDATE ON  [dbo].[RFSceneUsage] TO [public]
GRANT SELECT ON  [dbo].[RFSceneUsage] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RFSceneUsage] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RFSceneUsage] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RFSceneUsage] TO [Viewpoint]
GO
