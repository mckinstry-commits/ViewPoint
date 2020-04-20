SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMWI] as select a.* From bEMWI a
GO
GRANT SELECT ON  [dbo].[EMWI] TO [public]
GRANT INSERT ON  [dbo].[EMWI] TO [public]
GRANT DELETE ON  [dbo].[EMWI] TO [public]
GRANT UPDATE ON  [dbo].[EMWI] TO [public]
GO
