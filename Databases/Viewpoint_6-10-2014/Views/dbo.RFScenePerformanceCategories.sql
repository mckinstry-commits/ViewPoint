SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE View [dbo].[RFScenePerformanceCategories] as

select * from vRFScenePerformanceCategories


GO
GRANT SELECT ON  [dbo].[RFScenePerformanceCategories] TO [public]
GRANT INSERT ON  [dbo].[RFScenePerformanceCategories] TO [public]
GRANT DELETE ON  [dbo].[RFScenePerformanceCategories] TO [public]
GRANT UPDATE ON  [dbo].[RFScenePerformanceCategories] TO [public]
GRANT SELECT ON  [dbo].[RFScenePerformanceCategories] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RFScenePerformanceCategories] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RFScenePerformanceCategories] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RFScenePerformanceCategories] TO [Viewpoint]
GO
