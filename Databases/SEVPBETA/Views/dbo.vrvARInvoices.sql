SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[vrvARInvoices] 
/******************

vrvARInvoices created for AR Customer Drilldown to add attachments
12/20/07 CR  


used in ARCustDrill.rpt and ARCustPayDrill.rpt
*****************/

as

select Sort=1, l.ARCo, l.Mth, l.ARTrans, h.ARTransType, l.ARLine, l.RecType, l.LineType, LineDesc=l.Description, l.TaxCode, l.Amount, l.TaxAmount, 
       l.Retainage, l.DiscOffered, l.TaxDisc, l.DiscTaken, l.ApplyMth, l.ApplyTrans, l.Contract, l.Item, LineNotes=l.Notes,
       h.CustGroup, h.Customer, h.Invoice, h.CheckNo, h.TransDate, h.DueDate, h.CheckDate, HeaderDesc=h.Description, HeaderNotes=h.Notes, h.ExcludeFC,
       UniqueAttchID=null, AttachmentID=null,HQATDescription=null,DocName=null

from ARTL l
join ARTH h with (nolock) on l.ARCo=h.ARCo and l.Mth=h.Mth and l.ARTrans=h.ARTrans

union all

select distinct 2, ARTH.ARCo, ARTH.Mth, ARTH.ARTrans, ARTH.ARTransType, null, null, null, null, null, null, null, 
       null, null, null, null, ARTL.ApplyMth, ARTL.ApplyTrans, ARTL.Contract, null, null,
       ARTH.CustGroup, ARTH.Customer, ARTH.Invoice, null, ARTH.TransDate, ARTH.DueDate, ARTH.CheckDate, ARTH.Description, null, null,
       ARTH.UniqueAttchID, HQAT.AttachmentID, HQAT.Description, HQAT.DocName

from ARTH
join ARTL with (nolock) on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans
join HQAT with (nolock) on HQAT.UniqueAttchID=ARTH.UniqueAttchID

GO
GRANT SELECT ON  [dbo].[vrvARInvoices] TO [public]
GRANT INSERT ON  [dbo].[vrvARInvoices] TO [public]
GRANT DELETE ON  [dbo].[vrvARInvoices] TO [public]
GRANT UPDATE ON  [dbo].[vrvARInvoices] TO [public]
GO
