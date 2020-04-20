SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMRH] as select a.* From bEMRH a
GO
GRANT SELECT ON  [dbo].[EMRH] TO [public]
GRANT INSERT ON  [dbo].[EMRH] TO [public]
GRANT DELETE ON  [dbo].[EMRH] TO [public]
GRANT UPDATE ON  [dbo].[EMRH] TO [public]
GO
