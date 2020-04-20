SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMDepartmentApprovalProcess] as select a.* From vEMDepartmentApprovalProcess a
GO
GRANT SELECT ON  [dbo].[EMDepartmentApprovalProcess] TO [public]
GRANT INSERT ON  [dbo].[EMDepartmentApprovalProcess] TO [public]
GRANT DELETE ON  [dbo].[EMDepartmentApprovalProcess] TO [public]
GRANT UPDATE ON  [dbo].[EMDepartmentApprovalProcess] TO [public]
GO
