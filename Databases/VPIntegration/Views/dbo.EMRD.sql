SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMRD] as select a.* From bEMRD a
GO
GRANT SELECT ON  [dbo].[EMRD] TO [public]
GRANT INSERT ON  [dbo].[EMRD] TO [public]
GRANT DELETE ON  [dbo].[EMRD] TO [public]
GRANT UPDATE ON  [dbo].[EMRD] TO [public]
GO
