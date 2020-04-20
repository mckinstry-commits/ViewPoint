SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCAEmployees] as select a.* from bPRCAEmployees a 
GO
GRANT SELECT ON  [dbo].[PRCAEmployees] TO [public]
GRANT INSERT ON  [dbo].[PRCAEmployees] TO [public]
GRANT DELETE ON  [dbo].[PRCAEmployees] TO [public]
GRANT UPDATE ON  [dbo].[PRCAEmployees] TO [public]
GRANT SELECT ON  [dbo].[PRCAEmployees] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCAEmployees] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCAEmployees] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCAEmployees] TO [Viewpoint]
GO