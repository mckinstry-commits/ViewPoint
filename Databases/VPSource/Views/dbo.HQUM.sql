SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQUM] as select a.* From bHQUM a

GO
GRANT SELECT ON  [dbo].[HQUM] TO [public]
GRANT INSERT ON  [dbo].[HQUM] TO [public]
GRANT DELETE ON  [dbo].[HQUM] TO [public]
GRANT UPDATE ON  [dbo].[HQUM] TO [public]
GO
