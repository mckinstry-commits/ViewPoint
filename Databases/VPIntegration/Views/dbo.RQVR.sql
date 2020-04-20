SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RQVR] as select a.* From bRQVR a

GO
GRANT SELECT ON  [dbo].[RQVR] TO [public]
GRANT INSERT ON  [dbo].[RQVR] TO [public]
GRANT DELETE ON  [dbo].[RQVR] TO [public]
GRANT UPDATE ON  [dbo].[RQVR] TO [public]
GO
