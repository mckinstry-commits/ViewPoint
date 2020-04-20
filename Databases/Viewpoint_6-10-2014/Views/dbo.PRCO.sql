SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCO] as select a.* From bPRCO a
GO
GRANT SELECT ON  [dbo].[PRCO] TO [public]
GRANT INSERT ON  [dbo].[PRCO] TO [public]
GRANT DELETE ON  [dbo].[PRCO] TO [public]
GRANT UPDATE ON  [dbo].[PRCO] TO [public]
GRANT SELECT ON  [dbo].[PRCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCO] TO [Viewpoint]
GO
