SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







create view [dbo].[WFProcessHeader] as select a.* from dbo.vWFProcessHeader a







GO
GRANT SELECT ON  [dbo].[WFProcessHeader] TO [public]
GRANT INSERT ON  [dbo].[WFProcessHeader] TO [public]
GRANT DELETE ON  [dbo].[WFProcessHeader] TO [public]
GRANT UPDATE ON  [dbo].[WFProcessHeader] TO [public]
GO
