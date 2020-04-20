SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMWorkOrderQuote] AS SELECT a.* FROM vSMWorkOrderQuote a
GO
GRANT SELECT ON  [dbo].[SMWorkOrderQuote] TO [public]
GRANT INSERT ON  [dbo].[SMWorkOrderQuote] TO [public]
GRANT DELETE ON  [dbo].[SMWorkOrderQuote] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkOrderQuote] TO [public]
GO
