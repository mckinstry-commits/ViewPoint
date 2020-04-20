SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMMR] as select a.* From bEMMR a
GO
GRANT SELECT ON  [dbo].[EMMR] TO [public]
GRANT INSERT ON  [dbo].[EMMR] TO [public]
GRANT DELETE ON  [dbo].[EMMR] TO [public]
GRANT UPDATE ON  [dbo].[EMMR] TO [public]
GO
