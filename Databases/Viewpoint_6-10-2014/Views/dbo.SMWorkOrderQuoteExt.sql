SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create VIEW [dbo].[SMWorkOrderQuoteExt]
AS 
SELECT 
	a.*
	, CASE --(A)pproved, (C)anceled, (O)pen
		WHEN (a.DateCanceled IS NULL AND a.DateApproved IS NOT NULL) THEN 'A'
		WHEN (a.DateCanceled IS NOT NULL AND a.DateApproved IS NULL) THEN 'C'
		ELSE 'N' END as Status				
FROM vSMWorkOrderQuote a
GO
GRANT SELECT ON  [dbo].[SMWorkOrderQuoteExt] TO [public]
GRANT INSERT ON  [dbo].[SMWorkOrderQuoteExt] TO [public]
GRANT DELETE ON  [dbo].[SMWorkOrderQuoteExt] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkOrderQuoteExt] TO [public]
GRANT SELECT ON  [dbo].[SMWorkOrderQuoteExt] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMWorkOrderQuoteExt] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMWorkOrderQuoteExt] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMWorkOrderQuoteExt] TO [Viewpoint]
GO
