SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRAE] as select a.* from bPRAE a 
GO
GRANT SELECT ON  [dbo].[PRAE] TO [public]
GRANT INSERT ON  [dbo].[PRAE] TO [public]
GRANT DELETE ON  [dbo].[PRAE] TO [public]
GRANT UPDATE ON  [dbo].[PRAE] TO [public]
GO