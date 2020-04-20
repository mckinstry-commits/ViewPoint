SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLJA] as select a.* From bGLJA a

GO
GRANT SELECT ON  [dbo].[GLJA] TO [public]
GRANT INSERT ON  [dbo].[GLJA] TO [public]
GRANT DELETE ON  [dbo].[GLJA] TO [public]
GRANT UPDATE ON  [dbo].[GLJA] TO [public]
GO
