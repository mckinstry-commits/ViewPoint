SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE VIEW [dbo].[SMWorkScope] 
AS
SELECT a.* FROM dbo.vSMWorkScope a

/*
SELECT *, WorkScopeID AS KeyID
FROM dbo.vSMWorkScope
*/







GO
GRANT SELECT ON  [dbo].[SMWorkScope] TO [public]
GRANT INSERT ON  [dbo].[SMWorkScope] TO [public]
GRANT DELETE ON  [dbo].[SMWorkScope] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkScope] TO [public]
GRANT SELECT ON  [dbo].[SMWorkScope] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMWorkScope] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMWorkScope] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMWorkScope] TO [Viewpoint]
GO
