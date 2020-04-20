SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SLAD] as select a.* From bSLAD a
GO
GRANT SELECT ON  [dbo].[SLAD] TO [public]
GRANT INSERT ON  [dbo].[SLAD] TO [public]
GRANT DELETE ON  [dbo].[SLAD] TO [public]
GRANT UPDATE ON  [dbo].[SLAD] TO [public]
GO
