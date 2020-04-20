SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMAR] as select a.* From bEMAR a
GO
GRANT SELECT ON  [dbo].[EMAR] TO [public]
GRANT INSERT ON  [dbo].[EMAR] TO [public]
GRANT DELETE ON  [dbo].[EMAR] TO [public]
GRANT UPDATE ON  [dbo].[EMAR] TO [public]
GO
