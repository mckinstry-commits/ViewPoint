SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMBE] as select a.* From bEMBE a
GO
GRANT SELECT ON  [dbo].[EMBE] TO [public]
GRANT INSERT ON  [dbo].[EMBE] TO [public]
GRANT DELETE ON  [dbo].[EMBE] TO [public]
GRANT UPDATE ON  [dbo].[EMBE] TO [public]
GO
