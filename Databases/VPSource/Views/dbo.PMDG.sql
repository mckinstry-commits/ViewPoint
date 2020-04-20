SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMDG] as select a.* From bPMDG a
GO
GRANT SELECT ON  [dbo].[PMDG] TO [public]
GRANT INSERT ON  [dbo].[PMDG] TO [public]
GRANT DELETE ON  [dbo].[PMDG] TO [public]
GRANT UPDATE ON  [dbo].[PMDG] TO [public]
GO
