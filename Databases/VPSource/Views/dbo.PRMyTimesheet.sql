SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE view [dbo].[PRMyTimesheet] as 
select * from bPRMyTimesheet





GO
GRANT SELECT ON  [dbo].[PRMyTimesheet] TO [public]
GRANT INSERT ON  [dbo].[PRMyTimesheet] TO [public]
GRANT DELETE ON  [dbo].[PRMyTimesheet] TO [public]
GRANT UPDATE ON  [dbo].[PRMyTimesheet] TO [public]
GO
