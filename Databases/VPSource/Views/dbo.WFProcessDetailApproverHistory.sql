SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







create view [dbo].[WFProcessDetailApproverHistory] as select a.* from dbo.vWFProcessDetailApproverHistory a







GO
GRANT SELECT ON  [dbo].[WFProcessDetailApproverHistory] TO [public]
GRANT INSERT ON  [dbo].[WFProcessDetailApproverHistory] TO [public]
GRANT DELETE ON  [dbo].[WFProcessDetailApproverHistory] TO [public]
GRANT UPDATE ON  [dbo].[WFProcessDetailApproverHistory] TO [public]
GO
