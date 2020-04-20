SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMInvoiceLine]
AS
SELECT *
FROM dbo.vSMInvoiceLine
GO
GRANT SELECT ON  [dbo].[SMInvoiceLine] TO [public]
GRANT INSERT ON  [dbo].[SMInvoiceLine] TO [public]
GRANT DELETE ON  [dbo].[SMInvoiceLine] TO [public]
GRANT UPDATE ON  [dbo].[SMInvoiceLine] TO [public]
GRANT SELECT ON  [dbo].[SMInvoiceLine] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMInvoiceLine] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMInvoiceLine] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMInvoiceLine] TO [Viewpoint]
GO
