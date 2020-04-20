SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[INLM] as select a.* From bINLM a


GO
GRANT SELECT ON  [dbo].[INLM] TO [public]
GRANT INSERT ON  [dbo].[INLM] TO [public]
GRANT DELETE ON  [dbo].[INLM] TO [public]
GRANT UPDATE ON  [dbo].[INLM] TO [public]
GO
