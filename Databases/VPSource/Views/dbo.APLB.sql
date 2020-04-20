SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APLB] as select a.* From bAPLB a
GO
GRANT SELECT ON  [dbo].[APLB] TO [public]
GRANT INSERT ON  [dbo].[APLB] TO [public]
GRANT DELETE ON  [dbo].[APLB] TO [public]
GRANT UPDATE ON  [dbo].[APLB] TO [public]
GO
