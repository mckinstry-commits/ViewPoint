SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMML] as select a.* From bEMML a
GO
GRANT SELECT ON  [dbo].[EMML] TO [public]
GRANT INSERT ON  [dbo].[EMML] TO [public]
GRANT DELETE ON  [dbo].[EMML] TO [public]
GRANT UPDATE ON  [dbo].[EMML] TO [public]
GO
