SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APRLTotals] 
/********************************
* Created:	 MV 06/14/05
* Modified: GG 04/10/08 - added order by
*			MV 09/16/09 - #131819 - add Net Amount
*
* Purpose:	 to display line totals in APRecuInv
*
**********************************/
   
as
select top 100 percent l.APCo, VendorGroup, Vendor, InvId,
        'TotalGross'= sum(GrossAmt),
        'TotalFreightTax'= sum(MiscAmt + TaxAmt),
		'TotalRetgDisc' = sum(Retainage + Discount),
		'TotalPayable' = sum (GrossAmt + TaxAmt + MiscAmt),
		'TotalNetAmount' = sum ((GrossAmt + TaxAmt + MiscAmt) - (Retainage + Discount))
					
from APRL l (nolock)
join APCO c  (nolock) on l.APCo=c.APCo
group by l.APCo, VendorGroup, Vendor, InvId 
order by l.APCo, VendorGroup, Vendor, InvId

GO
GRANT SELECT ON  [dbo].[APRLTotals] TO [public]
GRANT INSERT ON  [dbo].[APRLTotals] TO [public]
GRANT DELETE ON  [dbo].[APRLTotals] TO [public]
GRANT UPDATE ON  [dbo].[APRLTotals] TO [public]
GO
