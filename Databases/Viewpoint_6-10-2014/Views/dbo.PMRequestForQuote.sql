SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[PMRequestForQuote] as select a.* From vPMRequestForQuote a

GO
GRANT SELECT ON  [dbo].[PMRequestForQuote] TO [public]
GRANT INSERT ON  [dbo].[PMRequestForQuote] TO [public]
GRANT DELETE ON  [dbo].[PMRequestForQuote] TO [public]
GRANT UPDATE ON  [dbo].[PMRequestForQuote] TO [public]
GRANT SELECT ON  [dbo].[PMRequestForQuote] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMRequestForQuote] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMRequestForQuote] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMRequestForQuote] TO [Viewpoint]
GO
