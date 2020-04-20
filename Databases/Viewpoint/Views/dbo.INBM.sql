SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INBM] as select a.* From bINBM a

GO
GRANT SELECT ON  [dbo].[INBM] TO [public]
GRANT INSERT ON  [dbo].[INBM] TO [public]
GRANT DELETE ON  [dbo].[INBM] TO [public]
GRANT UPDATE ON  [dbo].[INBM] TO [public]
GO
