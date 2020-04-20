SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INCJ] as select a.* From bINCJ a

GO
GRANT SELECT ON  [dbo].[INCJ] TO [public]
GRANT INSERT ON  [dbo].[INCJ] TO [public]
GRANT DELETE ON  [dbo].[INCJ] TO [public]
GRANT UPDATE ON  [dbo].[INCJ] TO [public]
GO
