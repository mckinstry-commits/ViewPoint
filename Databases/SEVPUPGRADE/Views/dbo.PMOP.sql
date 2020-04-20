SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMOP] as select a.* From bPMOP a
GO
GRANT SELECT ON  [dbo].[PMOP] TO [public]
GRANT INSERT ON  [dbo].[PMOP] TO [public]
GRANT DELETE ON  [dbo].[PMOP] TO [public]
GRANT UPDATE ON  [dbo].[PMOP] TO [public]
GO
