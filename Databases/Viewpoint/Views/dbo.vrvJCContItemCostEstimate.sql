SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE VIEW [dbo].[vrvJCContItemCostEstimate] 
/************************************************************************************************************************ 
* Initial:
* 3/23/09 - Used on standard report JC Contract Item Cost Estimate Recap until issues 128088 and 131816 are fixed - JH
* 
* Changes:
* 3/24/09 - Added Job - MB 
* 3/25/09 - Changed Month in Change Order section - MB 
* 12/29/10 - #136528 changes for contract amounts select statement: right join JCCI and isnull-check on Job - HH
*
*
************************************************************************************************************************ */
AS 
  --Contract Amounts 
  SELECT DISTINCT Job = Isnull(JCJM.Job, ''), 
                  JCCI.JCCo, 
                  JCCI.Contract, 
                  JCCI.Item, 
                  JCCI.Description, 
                  JCCI.OrigContractAmt, 
                  ACO='', 
                  ACOItem='', 
                  COAmt=0, 
                  COEstCost=0, 
                  OrigEst=0, 
                  Mth=JCCI.StartMonth 
  FROM   JCJM 
         JOIN JCJP 
           ON JCJM.JCCo = JCJP.JCCo 
              AND JCJM.Job = JCJP.Job 
         RIGHT JOIN JCCI 
           ON JCJP.JCCo = JCCI.JCCo 
              AND JCJP.Contract = JCCI.Contract 
              AND JCJP.Item = JCCI.Item 
  UNION ALL 
  --Original Estimates 
  SELECT JCCH.Job, 
         JCCH.JCCo, 
         JCJP.Contract, 
         JCJP.Item, 
         ItemDesc=MAX(JCCI.Description), 
         OrigContractAmt=0, 
         ACO='', 
         ACOItem='', 
         COAmt=0, 
         COEstCost=0, 
         OrigEst=SUM(JCCH.OrigCost), 
         Mth=JCCI.StartMonth 
  FROM   JCCH 
         JOIN JCJP WITH(nolock) 
           ON JCCH.JCCo = JCJP.JCCo 
              AND JCCH.Job = JCJP.Job 
              AND JCCH.PhaseGroup = JCJP.PhaseGroup 
              AND JCCH.Phase = JCJP.Phase 
         JOIN JCCI WITH(nolock) 
           ON JCJP.JCCo = JCCI.JCCo 
              AND JCJP.Contract = JCCI.Contract 
              AND JCJP.Item = JCCI.Item 
  GROUP  BY JCCH.Job, 
            JCCH.JCCo, 
            JCJP.Item, 
            JCJP.Contract, 
            JCCI.StartMonth 
  UNION ALL 
  --Change Orders 
  SELECT JCOI.Job, 
         JCOI.JCCo, 
         JCOI.Contract, 
         JCOI.Item, 
         ItemDesc=MAX(JCCI.Description), 
         OrigContractAmt=0, 
         JCOI.ACO, 
         JCOI.ACOItem, 
         COAmt=SUM(JCOI.ContractAmt), 
         COEstCost=SUM(Isnull(d.COEstCost, 0)), 
         OrigEst=0, 
         Mth=Isnull(JCOI.ApprovedMonth, (SELECT StartMonth 
                                         FROM   JCCM 
                                         WHERE  JCCo = JCOI.JCCo 
                                                AND [Contract] = JCOI.Contract)) 
  FROM   JCOI WITH(nolock) 
         JOIN JCCI WITH(nolock) 
           ON JCOI.JCCo = JCCI.JCCo 
              AND JCOI.Contract = JCCI.Contract 
              AND JCOI.Item = JCCI.Item 
         LEFT JOIN (SELECT JCOD.JCCo, 
                           JCJM.Job, 
                           JCJM.Contract, 
                           JCOD.ACO, 
                           JCOD.ACOItem, 
                           COEstCost=SUM(JCOD.EstCost) 
                    FROM   JCOD WITH(nolock) 
                           JOIN JCJM WITH(nolock) 
                             ON JCOD.JCCo = JCJM.JCCo 
                                AND JCOD.Job = JCJM.Job 
                    GROUP  BY JCOD.JCCo, 
                              JCJM.Job, 
                              JCJM.Contract, 
                              JCOD.ACO, 
                              JCOD.ACOItem) AS d 
           ON d.JCCo = JCOI.JCCo 
              AND d.Contract = JCOI.Contract 
              AND d.ACO = JCOI.ACO 
              AND d.ACOItem = JCOI.ACOItem 
              AND d.Job = JCOI.Job 
  GROUP  BY JCOI.Job, 
            JCOI.JCCo, 
            JCOI.Item, 
            JCOI.Contract, 
            JCOI.ACO, 
            JCOI.ACOItem, 
            JCOI.ApprovedMonth, 
            JCCI.StartMonth 


GO
GRANT SELECT ON  [dbo].[vrvJCContItemCostEstimate] TO [public]
GRANT INSERT ON  [dbo].[vrvJCContItemCostEstimate] TO [public]
GRANT DELETE ON  [dbo].[vrvJCContItemCostEstimate] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCContItemCostEstimate] TO [public]
GO
