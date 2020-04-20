SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRIA] as select a.* from bPRIA a 
GO
GRANT SELECT ON  [dbo].[PRIA] TO [public]
GRANT INSERT ON  [dbo].[PRIA] TO [public]
GRANT DELETE ON  [dbo].[PRIA] TO [public]
GRANT UPDATE ON  [dbo].[PRIA] TO [public]
GO