SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  view [dbo].[brvARRTRecap]  as
/*******************************************
* Created: JRE 5/19/04
* Modified: CR - #122854 - Customer Name View is now used in subreport of AR Customer Accounts by Customer  
*			GG 04/10/08 - added top 100 percent and order by
*
* Used for the AR Receivable Type Recap 
*
*******************************************/

SELECT top 100 percent l.ARCo, l.Mth, l.RecType, h.ARTransType, Amount=sum(l.Amount), 
       Retainage=sum(l.Retainage),
       t.Description, t.GLARAcct, t.GLRetainAcct, c.Customer, c.Name, c.SortName
FROM ARTL l 
/*left*/ Join ARRT t ON  l.ARCo = t.ARCo AND  l.RecType = t.RecType
left JOIN ARTH h ON l.ARCo = h.ARCo AND l.Mth = h.Mth AND l.ARTrans = h.ARTrans
left JOIN ARCM c ON h.CustGroup = c.CustGroup AND h.Customer = c.Customer
group by l.ARCo, l.Mth, l.RecType, h.ARTransType, l.ARTrans,
       t.Description, t.GLARAcct, t.GLRetainAcct, c.Customer, c.Name, c.SortName
order by l.ARCo, l.Mth, l.RecType, h.ARTransType







GO
GRANT SELECT ON  [dbo].[brvARRTRecap] TO [public]
GRANT INSERT ON  [dbo].[brvARRTRecap] TO [public]
GRANT DELETE ON  [dbo].[brvARRTRecap] TO [public]
GRANT UPDATE ON  [dbo].[brvARRTRecap] TO [public]
GRANT SELECT ON  [dbo].[brvARRTRecap] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvARRTRecap] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvARRTRecap] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvARRTRecap] TO [Viewpoint]
GO
