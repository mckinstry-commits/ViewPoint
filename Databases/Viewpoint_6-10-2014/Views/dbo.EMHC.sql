SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMHC] as select a.* From bEMHC a
GO
GRANT SELECT ON  [dbo].[EMHC] TO [public]
GRANT INSERT ON  [dbo].[EMHC] TO [public]
GRANT DELETE ON  [dbo].[EMHC] TO [public]
GRANT UPDATE ON  [dbo].[EMHC] TO [public]
GRANT SELECT ON  [dbo].[EMHC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMHC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMHC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMHC] TO [Viewpoint]
GO
