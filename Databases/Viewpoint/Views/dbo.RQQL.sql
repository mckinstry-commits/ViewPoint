SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RQQL] as select a.* From bRQQL a

GO
GRANT SELECT ON  [dbo].[RQQL] TO [public]
GRANT INSERT ON  [dbo].[RQQL] TO [public]
GRANT DELETE ON  [dbo].[RQQL] TO [public]
GRANT UPDATE ON  [dbo].[RQQL] TO [public]
GO
