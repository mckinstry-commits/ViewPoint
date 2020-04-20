SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMInvoiceDetail]
AS
SELECT *
FROM dbo.vSMInvoiceDetail
GO
GRANT SELECT ON  [dbo].[SMInvoiceDetail] TO [public]
GRANT INSERT ON  [dbo].[SMInvoiceDetail] TO [public]
GRANT DELETE ON  [dbo].[SMInvoiceDetail] TO [public]
GRANT UPDATE ON  [dbo].[SMInvoiceDetail] TO [public]
GO
