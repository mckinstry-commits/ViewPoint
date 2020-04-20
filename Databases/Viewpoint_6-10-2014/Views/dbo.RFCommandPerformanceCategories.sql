SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE View [dbo].[RFCommandPerformanceCategories] as

select * from vRFCommandPerformanceCategories


GO
GRANT SELECT ON  [dbo].[RFCommandPerformanceCategories] TO [public]
GRANT INSERT ON  [dbo].[RFCommandPerformanceCategories] TO [public]
GRANT DELETE ON  [dbo].[RFCommandPerformanceCategories] TO [public]
GRANT UPDATE ON  [dbo].[RFCommandPerformanceCategories] TO [public]
GRANT SELECT ON  [dbo].[RFCommandPerformanceCategories] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RFCommandPerformanceCategories] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RFCommandPerformanceCategories] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RFCommandPerformanceCategories] TO [Viewpoint]
GO
