SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APRH] as select a.* From bAPRH a
GO
GRANT SELECT ON  [dbo].[APRH] TO [public]
GRANT INSERT ON  [dbo].[APRH] TO [public]
GRANT DELETE ON  [dbo].[APRH] TO [public]
GRANT UPDATE ON  [dbo].[APRH] TO [public]
GRANT SELECT ON  [dbo].[APRH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APRH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APRH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APRH] TO [Viewpoint]
GO
