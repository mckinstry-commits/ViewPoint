SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RQRR] as select a.* From bRQRR a
GO
GRANT SELECT ON  [dbo].[RQRR] TO [public]
GRANT INSERT ON  [dbo].[RQRR] TO [public]
GRANT DELETE ON  [dbo].[RQRR] TO [public]
GRANT UPDATE ON  [dbo].[RQRR] TO [public]
GRANT SELECT ON  [dbo].[RQRR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RQRR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RQRR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RQRR] TO [Viewpoint]
GO
