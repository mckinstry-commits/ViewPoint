SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMEH] as select a.* From bEMEH a

GO
GRANT SELECT ON  [dbo].[EMEH] TO [public]
GRANT INSERT ON  [dbo].[EMEH] TO [public]
GRANT DELETE ON  [dbo].[EMEH] TO [public]
GRANT UPDATE ON  [dbo].[EMEH] TO [public]
GO
