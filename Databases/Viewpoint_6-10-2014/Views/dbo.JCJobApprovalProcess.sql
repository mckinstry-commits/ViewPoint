SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[JCJobApprovalProcess] as select a.* From vJCJobApprovalProcess a

GO
GRANT SELECT ON  [dbo].[JCJobApprovalProcess] TO [public]
GRANT INSERT ON  [dbo].[JCJobApprovalProcess] TO [public]
GRANT DELETE ON  [dbo].[JCJobApprovalProcess] TO [public]
GRANT UPDATE ON  [dbo].[JCJobApprovalProcess] TO [public]
GRANT SELECT ON  [dbo].[JCJobApprovalProcess] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCJobApprovalProcess] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCJobApprovalProcess] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCJobApprovalProcess] TO [Viewpoint]
GO
