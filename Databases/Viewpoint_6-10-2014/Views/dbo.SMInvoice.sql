SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMInvoice] as select a.* From vSMInvoice a
GO
GRANT SELECT ON  [dbo].[SMInvoice] TO [public]
GRANT INSERT ON  [dbo].[SMInvoice] TO [public]
GRANT DELETE ON  [dbo].[SMInvoice] TO [public]
GRANT UPDATE ON  [dbo].[SMInvoice] TO [public]
GRANT SELECT ON  [dbo].[SMInvoice] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMInvoice] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMInvoice] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMInvoice] TO [Viewpoint]
GO
