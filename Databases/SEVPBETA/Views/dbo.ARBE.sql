SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARBE] as select a.* From bARBE a

GO
GRANT SELECT ON  [dbo].[ARBE] TO [public]
GRANT INSERT ON  [dbo].[ARBE] TO [public]
GRANT DELETE ON  [dbo].[ARBE] TO [public]
GRANT UPDATE ON  [dbo].[ARBE] TO [public]
GO
