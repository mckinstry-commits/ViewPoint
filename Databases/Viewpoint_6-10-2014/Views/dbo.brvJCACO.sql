SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   View [dbo].[brvJCACO] as
/*********************
   This view is used to grab all ACO's by Contract and Item for use in
   JC Project Status report(removed from report 1/8/07 issue 122466 CR)
   
   *********************/
   select JCCo,Contract, Item,Mth, ACO=MAX(ACO) from JCID where ACO is not null
   Group by JCCo, Contract, Item, Mth

GO
GRANT SELECT ON  [dbo].[brvJCACO] TO [public]
GRANT INSERT ON  [dbo].[brvJCACO] TO [public]
GRANT DELETE ON  [dbo].[brvJCACO] TO [public]
GRANT UPDATE ON  [dbo].[brvJCACO] TO [public]
GRANT SELECT ON  [dbo].[brvJCACO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJCACO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJCACO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJCACO] TO [Viewpoint]
GO
