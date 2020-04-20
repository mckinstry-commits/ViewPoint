SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMRT] as select a.* From bEMRT a
GO
GRANT SELECT ON  [dbo].[EMRT] TO [public]
GRANT INSERT ON  [dbo].[EMRT] TO [public]
GRANT DELETE ON  [dbo].[EMRT] TO [public]
GRANT UPDATE ON  [dbo].[EMRT] TO [public]
GO
