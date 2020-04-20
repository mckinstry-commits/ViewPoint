SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCAEmployeeProvince] as select a.* From bPRCAEmployeeProvince a
GO
GRANT SELECT ON  [dbo].[PRCAEmployeeProvince] TO [public]
GRANT INSERT ON  [dbo].[PRCAEmployeeProvince] TO [public]
GRANT DELETE ON  [dbo].[PRCAEmployeeProvince] TO [public]
GRANT UPDATE ON  [dbo].[PRCAEmployeeProvince] TO [public]
GO
