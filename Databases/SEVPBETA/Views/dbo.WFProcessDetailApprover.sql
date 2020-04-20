SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[WFProcessDetailApprover] as select a.* From vWFProcessDetailApprover a

GO
GRANT SELECT ON  [dbo].[WFProcessDetailApprover] TO [public]
GRANT INSERT ON  [dbo].[WFProcessDetailApprover] TO [public]
GRANT DELETE ON  [dbo].[WFProcessDetailApprover] TO [public]
GRANT UPDATE ON  [dbo].[WFProcessDetailApprover] TO [public]
GO
