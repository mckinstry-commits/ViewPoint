SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTA] as select a.* From bPRTA a
GO
GRANT SELECT ON  [dbo].[PRTA] TO [public]
GRANT INSERT ON  [dbo].[PRTA] TO [public]
GRANT DELETE ON  [dbo].[PRTA] TO [public]
GRANT UPDATE ON  [dbo].[PRTA] TO [public]
GRANT SELECT ON  [dbo].[PRTA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRTA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRTA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRTA] TO [Viewpoint]
GO
