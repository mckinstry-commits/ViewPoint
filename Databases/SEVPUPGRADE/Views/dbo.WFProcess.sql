SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





create view [dbo].[WFProcess] as select a.* from dbo.vWFProcess a





GO
GRANT SELECT ON  [dbo].[WFProcess] TO [public]
GRANT INSERT ON  [dbo].[WFProcess] TO [public]
GRANT DELETE ON  [dbo].[WFProcess] TO [public]
GRANT UPDATE ON  [dbo].[WFProcess] TO [public]
GO
