SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PREH] as select a.* from bPREH a 
GO
GRANT SELECT ON  [dbo].[PREH] TO [public]
GRANT INSERT ON  [dbo].[PREH] TO [public]
GRANT DELETE ON  [dbo].[PREH] TO [public]
GRANT UPDATE ON  [dbo].[PREH] TO [public]
GO