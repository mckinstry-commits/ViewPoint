SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PMRequestForQuoteDetail] as select a.* From vPMRequestForQuoteDetail a


GO
GRANT SELECT ON  [dbo].[PMRequestForQuoteDetail] TO [public]
GRANT INSERT ON  [dbo].[PMRequestForQuoteDetail] TO [public]
GRANT DELETE ON  [dbo].[PMRequestForQuoteDetail] TO [public]
GRANT UPDATE ON  [dbo].[PMRequestForQuoteDetail] TO [public]
GRANT SELECT ON  [dbo].[PMRequestForQuoteDetail] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMRequestForQuoteDetail] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMRequestForQuoteDetail] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMRequestForQuoteDetail] TO [Viewpoint]
GO
