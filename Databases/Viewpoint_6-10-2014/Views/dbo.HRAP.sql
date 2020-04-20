SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRAP] as select a.* From bHRAP a
GO
GRANT SELECT ON  [dbo].[HRAP] TO [public]
GRANT INSERT ON  [dbo].[HRAP] TO [public]
GRANT DELETE ON  [dbo].[HRAP] TO [public]
GRANT UPDATE ON  [dbo].[HRAP] TO [public]
GRANT SELECT ON  [dbo].[HRAP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRAP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRAP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRAP] TO [Viewpoint]
GO
