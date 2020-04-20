SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[POSM] as select a.* From bPOSM a

GO
GRANT SELECT ON  [dbo].[POSM] TO [public]
GRANT INSERT ON  [dbo].[POSM] TO [public]
GRANT DELETE ON  [dbo].[POSM] TO [public]
GRANT UPDATE ON  [dbo].[POSM] TO [public]
GO
