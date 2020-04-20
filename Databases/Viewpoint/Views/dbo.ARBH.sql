SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARBH] as select a.* From bARBH a
GO
GRANT SELECT ON  [dbo].[ARBH] TO [public]
GRANT INSERT ON  [dbo].[ARBH] TO [public]
GRANT DELETE ON  [dbo].[ARBH] TO [public]
GRANT UPDATE ON  [dbo].[ARBH] TO [public]
GO
