SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[viFact_JCForecast]

/**************************************************
 * Created: DH 7/26/11  B-04363
 * Modified:      
 *
 * View that provides the forecast measures for the Job Cost Cube.  
 * 
 * KeyIDs selected from maintenance tables to use in Cube Dimension/Fact relationships.
 * 
 ***************************************************/
AS

--Return Forecast percentages by JC Company, Contract, and ForecastMonth
WITH cteEstCostContract (JCCo, Contract, Mth, CurrEstCost)

AS

(SELECT JCCP.JCCo, JCJP.Contract, JCCP.Mth,
        sum(JCCP.CurrEstCost) as CurrEstCost
   FROM JCCP WITH (NOLOCK)
   INNER JOIN JCJP WITH (NOLOCK) ON
		 JCJP.JCCo = JCCP.JCCo AND
		 JCJP.Job = JCCP.Job AND
		 JCJP.PhaseGroup = JCCP.PhaseGroup AND
		 JCJP.Phase = JCCP.Phase
    GROUP BY JCCP.JCCo, JCJP.Contract, JCCP.Mth		 
		 ),
			 
cteJCFCMth ( ForecastMonth, RevenuePct, CostPct, JCCo, [Contract], MthNum, CurrEstCostToDate )
          AS
(SELECT   ForecastMonth,
                        RevenuePct,
                        CostPct,
                        -- we need our joining clause
                        vJCForecastMonth.JCCo,
                        vJCForecastMonth.[Contract],
                        -- this is what numbers we are going to partition (reset) by each JCCo and Contract
                        ROW_NUMBER() OVER ( PARTITION BY vJCForecastMonth.JCCo, vJCForecastMonth.[Contract] ORDER BY ForecastMonth ),
                        sum(prev.CurrEstCost) as CurrEstCostToDate
               FROM     dbo.vJCForecastMonth WITH (NOLOCK)
               LEFT OUTER JOIN cteEstCostContract prev ON
					prev.JCCo = dbo.vJCForecastMonth.JCCo AND
					prev.Contract = dbo.vJCForecastMonth.Contract AND
					prev.Mth <= vJCForecastMonth.ForecastMonth
					
				
   Group By 	ForecastMonth,
                        RevenuePct,
                        CostPct,
                        -- we need our joining clause
                        vJCForecastMonth.JCCo,
                        vJCForecastMonth.[Contract]),
--Return the last month to which actual cost is posted.  Used to calculate remaining percent
cteLastContractCost (JCCo, Contract, LastCostMth)
		AS (SELECT bJCCP.JCCo, bJCJP.Contract, max(bJCCP.Mth)
			  From bJCCP WITH (NOLOCK)
			  Join bJCJP WITH (NOLOCK) on bJCJP.JCCo = bJCCP.JCCo and
						   bJCJP.Job = bJCCP.Job and
						   bJCJP.PhaseGroup = bJCCP.PhaseGroup and
						   bJCJP.Phase = bJCCP.Phase	   	
			  Join bJCCM WITH (NOLOCK) on bJCCM.JCCo = bJCJP.JCCo and
						   bJCCM.Contract = bJCJP.Contract	
		     WHERE bJCCP.ActualCost<>0						   			   
			 
			GROUP BY bJCCP.JCCo, bJCJP.Contract),

/*CTE returns forecast percentages and amounts adjusted by month (current - previous)
  RemainingPctFromLastCostMth = total remaining forecast percent of all months later than the
								last month to which actual cost is posted.
*/			

--CTE that returns the first contract item by Contract.  Allows returning key ID for the first contract item
--so that it can related to the JC DeptContract Hierarchy dimension
cteContract (JCCo, Contract, FirstContractItem)

as

(select JCCo, Contract, min(Item) 
 From JCCI WITH (NOLOCK) 
 Group by JCCo, Contract),
					
  
cteForecastData (JCCompany, Contract, FirstContractItem, Department, ProjectMgr, ForecastMonth
				, RevenuePcttoDate, RevenuePctMonth
				, RevenueEstMonth, CostPcttoDate, CostPctMonth, CostEstMonth
				, LastCostMth, RemainingRevenuePct, RemainingCostPct
				 )

AS

