SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSJP] as select a.* From bMSJP a
GO
GRANT SELECT ON  [dbo].[MSJP] TO [public]
GRANT INSERT ON  [dbo].[MSJP] TO [public]
GRANT DELETE ON  [dbo].[MSJP] TO [public]
GRANT UPDATE ON  [dbo].[MSJP] TO [public]
GRANT SELECT ON  [dbo].[MSJP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSJP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSJP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSJP] TO [Viewpoint]
GO
