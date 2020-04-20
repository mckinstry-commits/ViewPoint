SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RQQH] as select a.* From bRQQH a
GO
GRANT SELECT ON  [dbo].[RQQH] TO [public]
GRANT INSERT ON  [dbo].[RQQH] TO [public]
GRANT DELETE ON  [dbo].[RQQH] TO [public]
GRANT UPDATE ON  [dbo].[RQQH] TO [public]
GRANT SELECT ON  [dbo].[RQQH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RQQH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RQQH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RQQH] TO [Viewpoint]
GO
