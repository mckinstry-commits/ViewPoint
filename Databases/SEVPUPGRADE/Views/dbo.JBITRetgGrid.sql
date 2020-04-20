SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBITRetgGrid]
/*************************************************************************
* Created: ?? ??/??/??: Issue #_____, Unknown
* Modified: TJL 03/01/05:  Issue #26761, Add this Remarks area
*		GG 04/10/08 - added top 100 percent and order by
*		TJL 08/14/08 - Issue #128370, JB International Sales Tax
*		
*
* Provides a view for JB Release Retainage (JBIT) that fills a grid on
* the JB Release Retainage form.
*
*
**************************************************************************/ 

as 
select top 100 percent 'co' = t.JBCo, 'mth' = t.BillMonth, 'billnum' = t.BillNumber, t.Item, t.Description,
   	'openretg' = min(t.PrevRetg) + t.RetgBilled - min(t.PrevRetgReleased),
	'openretgtax' = min(t.PrevRetgTax) + t.RetgTax - min(t.PrevRetgTaxRel),
   	'prevretgrel' = min(t.PrevRetgReleased),
	'prevretgtaxrel' = min(t.PrevRetgTaxRel),
   	'retgpct' =  case n.RevRelRetgYN when 'N' then
   		case min(t.PrevRetg) + t.RetgBilled - min(t.PrevRetgReleased) when 0 then 0
     		else convert(float,(t.RetgRel/(min(t.PrevRetg) + t.RetgBilled - min(t.PrevRetgReleased)))) end
   		else case min(t.PrevRetgReleased) when 0 then 0
   			else convert(float,-(t.RetgRel/min(t.PrevRetgReleased))) end end,
   	t.RetgRel, t.AmountDue,
   	amtdue = min(t.WC) + min(t.TaxAmount) - min(t.WCRetg) + min(t.SM) - min(t.SMRetg)
from JBIT t (nolock)
join JBIN n (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
group by t.JBCo, t.BillMonth, t.BillNumber, t.Item, t.Description, t.RetgRel,
	t.RetgBilled, t.AmountDue, n.RevRelRetgYN, t.RetgTax
   --having (min(t.PrevRetg) + t.RetgBilled - min(t.PrevRetgReleased)) <> 0
order by t.JBCo, t.BillMonth, t.BillNumber, t.Item

GO
GRANT SELECT ON  [dbo].[JBITRetgGrid] TO [public]
GRANT INSERT ON  [dbo].[JBITRetgGrid] TO [public]
GRANT DELETE ON  [dbo].[JBITRetgGrid] TO [public]
GRANT UPDATE ON  [dbo].[JBITRetgGrid] TO [public]
GO
