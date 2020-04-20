USE [Viewpoint]
GO

/****** Object:  View [dbo].[mckSMWorkOrderInfo]    Script Date: 3/5/2019 11:34:54 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[mckSMWorkOrderInfo] 
   AS

/********************************************************************************************

   Created 01/24/19 Ben Wilson
   
   Return Work Order details concatinated from WOScopes and Divisions
   

********************************************************************************************/

WITH MultiRowWOs AS 
(
SELECT  
      wo.SMCo, wo.WorkOrder
       --, count(distinct wos.ServiceCenter) SCnt
       --, count(distinct Division) DCnt

       FROM dbo.SMWorkOrder wo (NOLOCK) 
       JOIN dbo.SMWorkOrderScope wos (NOLOCK) ON wos.WorkOrder=wo.WorkOrder AND wos.SMCo=wo.SMCo
       GROUP BY wo.SMCo, wo.WorkOrder
       HAVING COUNT(DISTINCT wos.ServiceCenter) > 1 OR COUNT(DISTINCT Division) >1
),
ConcatRows AS (
SELECT DISTINCT ws.SMCo, ws.WorkOrder,dv.ServiceCenter,dv.Division,dp.Department AS SMDept,dp.udGLDept AS GLDept, 'Y' AS Multi
FROM dbo.SMWorkOrder wo
JOIN dbo.SMWorkOrderScope ws ON ws.SMCo = wo.SMCo AND ws.WorkOrder = wo.WorkOrder
JOIN dbo.SMDivision dv ON dv.SMCo = ws.SMCo AND dv.ServiceCenter = ws.ServiceCenter AND dv.Division = ws.Division
JOIN dbo.SMDepartment dp ON dp.SMCo = dv.SMCo AND dp.Department = dv.Department
JOIN MultiRowWOs mr ON wo.SMCo = mr.SMCo AND wo.WorkOrder = mr.WorkOrder
)


SELECT DISTINCT ws.SMCo, ws.WorkOrder,dv.ServiceCenter,dv.Division,dp.Department AS SMDept,dp.udGLDept AS GLDept --, 'N' AS Multi
FROM dbo.SMWorkOrder wo
JOIN dbo.SMWorkOrderScope ws ON ws.SMCo = wo.SMCo AND ws.WorkOrder = wo.WorkOrder
JOIN dbo.SMDivision dv ON dv.SMCo = ws.SMCo AND dv.ServiceCenter = ws.ServiceCenter AND dv.Division = ws.Division
JOIN dbo.SMDepartment dp ON dp.SMCo = dv.SMCo AND dp.Department = dv.Department
WHERE wo.WorkOrder NOT IN (SELECT MultiRowWOs.WorkOrder FROM MultiRowWOs)

UNION

SELECT a.SMCo,a.WorkOrder,
              ServiceCenter = STUFF(( SELECT DISTINCT ',' + ServiceCenter
                           FROM   ConcatRows AS b
                           WHERE a.WorkOrder = b.WorkOrder 
                           --ORDER BY WorkOrder
                           FOR XML       PATH('')
                           ), 1, 1, '')  ,
						                 Division = STUFF(( SELECT DISTINCT ',' + [Division]
                           FROM   ConcatRows AS b
                           WHERE a.WorkOrder = b.WorkOrder 
                           --ORDER BY WorkOrder
                           FOR XML       PATH('')
                           ), 1, 1, '')
                           ,
                           SMDept = STUFF(( SELECT DISTINCT ',' + SMDept
                           FROM   ConcatRows AS b
                           WHERE a.WorkOrder = b.WorkOrder 
                           --ORDER BY WorkOrder
                           FOR XML       PATH('')
                           ), 1, 1, ''),
                                         GLDept = STUFF(( SELECT    DISTINCT ',' + [GLDept]
                           FROM   ConcatRows AS b
                           WHERE a.WorkOrder = b.WorkOrder 
                           --ORDER BY WorkOrder
                           FOR XML       PATH('')
                           ), 1, 1, '')
FROM ConcatRows a




GO


