SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRDP] as select a.* From bPRDP a
GO
GRANT SELECT ON  [dbo].[PRDP] TO [public]
GRANT INSERT ON  [dbo].[PRDP] TO [public]
GRANT DELETE ON  [dbo].[PRDP] TO [public]
GRANT UPDATE ON  [dbo].[PRDP] TO [public]
GRANT SELECT ON  [dbo].[PRDP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRDP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRDP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRDP] TO [Viewpoint]
GO
