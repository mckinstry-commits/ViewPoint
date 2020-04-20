SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:	DC 01/08/2007 6.x only
* Modfied By:
*
* Provides a view of SL Subcontract Invoice totals
* for 6.x.
* Returns:
*	SLWH.SLCo
*	SLWH.SL
*	Sum(SLIT.CurCost) as CurCost
*	Sum(SLIT.InvCost) as InvCost
*	sum(SLWI.WCCost) as WCCost
*	sum(SLWI.Purchased) - sum(SLWI.Installed) as StoredMatls
*	sum(SLWI.WCCost) + sum(SLWI.Purchased) - sum(SLWI.Installed) as Total
*	sum(SLWI.WCRetAmt) + sum(SLWI.SMRetAmt) as Retainage
*
*****************************************/

CREATE view [dbo].[SLWHInvoiceTotals] as 

SELECT h.SLCo,
		h.SL,
		h.UserName,
		'CurCost' = isnull(CurCost,0),
		'InvCost' = isnull(InvCost,0),
		'WCCost' = isnull(WCCost,0),
		'StoredMatls' = isnull(StoredMatls,0),
		'Total' = isnull(Total,0),
		'Retainage' = isnull(Retainage,0)
FROM SLWH h
/*Current Contract Cost */
LEFT JOIN (SELECT a.SLCo, a.SL, 
				CurCost=isnull(sum(a.CurCost),0) 
			FROM SLIT a with (Nolock)
			GROUP BY a.SLCo, a.SL)
	cc on cc.SLCo = h.SLCo and cc.SL = h.SL
/* Prev Invoiced*/
LEFT JOIN (SELECT b.SLCo, b.SL,
				InvCost = isnull(sum(b.InvCost),0)
			FROM SLIT b with (nolock)
			GROUP BY b.SLCo, b.SL)
	prvi on prvi.SLCo = h.SLCo and prvi.SL = h.SL
/*Work Completed*/
LEFT JOIN (SELECT c.SLCo, c.SL,
				WCCost = isnull(sum(c.WCCost),0)
			FROM SLWI c with (nolock)
			GROUP BY c.SLCo, c.SL)
	wc on wc.SLCo = h.SLCo and wc.SL = h.SL
/*Stored Matls*/
LEFT JOIN (SELECT d.SLCo, d.SL,
				StoredMatls = isnull(sum(d.Purchased),0)-isnull(sum(d.Installed),0)
			FROM SLWI d with (nolock)
			GROUP BY d.SLCo, d.SL)
	sm on sm.SLCo = h.SLCo and sm.SL = h.SL
/*Total*/
LEFT JOIN (SELECT e.SLCo, e.SL,
				Total = isnull(sum(e.WCCost),0)+(isnull(sum(e.Purchased),0)-isnull(sum(e.Installed),0))
			FROM SLWI e with (nolock)
			GROUP BY e.SLCo, e.SL)
	tl on tl.SLCo = h.SLCo and tl.SL = h.SL
/*Retainage*/
LEFT JOIN (SELECT f.SLCo, f.SL,
				Retainage = isnull(sum(f.WCRetAmt),0)+ isnull(sum(f.SMRetAmt),0)
			FROM SLWI f with (nolock)
			GROUP BY f.SLCo, f.SL)
	rt on rt.SLCo = h.SLCo and rt.SL = h.SL

GROUP BY h.SLCo, h.SL, h.UserName, CurCost, InvCost, WCCost, StoredMatls, Total, Retainage

GO
GRANT SELECT ON  [dbo].[SLWHInvoiceTotals] TO [public]
GRANT INSERT ON  [dbo].[SLWHInvoiceTotals] TO [public]
GRANT DELETE ON  [dbo].[SLWHInvoiceTotals] TO [public]
GRANT UPDATE ON  [dbo].[SLWHInvoiceTotals] TO [public]
GO
