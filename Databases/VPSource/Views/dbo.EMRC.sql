SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMRC] as select a.* From bEMRC a
GO
GRANT SELECT ON  [dbo].[EMRC] TO [public]
GRANT INSERT ON  [dbo].[EMRC] TO [public]
GRANT DELETE ON  [dbo].[EMRC] TO [public]
GRANT UPDATE ON  [dbo].[EMRC] TO [public]
GO
