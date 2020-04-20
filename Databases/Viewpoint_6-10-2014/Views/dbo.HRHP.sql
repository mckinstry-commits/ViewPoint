SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRHP] as select a.* From bHRHP a
GO
GRANT SELECT ON  [dbo].[HRHP] TO [public]
GRANT INSERT ON  [dbo].[HRHP] TO [public]
GRANT DELETE ON  [dbo].[HRHP] TO [public]
GRANT UPDATE ON  [dbo].[HRHP] TO [public]
GRANT SELECT ON  [dbo].[HRHP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRHP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRHP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRHP] TO [Viewpoint]
GO
