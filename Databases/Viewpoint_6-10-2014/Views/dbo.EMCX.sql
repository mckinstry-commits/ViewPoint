SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMCX] as select a.* From bEMCX a

GO
GRANT SELECT ON  [dbo].[EMCX] TO [public]
GRANT INSERT ON  [dbo].[EMCX] TO [public]
GRANT DELETE ON  [dbo].[EMCX] TO [public]
GRANT UPDATE ON  [dbo].[EMCX] TO [public]
GRANT SELECT ON  [dbo].[EMCX] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMCX] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMCX] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMCX] TO [Viewpoint]
GO