(SELECT  c.JCCo AS JCCompany,
		c.Contract,
		c.FirstContractItem,
		i.Department,
        j.ProjectMgr,
        fm.ForecastMonth AS ForecastMonth,
        fm.RevenuePct AS RevenuePcttoDate,
        fm.RevenuePct - ISNULL(prevMon.RevenuePct, 0) AS RevenuePctMonth,
        fr.ForecastMthRevenue as RevenueEstMonth,
        fm.CostPct AS CostPcttoDate,
        fm.CostPct - ISNULL(prevMon.CostPct, 0) AS CostPctMonth,
        (fm.CurrEstCostToDate * fm.CostPct) - ISNULL(prevMon.CurrEstCostToDate,0) * ISNULL(prevMon.CostPct,0) as CostEstMonth,
        lcc.LastCostMth,
        ( 1 - jcf.RevenuePct ) AS RemainingRevenuePct,
        ( 1 - jcf.CostPct) AS RemainingCostPct
   
					 
FROM    cteContract c WITH (NOLOCK)
		INNER JOIN dbo.bJCCI i WITH (NOLOCK) ON i.JCCo = c.JCCo
								AND  i.Contract = c.Contract
								AND  i.Item = c.FirstContractItem
        INNER JOIN dbo.bJCJM j WITH (NOLOCK) ON c.JCCo = j.JCCo
                                 AND c.Contract = j.Contract
        LEFT JOIN dbo.bJCMP WITH (NOLOCK) ON j.ProjectMgr = bJCMP.ProjectMgr
                               AND j.JCCo = bJCMP.JCCo
		                              
        INNER JOIN cteJCFCMth fm ON c.JCCo = fm.JCCo
                                    AND c.Contract = fm.Contract
		LEFT JOIN  cteLastContractCost lcc on lcc.JCCo = c.JCCo
										AND lcc.Contract = c.Contract
        LEFT JOIN cteJCFCMth prevMon ON c.JCCo = prevMon.JCCo
                                        AND c.Contract = prevMon.Contract
                                                            -- notice we need to go back a month here
                                        AND ( fm.MthNum - 1 ) = prevMon.MthNum
        INNER JOIN dbo.JCForecastTotalsRev fr ON fm.JCCo = fr.JCCo
                                                 AND fm.Contract = fr.Contract
                                                 AND fm.ForecastMonth = fr.ForecastMonth
        INNER JOIN dbo.JCForecastTotalsCost fc ON fm.JCCo = fc.JCCo
                                                  AND fm.Contract = fc.Contract
                                                  AND fm.ForecastMonth = fc.ForecastMonth
          
        LEFT JOIN dbo.vJCForecastMonth jcf WITH (NOLOCK) ON jcf.JCCo = lcc.JCCo
                                             AND jcf.Contract = lcc.Contract  
                                                                        
                                             AND jcf.ForecastMonth = lcc.LastCostMth


)
/*Final Select
  AdjustedCostPctMth = "weighted" percent of each forecast month remaining.
  Pct of each month divided by Remaining Percent from Last Cost Month
  */
select  bJCCO.KeyID as JCCoID,
		bJCCM.KeyID as ContractID,
		isnull(bARCM.KeyID,0) as CustomerID,
		bJCDM.KeyID as JCDeptID,
		isnull(bJCMP.KeyID,0) as ProjectMgrID,
        bJCCI.KeyID as DeptContractHierarchyID,
		isnull(Cast(cast(bJCCO.GLCo as varchar(3))+cast(Datediff(dd,'1/1/1950',a.ForecastMonth) as varchar(10)) as int),0) as FiscalMthID,
		a.ForecastMonth,
		a.RevenuePcttoDate,
		a.RevenuePctMonth,
		a.RevenueEstMonth,
		a.CostPcttoDate,
		a.CostPctMonth,
		a.CostEstMonth,
		a.LastCostMth,
		case when a.ForecastMonth > a.LastCostMth then
			a.RemainingRevenuePct
		else 0 end as TotalRemainRevenuePct,
		case when a.ForecastMonth > a.LastCostMth then
			a.RemainingCostPct
		else 0 end as TotalRemainCostPct,
		Cast(case when a.ForecastMonth > a.LastCostMth and a.RemainingCostPct<>0
			then a.CostPctMonth/RemainingCostPct
		else 0 end as decimal (10,4)) as AdjustedCostPctMonth,
		Cast(case when a.ForecastMonth > a.LastCostMth and a.RemainingRevenuePct<>0
			then a.RevenuePctMonth/RemainingRevenuePct
		else 0 end as decimal (10,4)) as AdjustedRevenuePctMonth		
		
FROM cteForecastData a
INNER JOIN dbo.bJCCI WITH (NOLOCK) ON bJCCI.JCCo = a.JCCompany
								  AND bJCCI.Contract = a.Contract
								  AND bJCCI.Item = a.FirstContractItem
INNER JOIN bJCCO WITH (NOLOCK) ON  a.JCCompany = bJCCO.JCCo
INNER JOIN vDDBICompanies WITH (NOLOCK) ON vDDBICompanies.Co = a.JCCompany
INNER JOIN bJCCM WITH (NOLOCK) ON  a.JCCompany = bJCCM.JCCo
				 AND a.Contract = bJCCM.Contract
LEFT JOIN bARCM WITH (NOLOCK) ON bARCM.CustGroup = bJCCM.CustGroup
							 AND bARCM.Customer = bJCCM.Customer				 
INNER JOIN bJCDM WITH (NOLOCK) ON  a.JCCompany = bJCDM.JCCo
				 AND a.Department = bJCDM.Department

LEFT JOIN bJCMP WITH (NOLOCK) ON bJCMP.JCCo=a.JCCompany 
				AND bJCMP.ProjectMgr=a.ProjectMgr		
						 
				 

		

GO
GRANT SELECT ON  [dbo].[viFact_JCForecast] TO [public]
GRANT INSERT ON  [dbo].[viFact_JCForecast] TO [public]
GRANT DELETE ON  [dbo].[viFact_JCForecast] TO [public]
GRANT UPDATE ON  [dbo].[viFact_JCForecast] TO [public]
GO
