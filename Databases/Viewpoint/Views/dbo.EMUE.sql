SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMUE] as select a.* From bEMUE a

GO
GRANT SELECT ON  [dbo].[EMUE] TO [public]
GRANT INSERT ON  [dbo].[EMUE] TO [public]
GRANT DELETE ON  [dbo].[EMUE] TO [public]
GRANT UPDATE ON  [dbo].[EMUE] TO [public]
GO
