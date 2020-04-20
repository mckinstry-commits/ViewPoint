SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PORB] as select a.* From bPORB a
GO
GRANT SELECT ON  [dbo].[PORB] TO [public]
GRANT INSERT ON  [dbo].[PORB] TO [public]
GRANT DELETE ON  [dbo].[PORB] TO [public]
GRANT UPDATE ON  [dbo].[PORB] TO [public]
GO
