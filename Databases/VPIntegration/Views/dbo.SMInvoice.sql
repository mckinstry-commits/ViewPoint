SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[SMInvoice]
AS
SELECT a.* FROM dbo.vSMInvoice a


GO
GRANT SELECT ON  [dbo].[SMInvoice] TO [public]
GRANT INSERT ON  [dbo].[SMInvoice] TO [public]
GRANT DELETE ON  [dbo].[SMInvoice] TO [public]
GRANT UPDATE ON  [dbo].[SMInvoice] TO [public]
GO
