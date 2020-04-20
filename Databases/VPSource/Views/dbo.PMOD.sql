SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMOD] as select a.* From bPMOD a
GO
GRANT SELECT ON  [dbo].[PMOD] TO [public]
GRANT INSERT ON  [dbo].[PMOD] TO [public]
GRANT DELETE ON  [dbo].[PMOD] TO [public]
GRANT UPDATE ON  [dbo].[PMOD] TO [public]
GO
