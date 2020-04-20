SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvJBJCChangeOrders] as
/*
View was created for Issue# 25958 on 5/28/08 CR
used in report 

*/
select Sort=1, Company=I.JCCo, I.Contract, I.Job, I.Item, I.ACO, I.ACOItem, 'BillMonth' = '1/1/1950', 'BillNumber'= Null, 
 I.ContractAmt, ChgOrderAmt = 0, Description
from JCOI I


Union all

select Sort=2, S.JBCo, S.Contract, S.Job, S.Item, S.ACO, S.ACOItem, S.BillMonth, S.BillNumber, 
null, S.ChgOrderAmt,null 
from JBIS S

GO
GRANT SELECT ON  [dbo].[brvJBJCChangeOrders] TO [public]
GRANT INSERT ON  [dbo].[brvJBJCChangeOrders] TO [public]
GRANT DELETE ON  [dbo].[brvJBJCChangeOrders] TO [public]
GRANT UPDATE ON  [dbo].[brvJBJCChangeOrders] TO [public]
GRANT SELECT ON  [dbo].[brvJBJCChangeOrders] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJBJCChangeOrders] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJBJCChangeOrders] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJBJCChangeOrders] TO [Viewpoint]
GO
