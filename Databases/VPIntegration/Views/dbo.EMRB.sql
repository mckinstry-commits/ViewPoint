SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMRB] as select a.* From bEMRB a
GO
GRANT SELECT ON  [dbo].[EMRB] TO [public]
GRANT INSERT ON  [dbo].[EMRB] TO [public]
GRANT DELETE ON  [dbo].[EMRB] TO [public]
GRANT UPDATE ON  [dbo].[EMRB] TO [public]
GO
