SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQLT] as select a.* From bHQLT a
GO
GRANT SELECT ON  [dbo].[HQLT] TO [public]
GRANT INSERT ON  [dbo].[HQLT] TO [public]
GRANT DELETE ON  [dbo].[HQLT] TO [public]
GRANT UPDATE ON  [dbo].[HQLT] TO [public]
GO
