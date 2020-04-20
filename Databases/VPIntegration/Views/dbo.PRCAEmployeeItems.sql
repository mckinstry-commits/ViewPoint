SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCAEmployeeItems] as select a.* From bPRCAEmployeeItems a
GO
GRANT SELECT ON  [dbo].[PRCAEmployeeItems] TO [public]
GRANT INSERT ON  [dbo].[PRCAEmployeeItems] TO [public]
GRANT DELETE ON  [dbo].[PRCAEmployeeItems] TO [public]
GRANT UPDATE ON  [dbo].[PRCAEmployeeItems] TO [public]
GO
