SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[PMOPTotalsForCOR]  AS 
/*****************************************
* Created:	GP 03/15/2011
* Modified:	GP 05/12/2011 - updated view to accurately reflect approved amounts, also to match CCO
*			GF 02/01/2012 TK-12209 #145678 use table not views performance problem with data type security
*
*
* Provides a view of PM PCO Totals for use in
* PM Change Order Request. Need this view to be able to
* filter by PMCo, Contract, and COR.
*
*****************************************/

---- 145678 changed to use tables
select top 100 percent p.PMCo, p.[Contract], p.COR, 
	isnull(sum(case oi.FixedAmountYN when 'Y' then oi.FixedAmount else oi.PendingAmount end), 0) as [RevTotal], 
	isnull(approved.ACORevTotal, 0) - isnull(sum(oi.ApprovedAmt), 0) as [ACORevTotal],
	isnull(sum(oi.ChangeDays), 0) as [ChangeInDays]
from dbo.vPMChangeOrderRequest p
join dbo.vPMChangeOrderRequestPCO o on o.PMCo=p.PMCo and o.[Contract]=p.[Contract] and o.COR=p.COR
join dbo.bPMOI oi on oi.PMCo=o.PMCo and oi.Project=o.Project and oi.PCOType=o.PCOType and oi.PCO=o.PCO
inner join (select top 100 percent p.PMCo, p.[Contract], p.COR,
			isnull(sum(oi.ApprovedAmt), 0) as [ACORevTotal]
			from dbo.vPMChangeOrderRequest p
			join dbo.bPMOI oi on oi.PMCo=p.PMCo and oi.[Contract]=p.[Contract]
			group by p.PMCo, p.[Contract], p.COR) approved
	on approved.PMCo=p.PMCo and approved.[Contract]=p.[Contract] and approved.COR=p.COR
where oi.PCO is not null
group by p.PMCo, p.[Contract], p.COR, approved.ACORevTotal







GO
GRANT SELECT ON  [dbo].[PMOPTotalsForCOR] TO [public]
GRANT INSERT ON  [dbo].[PMOPTotalsForCOR] TO [public]
GRANT DELETE ON  [dbo].[PMOPTotalsForCOR] TO [public]
GRANT UPDATE ON  [dbo].[PMOPTotalsForCOR] TO [public]
GRANT SELECT ON  [dbo].[PMOPTotalsForCOR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMOPTotalsForCOR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMOPTotalsForCOR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMOPTotalsForCOR] TO [Viewpoint]
GO
