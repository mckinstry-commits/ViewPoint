SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viDim_ARInvoice]
/**************************************************
 * Alterd: DH 6/19/08
 * Modified:      
 * Usage:  Dimension View from AR Transaction Header for use in SSAS Cubes. 
 *         
 *
 ********************************************************/

as

/*Begin AROpen CTE*/
With AROpen
		(ARCo,
		 ApplyMth,
		 ApplyTrans,
		 OpenYN)
as 

(Select bARTL.ARCo,
	   bARTL.ApplyMth,
	   bARTL.ApplyTrans,
	   'Y'	
	   From bARTL with(nolock)
       Join bARTH with(nolock) on bARTH.ARCo=bARTL.ARCo and bARTH.Mth=bARTL.Mth and bARTH.ARTrans=bARTL.ARTrans
  Group By bARTL.ARCo, bARTL.ApplyMth, bARTL.ApplyTrans 
 having sum(bARTL.Amount)<>0)
/*End AROpen CTE*/

select	bARTH.KeyID as ARInvoiceID,
		bARTH.ARCo,
		bARTH.Mth,
		datediff(mm,'1/1/1950',bARTH.Mth) as MonthID,
		bARTH.ARTrans,
		bARTH.Invoice+isnull(bARTH.Description,'') as InvoiceAndDescription,
		bARTH.TransDate as InvoiceDate,
		datediff(dd,'1/1/1950', bARTH.TransDate) as InvDateID,
		bARTH.DueDate,
		datediff(dd,'1/1/1950', bARTH.DueDate) as DueDateID,
		case when AROpen.OpenYN is null then 'N' else AROpen.OpenYN end as OpenYN
From bARTH 
Left Join AROpen on AROpen.ARCo=bARTH.ARCo and AROpen.ApplyMth=bARTH.Mth and AROpen.ApplyTrans=bARTH.ARTrans
Where bARTH.ARTransType='I' --restrict to Invoice type transactions only

union all

/*Default 0 ID that links back to Fact Views for non-AR transactions*/
Select  0 as ARInvoiceID,
		Null as ARCo,
		Null as Mth,
		Null as MonthID,
		Null as ARTrans,
		Null as InvoiceAndDescription,
		Null as InvoiceDate,
		Null as InvDateID,
		Null as DueDate,
		Null as DueDateID,
		Null as OpenYN

GO
GRANT SELECT ON  [dbo].[viDim_ARInvoice] TO [public]
GRANT INSERT ON  [dbo].[viDim_ARInvoice] TO [public]
GRANT DELETE ON  [dbo].[viDim_ARInvoice] TO [public]
GRANT UPDATE ON  [dbo].[viDim_ARInvoice] TO [public]
GO
