SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE view [dbo].[WFProcessHeader] as select a.* from dbo.vWFProcessHeader a







GO
GRANT SELECT ON  [dbo].[WFProcessHeader] TO [public]
GRANT INSERT ON  [dbo].[WFProcessHeader] TO [public]
GRANT DELETE ON  [dbo].[WFProcessHeader] TO [public]
GRANT UPDATE ON  [dbo].[WFProcessHeader] TO [public]
GRANT SELECT ON  [dbo].[WFProcessHeader] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WFProcessHeader] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WFProcessHeader] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WFProcessHeader] TO [Viewpoint]
GO
