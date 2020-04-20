SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SLXB] as select a.* From bSLXB a
GO
GRANT SELECT ON  [dbo].[SLXB] TO [public]
GRANT INSERT ON  [dbo].[SLXB] TO [public]
GRANT DELETE ON  [dbo].[SLXB] TO [public]
GRANT UPDATE ON  [dbo].[SLXB] TO [public]
GRANT SELECT ON  [dbo].[SLXB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SLXB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SLXB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SLXB] TO [Viewpoint]
GO
