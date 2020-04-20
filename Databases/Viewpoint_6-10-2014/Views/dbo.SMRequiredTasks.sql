SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMRequiredTasks] AS SELECT a.* FROM vSMRequiredTasks a
GO
GRANT SELECT ON  [dbo].[SMRequiredTasks] TO [public]
GRANT INSERT ON  [dbo].[SMRequiredTasks] TO [public]
GRANT DELETE ON  [dbo].[SMRequiredTasks] TO [public]
GRANT UPDATE ON  [dbo].[SMRequiredTasks] TO [public]
GRANT SELECT ON  [dbo].[SMRequiredTasks] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMRequiredTasks] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMRequiredTasks] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMRequiredTasks] TO [Viewpoint]
GO
