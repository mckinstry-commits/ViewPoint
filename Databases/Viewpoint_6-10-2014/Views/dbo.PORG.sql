SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PORG] as select a.* From bPORG a
GO
GRANT SELECT ON  [dbo].[PORG] TO [public]
GRANT INSERT ON  [dbo].[PORG] TO [public]
GRANT DELETE ON  [dbo].[PORG] TO [public]
GRANT UPDATE ON  [dbo].[PORG] TO [public]
GRANT SELECT ON  [dbo].[PORG] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PORG] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PORG] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PORG] TO [Viewpoint]
GO
