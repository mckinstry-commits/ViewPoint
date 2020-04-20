SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE view [dbo].[WFProcessDetailHistory] as select a.* from dbo.vWFProcessDetailHistory a







GO
GRANT SELECT ON  [dbo].[WFProcessDetailHistory] TO [public]
GRANT INSERT ON  [dbo].[WFProcessDetailHistory] TO [public]
GRANT DELETE ON  [dbo].[WFProcessDetailHistory] TO [public]
GRANT UPDATE ON  [dbo].[WFProcessDetailHistory] TO [public]
GRANT SELECT ON  [dbo].[WFProcessDetailHistory] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WFProcessDetailHistory] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WFProcessDetailHistory] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WFProcessDetailHistory] TO [Viewpoint]
GO
