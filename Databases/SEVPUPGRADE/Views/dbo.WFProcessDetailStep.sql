SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[WFProcessDetailStep] as select a.* From vWFProcessDetailStep a

GO
GRANT SELECT ON  [dbo].[WFProcessDetailStep] TO [public]
GRANT INSERT ON  [dbo].[WFProcessDetailStep] TO [public]
GRANT DELETE ON  [dbo].[WFProcessDetailStep] TO [public]
GRANT UPDATE ON  [dbo].[WFProcessDetailStep] TO [public]
GO
