SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WDJB] as select a.* From bWDJB a

GO
GRANT SELECT ON  [dbo].[WDJB] TO [public]
GRANT INSERT ON  [dbo].[WDJB] TO [public]
GRANT DELETE ON  [dbo].[WDJB] TO [public]
GRANT UPDATE ON  [dbo].[WDJB] TO [public]
GRANT SELECT ON  [dbo].[WDJB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WDJB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WDJB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WDJB] TO [Viewpoint]
GO
