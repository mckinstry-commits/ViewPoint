SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[SLWHHist] as select a.* From vSLWHHist a



GO
GRANT SELECT ON  [dbo].[SLWHHist] TO [public]
GRANT INSERT ON  [dbo].[SLWHHist] TO [public]
GRANT DELETE ON  [dbo].[SLWHHist] TO [public]
GRANT UPDATE ON  [dbo].[SLWHHist] TO [public]
GRANT SELECT ON  [dbo].[SLWHHist] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SLWHHist] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SLWHHist] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SLWHHist] TO [Viewpoint]
GO
