SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQAT] as select a.* From bHQAT a
GO
GRANT SELECT ON  [dbo].[HQAT] TO [public]
GRANT INSERT ON  [dbo].[HQAT] TO [public]
GRANT DELETE ON  [dbo].[HQAT] TO [public]
GRANT UPDATE ON  [dbo].[HQAT] TO [public]
GO
