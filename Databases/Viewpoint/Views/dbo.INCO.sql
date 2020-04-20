SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INCO] as select a.* From bINCO a
GO
GRANT SELECT ON  [dbo].[INCO] TO [public]
GRANT INSERT ON  [dbo].[INCO] TO [public]
GRANT DELETE ON  [dbo].[INCO] TO [public]
GRANT UPDATE ON  [dbo].[INCO] TO [public]
GO
