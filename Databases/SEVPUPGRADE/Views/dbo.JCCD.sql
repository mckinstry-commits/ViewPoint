SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCCD] as select a.* from bJCCD a 
GO
GRANT SELECT ON  [dbo].[JCCD] TO [public]
GRANT INSERT ON  [dbo].[JCCD] TO [public]
GRANT DELETE ON  [dbo].[JCCD] TO [public]
GRANT UPDATE ON  [dbo].[JCCD] TO [public]
GO