SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARCO] as select a.* From bARCO a
GO
GRANT SELECT ON  [dbo].[ARCO] TO [public]
GRANT INSERT ON  [dbo].[ARCO] TO [public]
GRANT DELETE ON  [dbo].[ARCO] TO [public]
GRANT UPDATE ON  [dbo].[ARCO] TO [public]
GO
