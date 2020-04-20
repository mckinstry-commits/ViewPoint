SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCAEmployeeCodes] as select a.* from bPRCAEmployeeCodes a 
GO
GRANT SELECT ON  [dbo].[PRCAEmployeeCodes] TO [public]
GRANT INSERT ON  [dbo].[PRCAEmployeeCodes] TO [public]
GRANT DELETE ON  [dbo].[PRCAEmployeeCodes] TO [public]
GRANT UPDATE ON  [dbo].[PRCAEmployeeCodes] TO [public]
GRANT SELECT ON  [dbo].[PRCAEmployeeCodes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCAEmployeeCodes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCAEmployeeCodes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCAEmployeeCodes] TO [Viewpoint]
GO