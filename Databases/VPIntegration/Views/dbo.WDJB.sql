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
GO
