SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PCScopes] as select a.* From vPCScopes a

GO
GRANT SELECT ON  [dbo].[PCScopes] TO [public]
GRANT INSERT ON  [dbo].[PCScopes] TO [public]
GRANT DELETE ON  [dbo].[PCScopes] TO [public]
GRANT UPDATE ON  [dbo].[PCScopes] TO [public]
GO
