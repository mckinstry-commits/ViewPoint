SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SLWIHist] as select a.* From vSLWIHist a

GO
GRANT SELECT ON  [dbo].[SLWIHist] TO [public]
GRANT INSERT ON  [dbo].[SLWIHist] TO [public]
GRANT DELETE ON  [dbo].[SLWIHist] TO [public]
GRANT UPDATE ON  [dbo].[SLWIHist] TO [public]
GO
