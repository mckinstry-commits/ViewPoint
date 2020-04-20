SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCW] as select a.* From bPRCW a
GO
GRANT SELECT ON  [dbo].[PRCW] TO [public]
GRANT INSERT ON  [dbo].[PRCW] TO [public]
GRANT DELETE ON  [dbo].[PRCW] TO [public]
GRANT UPDATE ON  [dbo].[PRCW] TO [public]
GRANT SELECT ON  [dbo].[PRCW] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCW] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCW] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCW] TO [Viewpoint]
GO
