SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







create view [dbo].[WFProcessDetailStepHistory] as select a.* from dbo.vWFProcessDetailStepHistory a







GO
GRANT SELECT ON  [dbo].[WFProcessDetailStepHistory] TO [public]
GRANT INSERT ON  [dbo].[WFProcessDetailStepHistory] TO [public]
GRANT DELETE ON  [dbo].[WFProcessDetailStepHistory] TO [public]
GRANT UPDATE ON  [dbo].[WFProcessDetailStepHistory] TO [public]
GO