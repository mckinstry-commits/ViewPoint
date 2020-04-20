SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCF] as select a.* From bPRCF a
GO
GRANT SELECT ON  [dbo].[PRCF] TO [public]
GRANT INSERT ON  [dbo].[PRCF] TO [public]
GRANT DELETE ON  [dbo].[PRCF] TO [public]
GRANT UPDATE ON  [dbo].[PRCF] TO [public]
GRANT SELECT ON  [dbo].[PRCF] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCF] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCF] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCF] TO [Viewpoint]
GO
