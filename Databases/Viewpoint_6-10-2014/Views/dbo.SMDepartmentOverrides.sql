SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMDepartmentOverrides] as select a.* From vSMDepartmentOverrides a
GO
GRANT SELECT ON  [dbo].[SMDepartmentOverrides] TO [public]
GRANT INSERT ON  [dbo].[SMDepartmentOverrides] TO [public]
GRANT DELETE ON  [dbo].[SMDepartmentOverrides] TO [public]
GRANT UPDATE ON  [dbo].[SMDepartmentOverrides] TO [public]
GRANT SELECT ON  [dbo].[SMDepartmentOverrides] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMDepartmentOverrides] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMDepartmentOverrides] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMDepartmentOverrides] TO [Viewpoint]
GO
