SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





create view [dbo].[WFProcessStep] as select a.* from dbo.vWFProcessStep a





GO
GRANT SELECT ON  [dbo].[WFProcessStep] TO [public]
GRANT INSERT ON  [dbo].[WFProcessStep] TO [public]
GRANT DELETE ON  [dbo].[WFProcessStep] TO [public]
GRANT UPDATE ON  [dbo].[WFProcessStep] TO [public]
GO
