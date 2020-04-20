SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSII] as select a.* From bMSII a
GO
GRANT SELECT ON  [dbo].[MSII] TO [public]
GRANT INSERT ON  [dbo].[MSII] TO [public]
GRANT DELETE ON  [dbo].[MSII] TO [public]
GRANT UPDATE ON  [dbo].[MSII] TO [public]
GRANT SELECT ON  [dbo].[MSII] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSII] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSII] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSII] TO [Viewpoint]
GO
