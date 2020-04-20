SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SLWH] as select a.* From bSLWH a
GO
GRANT SELECT ON  [dbo].[SLWH] TO [public]
GRANT INSERT ON  [dbo].[SLWH] TO [public]
GRANT DELETE ON  [dbo].[SLWH] TO [public]
GRANT UPDATE ON  [dbo].[SLWH] TO [public]
GO
