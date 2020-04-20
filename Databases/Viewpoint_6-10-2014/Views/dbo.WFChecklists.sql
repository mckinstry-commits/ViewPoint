SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WFChecklists] as select a.* From vWFChecklists a
GO
GRANT SELECT ON  [dbo].[WFChecklists] TO [public]
GRANT INSERT ON  [dbo].[WFChecklists] TO [public]
GRANT DELETE ON  [dbo].[WFChecklists] TO [public]
GRANT UPDATE ON  [dbo].[WFChecklists] TO [public]
GRANT SELECT ON  [dbo].[WFChecklists] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WFChecklists] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WFChecklists] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WFChecklists] TO [Viewpoint]
GO
