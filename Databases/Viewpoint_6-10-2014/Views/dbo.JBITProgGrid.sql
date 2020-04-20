SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBITProgGrid]
/*************************************************************************
* Created: ?? ??/??/??: 	Issue #_____, Unknown
* Modified: TJL 03/01/05:   Issue #26761, Add this Remarks area
*			TJL 02/23/06 - Issue #28051, 6x recode.
*			GG 04/10/08 - added top 100 percent and order by  
*		
* Provides a view for JB Progress Bill Items (JBIT) that fills a grid on
* the JB Progress Bill Items form.
*
*
**************************************************************************/ 
   
as
select top 100 percent t.JBCo, t.BillMonth, t.BillNumber, t.Item, 
	'JCCISICode' = c.SICode, t.Description, 'JCCIUM' = c.UM, 'JCCIUnitPrice' = c.UnitPrice,
	'TotalContractUnits' = t.ContractUnits + isnull(sum(s.ChgOrderUnits),0),
	'TotalContractAmt' = t.CurrContract  + isnull(sum(s.ChgOrderAmt),0),
	t.PrevWCUnits, t.PrevWC,
	'PctComplete' = case c.UM when 'LS' then
	        case (t.CurrContract + isnull(sum(s.ChgOrderAmt),0)) when 0 then 0
	          else
	          convert(float,((t.WC + t.PrevWC)/
	          (t.CurrContract + isnull(sum(s.ChgOrderAmt),0)))) end
	      else
	        case (t.ContractUnits + isnull(sum(s.ChgOrderUnits),0)) when 0 then 0
	          else convert(float,((t.WCUnits + t.PrevWCUnits)/(t.ContractUnits + isnull(sum(s.ChgOrderUnits),0)))) end end,
	'ToDateUnits' = isnull(t.WCUnits,0) + isnull(t.PrevWCUnits,0),
	'ToDateAmt' = isnull(t.WC,0) + isnull(t.PrevWC,0),
	t.WCUnits, t.WC, t.WCRetPct, t.WCRetg, t.PrevSM, t.Purchased, t.Installed, t.SM, 
	t.SMRetg, t.TaxGroup, t.TaxCode, t.TaxBasis, Seq124='', t.TaxAmount, t.RetgRel,
	t.Discount, t.AmountDue, t.PrevWCRetg, t.PrevRetgReleased, t.PrevTax,
	t.PrevDue, t.PrevRetg, t.PrevSMRetg, t.PrevUnits, t.PrevAmt,
	t.RetgBilled, 'col38' = t.WCRetPct, t.ContractUnits, t.CurrContract,
	'JBISChgOrderUnits' = isnull(sum(s.ChgOrderUnits), 0), 'JBISChgOrderAmt' = isnull(sum(s.ChgOrderAmt), 0),
	t.UnitsBilled, t.AmtBilled, 'JCCIBillType' = c.BillType, t.Contract,
	'SMRetgPct' = Case t.SM when 0 then c.RetainPCT else convert(float,(t.SMRetg / t.SM)) end,
	'JCCIRetainPCT' = c.RetainPCT, 'ToDateSM' = isnull(t.SM,0) + isnull(t.PrevSM,0)
from JBIT t (nolock)
join JBIN n (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
join JCCI c (nolock) on n.JBCo = c.JCCo and n.Contract = c.Contract and t.Item = c.Item
join JBIS s (nolock) on s.JBCo = t.JBCo and s.BillMonth = t.BillMonth and s.BillNumber = t.BillNumber and s.Item = t.Item
group by t.JBCo, t.BillMonth, t.BillNumber, t.Item, c.SICode, t.Description, c.UM, c.UnitPrice,
	t.ContractUnits , t.CurrContract, t.PrevWCUnits, t.PrevWC,
	t.WCUnits, t.WC, t.WCRetPct,t.WCRetg,
	t.PrevSM, t.Purchased, t.Installed, t.SM, t.SMRetg,
	t.TaxGroup, t.TaxCode, t.TaxBasis,  t.TaxAmount, t.PrevTax,
	t.Discount, t.AmountDue, t.PrevWCRetg, t.PrevRetgReleased, t.RetgRel,
	t.PrevDue, t.PrevAmt, t.PrevRetg, t.PrevSMRetg, t.PrevUnits, t.RetgBilled, c.RetainPCT,
	t.UnitsBilled, t.AmtBilled, c.BillType, t.Contract, c.BillGroup
order by t.JBCo, t.BillMonth, t.BillNumber, t.Item

GO
GRANT SELECT ON  [dbo].[JBITProgGrid] TO [public]
GRANT INSERT ON  [dbo].[JBITProgGrid] TO [public]
GRANT DELETE ON  [dbo].[JBITProgGrid] TO [public]
GRANT UPDATE ON  [dbo].[JBITProgGrid] TO [public]
GRANT SELECT ON  [dbo].[JBITProgGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBITProgGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBITProgGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBITProgGrid] TO [Viewpoint]
GO
