SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQRP] as select a.* From bHQRP a
GO
GRANT SELECT ON  [dbo].[HQRP] TO [public]
GRANT INSERT ON  [dbo].[HQRP] TO [public]
GRANT DELETE ON  [dbo].[HQRP] TO [public]
GRANT UPDATE ON  [dbo].[HQRP] TO [public]
GO
