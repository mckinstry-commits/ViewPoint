SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    View [dbo].[brvJCEstCostItem] 
     AS 
    /*
    
     SELECT 
     a.JCCo,b.Contract, b.Item,OrigHours=Sum(a.OrigHours),OrigUnits=Sum(a.OrigUnits),
     OrigCost=Sum(a.OrigCost)
     FROM JCCH a 
     INNER JOIN JCJP b ON a.JCCo=b.JCCo AND a.Job=b.Job AND a.PhaseGroup=b.PhaseGroup 
     AND a.Phase=b.Phase
     GROUP BY a.JCCo, b.Contract,b.Item
    */
    

SELECT Sort='A', a.JCCo, a.Contract, JCCH.Job, a.Item, OrigHours=JCCH.OrigHours, 
     OrigUnits=JCCH.OrigUnits, OrigCost=JCCH.OrigCost,
     ACO = Null, ACOItem = NULL, Month =isnull(a.StartMonth,'1/1/1950'), ContractAmt=a.OrigContractAmt, 
     a.Description, EstCost=0
     FROM JCCI a 
     Left join (select b.JCCo, p.Contract, b.Job, p.Item, OrigHours=sum(OrigHours), OrigUnits=sum(OrigUnits), OrigCost=sum(OrigCost)
                from JCCH b
                left join JCJP p on b.JCCo=p.JCCo and b.Job=p.Job and b.PhaseGroup=p.PhaseGroup and b.Phase=p.Phase
                group by b.JCCo, p.Contract, b.Job, p.Item) as JCCH
                on JCCH.JCCo=a.JCCo and JCCH.Contract=a.Contract and JCCH.Item=a.Item

Union all

select Sort='C', c.JCCo, c.Contract, JCOD.Job, c.Item, 0, 0, 0, c.ACO, c.ACOItem, c.ApprovedMonth, c.ContractAmt, 
     c.Description,JCOD.EstCost
	 from JCOI c
     left join (select j.JCCo, p.Contract, j.Job, p.Item, j.ACO, j.ACOItem, EstCost=sum(j.EstCost)
                from JCOD j 
                left join JCJP p on j.JCCo=p.JCCo and j.Job=p.Job
                group by j.JCCo, p.Contract, j.Job, p.Item, j.ACO, j.ACOItem) as JCOD
                on JCOD.JCCo=c.JCCo and JCOD.Contract=c.Contract and JCOD.Item=c.Item

GO
GRANT SELECT ON  [dbo].[brvJCEstCostItem] TO [public]
GRANT INSERT ON  [dbo].[brvJCEstCostItem] TO [public]
GRANT DELETE ON  [dbo].[brvJCEstCostItem] TO [public]
GRANT UPDATE ON  [dbo].[brvJCEstCostItem] TO [public]
GRANT SELECT ON  [dbo].[brvJCEstCostItem] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJCEstCostItem] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJCEstCostItem] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJCEstCostItem] TO [Viewpoint]
GO
