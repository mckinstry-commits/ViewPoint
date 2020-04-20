SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMRequiredTasksExt] AS 

SELECT *, (SELECT WorkOrderQuote FROM dbo.vSMEntity WHERE SMRequiredTasks.SMCo = vSMEntity.SMCo AND SMRequiredTasks.EntitySeq = vSMEntity.EntitySeq) WorkOrderQuote,
(SELECT WorkOrder FROM dbo.vSMEntity WHERE SMRequiredTasks.SMCo = vSMEntity.SMCo AND SMRequiredTasks.EntitySeq = vSMEntity.EntitySeq) WorkOrder
FROM dbo.SMRequiredTasks
GO
GRANT SELECT ON  [dbo].[SMRequiredTasksExt] TO [public]
GRANT INSERT ON  [dbo].[SMRequiredTasksExt] TO [public]
GRANT DELETE ON  [dbo].[SMRequiredTasksExt] TO [public]
GRANT UPDATE ON  [dbo].[SMRequiredTasksExt] TO [public]
GRANT SELECT ON  [dbo].[SMRequiredTasksExt] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMRequiredTasksExt] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMRequiredTasksExt] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMRequiredTasksExt] TO [Viewpoint]
GO
