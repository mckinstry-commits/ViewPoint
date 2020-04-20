SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WFStatusCodes] as select a.* From vWFStatusCodes a
GO
GRANT SELECT ON  [dbo].[WFStatusCodes] TO [public]
GRANT INSERT ON  [dbo].[WFStatusCodes] TO [public]
GRANT DELETE ON  [dbo].[WFStatusCodes] TO [public]
GRANT UPDATE ON  [dbo].[WFStatusCodes] TO [public]
GO
