SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  View [dbo].[brvARReceivedTax]    Script Date: 01/28/2009 07:42:12 ******/
CREATE    view [dbo].[brvARReceivedTax]

/******
  Usage:  Used by the AR Sales Tax Received Report.
          View selects one record per payment transaction and applyline.
          Only invoices with paid tax will be returned.  Invoiced amounts also include adjustments,
          credits, and write-offs.  
  Mod:  DH  1/28/2009.  Issue 131400
*******/

 as

select  Paid.ARCo,
		Paid.Mth,
		Paid.TaxGroup,
		TL.TaxCode,
		Paid.TaxAmount as PaidTax,
		Paid.TaxDisc as PaidTaxDisc,
	    TL.ApplyMth,
		TL.ApplyTrans,
		TL.ApplyLine,
	    TL.ARTransType,
		TL.Invoice,
		TL.TransDate,
		TL.InvAmt,
		TL.TaxBasis,
		TL.InvTax,
		TL.InvTaxDisc
From ARTL Paid with (nolock)
Join ARTH with (nolock) on ARTH.ARCo=Paid.ARCo and ARTH.Mth=Paid.Mth and ARTH.ARTrans=Paid.ARTrans
Join (select ARTL.ARCo,
	         ARTL.ApplyMth,
	         ARTL.ApplyTrans,
			 ARTL.ApplyLine,
			 max(case when ARTH.ARTransType='I' then ARTL.TaxCode end) as TaxCode,
	         max(case when ARTH.ARTransType='I' then ARTH.ARTransType end) as ARTransType,  
   	         max(case when ARTH.ARTransType='I' then ARTH.Invoice end) as Invoice,
             max(case when ARTH.ARTransType='I' then ARTH.TransDate end) as TransDate,
             sum(ARTL.Amount) as InvAmt,
             sum(ARTL.TaxBasis) as TaxBasis,
             sum(ARTL.TaxAmount) as InvTax,
             sum(ARTL.TaxDisc) as InvTaxDisc	
          from ARTL with (nolock)
          join ARTH with (nolock) on ARTL.ARCo = ARTH.ARCo and ARTL.Mth = ARTH.Mth and ARTL.ARTrans = ARTH.ARTrans
       where ARTH.ARTransType<>'P'
       group by ARTL.ARCo, ARTL.ApplyMth, ARTL.ApplyTrans, ARTL.ApplyLine) as TL
on TL.ARCo=Paid.ARCo and TL.ApplyMth=Paid.ApplyMth and TL.ApplyTrans=Paid.ApplyTrans and TL.ApplyLine=Paid.ApplyLine
Where ARTH.ARTransType='P'

		
		



GO
GRANT SELECT ON  [dbo].[brvARReceivedTax] TO [public]
GRANT INSERT ON  [dbo].[brvARReceivedTax] TO [public]
GRANT DELETE ON  [dbo].[brvARReceivedTax] TO [public]
GRANT UPDATE ON  [dbo].[brvARReceivedTax] TO [public]
GRANT SELECT ON  [dbo].[brvARReceivedTax] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvARReceivedTax] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvARReceivedTax] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvARReceivedTax] TO [Viewpoint]
GO
