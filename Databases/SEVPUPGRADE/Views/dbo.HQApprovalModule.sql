SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






create view [dbo].[HQApprovalModule] as select a.* from dbo.vHQApprovalModule a






GO
GRANT SELECT ON  [dbo].[HQApprovalModule] TO [public]
GRANT INSERT ON  [dbo].[HQApprovalModule] TO [public]
GRANT DELETE ON  [dbo].[HQApprovalModule] TO [public]
GRANT UPDATE ON  [dbo].[HQApprovalModule] TO [public]
GO
