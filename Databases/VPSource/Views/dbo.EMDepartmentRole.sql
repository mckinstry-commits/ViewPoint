SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[EMDepartmentRole] as select a.* From vEMDepartmentRole a
GO
GRANT SELECT ON  [dbo].[EMDepartmentRole] TO [public]
GRANT INSERT ON  [dbo].[EMDepartmentRole] TO [public]
GRANT DELETE ON  [dbo].[EMDepartmentRole] TO [public]
GRANT UPDATE ON  [dbo].[EMDepartmentRole] TO [public]
GO
