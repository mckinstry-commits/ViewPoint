SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMNR] as select a.* From bPMNR a
GO
GRANT SELECT ON  [dbo].[PMNR] TO [public]
GRANT INSERT ON  [dbo].[PMNR] TO [public]
GRANT DELETE ON  [dbo].[PMNR] TO [public]
GRANT UPDATE ON  [dbo].[PMNR] TO [public]
GO
