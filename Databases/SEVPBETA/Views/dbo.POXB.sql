SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POXB] as select a.* From bPOXB a
GO
GRANT SELECT ON  [dbo].[POXB] TO [public]
GRANT INSERT ON  [dbo].[POXB] TO [public]
GRANT DELETE ON  [dbo].[POXB] TO [public]
GRANT UPDATE ON  [dbo].[POXB] TO [public]
GO
