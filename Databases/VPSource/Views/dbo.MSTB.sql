SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSTB] as select a.* From bMSTB a
GO
GRANT SELECT ON  [dbo].[MSTB] TO [public]
GRANT INSERT ON  [dbo].[MSTB] TO [public]
GRANT DELETE ON  [dbo].[MSTB] TO [public]
GRANT UPDATE ON  [dbo].[MSTB] TO [public]
GO
