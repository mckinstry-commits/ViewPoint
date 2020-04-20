SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  view [dbo].[vrvSMWorkOrderCountByTechnician]
as

/***********************************************************
* CREATED BY:  HH 10/07/2011
* MODIFIED By: 
*
* USAGE:
* This view lists all SM Technicians and the count of their related 
* SM Work Orders where they are "Lead Technicians" or have "Trips" 
* and "Work Completed" assigned. In addition WOAttention is the count
* of Work Orders whose Work Scope is Due or a Billing is ready.
* 
* Report usage:
* SMWorkOrderStatusByTechnician.rpt
*
*****************************************************/

WITH cte 
     AS (SELECT c.SMCo, 
                c.Technician, 
                (SELECT COUNT(WorkOrder) 
                 FROM   (SELECT DISTINCT ia.* 
                         FROM   (SELECT t.SMCo, 
                                        t.Technician, 
                                        wo.WorkOrder 
                                 FROM   SMTechnician t 
                                        INNER JOIN SMWorkOrder wo 
                                          ON t.SMCo = wo.SMCo 
                                             AND 
                                 t.Technician = wo.LeadTechnician 
                                 UNION ALL 
                                 SELECT t.SMCo, 
                                        t.Technician, 
                                        tr.WorkOrder 
                                 FROM   SMTechnician t 
                                        INNER JOIN SMTrip tr 
                                          ON t.SMCo = tr.SMCo 
                                             AND t.Technician = tr.Technician 
                                 UNION ALL 
                                 SELECT t.SMCo, 
                                        t.Technician, 
                                        wc.WorkOrder 
                                 FROM   SMTechnician t 
                                        INNER JOIN SMWorkCompleted wc 
                                          ON t.SMCo = wc.SMCo 
                                             AND t.Technician = wc.Technician) 
                                ia 
                         WHERE  c.SMCo = ia.SMCo 
                                AND c.Technician = ia.Technician) ib) AS WOCount 
                , 
                SUM(c.Attention) 
                AS WOAttention 
         FROM   (SELECT a.SMCo, 
                        a.Technician, 
                        WorkOrder, 
                        MAX(a.Attention) AS Attention 
                 FROM   (SELECT SMCo, 
                                Technician, 
                                WorkOrder, 
                                CASE 
                                  WHEN DueAttention > 0 
                                        OR BillingAttention > 0 THEN 1 
                                  ELSE 0 
                                END AS Attention 
                         FROM   vrvSMWorkOrderStatusByTechnician) a 
                 GROUP  BY SMCo, 
                           Technician, 
                           WorkOrder) c 
         GROUP  BY SMCo, 
                   Technician) 
SELECT * 
FROM   cte 



GO
GRANT SELECT ON  [dbo].[vrvSMWorkOrderCountByTechnician] TO [public]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderCountByTechnician] TO [public]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderCountByTechnician] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderCountByTechnician] TO [public]
GRANT SELECT ON  [dbo].[vrvSMWorkOrderCountByTechnician] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderCountByTechnician] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderCountByTechnician] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderCountByTechnician] TO [Viewpoint]
GO
