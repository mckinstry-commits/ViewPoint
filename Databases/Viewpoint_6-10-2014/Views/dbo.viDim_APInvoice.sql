SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viDim_APInvoice]

/**************************************************
 * Alterd: DH 6/19/08
 * Modified:      
 * Usage:  Dimension View from AP Transaction Header for use in SSAS Cubes. 
 *         
 *
 ********************************************************/

as

Select	bAPTH.KeyID as APInvoiceID,
		bAPTH.APCo,
		bAPTH.Mth,
		datediff(mm,'1/1/1950',bAPTH.Mth) as MonthID,
		bAPTH.APTrans,
		bAPTH.InvDate,
		datediff(dd,'1/1/1950',bAPTH.InvDate) as InvDateID,
		bAPTH.DueDate,
		datediff(dd,'1/1/1950',bAPTH.DueDate) as DueDateID,
		bAPTH.APRef+isnull(bAPTH.Description,'') as APInvoiceAndDescription
From bAPTH

union all

/*Default 0 ID that links back to Fact Views for non-AP transactions*/
Select  0 as APInvoiceID,
		Null as APCo,
		Null as Mth,
		Null as MonthID,
		Null as APTrans,
		Null as InvDate,
		Null as InvDateID,
		Null as DueDate,
		Null as DueDateID,
		Null as APInvoiceAndDescription

GO
GRANT SELECT ON  [dbo].[viDim_APInvoice] TO [public]
GRANT INSERT ON  [dbo].[viDim_APInvoice] TO [public]
GRANT DELETE ON  [dbo].[viDim_APInvoice] TO [public]
GRANT UPDATE ON  [dbo].[viDim_APInvoice] TO [public]
GRANT SELECT ON  [dbo].[viDim_APInvoice] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_APInvoice] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_APInvoice] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_APInvoice] TO [Viewpoint]
GO
