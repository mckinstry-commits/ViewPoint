SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMAE] as select a.* From bEMAE a

GO
GRANT SELECT ON  [dbo].[EMAE] TO [public]
GRANT INSERT ON  [dbo].[EMAE] TO [public]
GRANT DELETE ON  [dbo].[EMAE] TO [public]
GRANT UPDATE ON  [dbo].[EMAE] TO [public]
GO
