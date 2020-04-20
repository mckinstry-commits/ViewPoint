SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SLCB] as select a.* From bSLCB a
GO
GRANT SELECT ON  [dbo].[SLCB] TO [public]
GRANT INSERT ON  [dbo].[SLCB] TO [public]
GRANT DELETE ON  [dbo].[SLCB] TO [public]
GRANT UPDATE ON  [dbo].[SLCB] TO [public]
GO
