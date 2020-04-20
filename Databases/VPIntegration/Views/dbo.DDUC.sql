SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[DDUC] as select * from vDDUC

GO
GRANT SELECT ON  [dbo].[DDUC] TO [public]
GRANT INSERT ON  [dbo].[DDUC] TO [public]
GRANT DELETE ON  [dbo].[DDUC] TO [public]
GRANT UPDATE ON  [dbo].[DDUC] TO [public]
GO
