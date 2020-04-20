SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRAL] as select a.* From bHRAL a
GO
GRANT SELECT ON  [dbo].[HRAL] TO [public]
GRANT INSERT ON  [dbo].[HRAL] TO [public]
GRANT DELETE ON  [dbo].[HRAL] TO [public]
GRANT UPDATE ON  [dbo].[HRAL] TO [public]
GO
