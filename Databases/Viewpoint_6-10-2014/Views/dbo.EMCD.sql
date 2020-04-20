SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMCD] as select a.* From bEMCD a
GO
GRANT SELECT ON  [dbo].[EMCD] TO [public]
GRANT INSERT ON  [dbo].[EMCD] TO [public]
GRANT DELETE ON  [dbo].[EMCD] TO [public]
GRANT UPDATE ON  [dbo].[EMCD] TO [public]
GRANT SELECT ON  [dbo].[EMCD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMCD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMCD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMCD] TO [Viewpoint]
GO
