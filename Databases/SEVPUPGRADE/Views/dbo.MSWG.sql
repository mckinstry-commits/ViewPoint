SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSWG] as select a.* From bMSWG a

GO
GRANT SELECT ON  [dbo].[MSWG] TO [public]
GRANT INSERT ON  [dbo].[MSWG] TO [public]
GRANT DELETE ON  [dbo].[MSWG] TO [public]
GRANT UPDATE ON  [dbo].[MSWG] TO [public]
GO
