SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSDH] as select a.* From bMSDH a
GO
GRANT SELECT ON  [dbo].[MSDH] TO [public]
GRANT INSERT ON  [dbo].[MSDH] TO [public]
GRANT DELETE ON  [dbo].[MSDH] TO [public]
GRANT UPDATE ON  [dbo].[MSDH] TO [public]
GRANT SELECT ON  [dbo].[MSDH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSDH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSDH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSDH] TO [Viewpoint]
GO
