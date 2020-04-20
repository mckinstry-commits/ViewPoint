SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMOL] as select a.* From bPMOL a
GO
GRANT SELECT ON  [dbo].[PMOL] TO [public]
GRANT INSERT ON  [dbo].[PMOL] TO [public]
GRANT DELETE ON  [dbo].[PMOL] TO [public]
GRANT UPDATE ON  [dbo].[PMOL] TO [public]
GO
