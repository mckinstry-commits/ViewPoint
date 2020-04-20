SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSLB] as select a.* From bMSLB a

GO
GRANT SELECT ON  [dbo].[MSLB] TO [public]
GRANT INSERT ON  [dbo].[MSLB] TO [public]
GRANT DELETE ON  [dbo].[MSLB] TO [public]
GRANT UPDATE ON  [dbo].[MSLB] TO [public]
GO
