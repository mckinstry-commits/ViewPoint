SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMMI] as select a.* From bPMMI a
GO
GRANT SELECT ON  [dbo].[PMMI] TO [public]
GRANT INSERT ON  [dbo].[PMMI] TO [public]
GRANT DELETE ON  [dbo].[PMMI] TO [public]
GRANT UPDATE ON  [dbo].[PMMI] TO [public]
GO
