SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRAR] as select a.* From bHRAR a

GO
GRANT SELECT ON  [dbo].[HRAR] TO [public]
GRANT INSERT ON  [dbo].[HRAR] TO [public]
GRANT DELETE ON  [dbo].[HRAR] TO [public]
GRANT UPDATE ON  [dbo].[HRAR] TO [public]
GO
