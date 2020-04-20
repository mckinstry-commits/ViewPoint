SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE view [dbo].[SLWIInvoices] as select a.* From vSLWIInvoices a






GO
GRANT SELECT ON  [dbo].[SLWIInvoices] TO [public]
GRANT INSERT ON  [dbo].[SLWIInvoices] TO [public]
GRANT DELETE ON  [dbo].[SLWIInvoices] TO [public]
GRANT UPDATE ON  [dbo].[SLWIInvoices] TO [public]
GO
