SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WFChecklistTasks] as select a.* From vWFChecklistTasks a
GO
GRANT SELECT ON  [dbo].[WFChecklistTasks] TO [public]
GRANT INSERT ON  [dbo].[WFChecklistTasks] TO [public]
GRANT DELETE ON  [dbo].[WFChecklistTasks] TO [public]
GRANT UPDATE ON  [dbo].[WFChecklistTasks] TO [public]
GRANT SELECT ON  [dbo].[WFChecklistTasks] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WFChecklistTasks] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WFChecklistTasks] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WFChecklistTasks] TO [Viewpoint]
GO
