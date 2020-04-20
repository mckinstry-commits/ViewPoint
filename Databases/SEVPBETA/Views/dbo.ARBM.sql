SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARBM] as select a.* From bARBM a

GO
GRANT SELECT ON  [dbo].[ARBM] TO [public]
GRANT INSERT ON  [dbo].[ARBM] TO [public]
GRANT DELETE ON  [dbo].[ARBM] TO [public]
GRANT UPDATE ON  [dbo].[ARBM] TO [public]
GO
