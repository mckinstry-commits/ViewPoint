SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCAEmployeeCodes] as select a.* From bPRCAEmployeeCodes a
GO
GRANT SELECT ON  [dbo].[PRCAEmployeeCodes] TO [public]
GRANT INSERT ON  [dbo].[PRCAEmployeeCodes] TO [public]
GRANT DELETE ON  [dbo].[PRCAEmployeeCodes] TO [public]
GRANT UPDATE ON  [dbo].[PRCAEmployeeCodes] TO [public]
GO
