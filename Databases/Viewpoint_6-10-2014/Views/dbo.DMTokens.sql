SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[DMTokens] as select a.* From vDMTokens a



GO
GRANT SELECT ON  [dbo].[DMTokens] TO [public]
GRANT INSERT ON  [dbo].[DMTokens] TO [public]
GRANT DELETE ON  [dbo].[DMTokens] TO [public]
GRANT UPDATE ON  [dbo].[DMTokens] TO [public]
GRANT SELECT ON  [dbo].[DMTokens] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DMTokens] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DMTokens] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DMTokens] TO [Viewpoint]
GO
