SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SLWI] as select a.* From bSLWI a
GO
GRANT SELECT ON  [dbo].[SLWI] TO [public]
GRANT INSERT ON  [dbo].[SLWI] TO [public]
GRANT DELETE ON  [dbo].[SLWI] TO [public]
GRANT UPDATE ON  [dbo].[SLWI] TO [public]
GO
