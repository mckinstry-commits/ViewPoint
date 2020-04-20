SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMEP] as select a.* From bEMEP a
GO
GRANT SELECT ON  [dbo].[EMEP] TO [public]
GRANT INSERT ON  [dbo].[EMEP] TO [public]
GRANT DELETE ON  [dbo].[EMEP] TO [public]
GRANT UPDATE ON  [dbo].[EMEP] TO [public]
GRANT SELECT ON  [dbo].[EMEP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMEP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMEP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMEP] TO [Viewpoint]
GO
