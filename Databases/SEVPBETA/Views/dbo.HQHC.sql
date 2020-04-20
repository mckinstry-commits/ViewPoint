SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQHC] as select a.* From bHQHC a

GO
GRANT SELECT ON  [dbo].[HQHC] TO [public]
GRANT INSERT ON  [dbo].[HQHC] TO [public]
GRANT DELETE ON  [dbo].[HQHC] TO [public]
GRANT UPDATE ON  [dbo].[HQHC] TO [public]
GO
