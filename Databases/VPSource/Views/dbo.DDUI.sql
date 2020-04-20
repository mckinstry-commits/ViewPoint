SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[DDUI] as select * from vDDUI

GO
GRANT SELECT ON  [dbo].[DDUI] TO [public]
GRANT INSERT ON  [dbo].[DDUI] TO [public]
GRANT DELETE ON  [dbo].[DDUI] TO [public]
GRANT UPDATE ON  [dbo].[DDUI] TO [public]
GO
