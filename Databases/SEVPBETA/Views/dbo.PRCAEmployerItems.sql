SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[PRCAEmployerItems]
AS
SELECT     dbo.bPRCAEmployerItems.*
FROM         dbo.bPRCAEmployerItems


GO
GRANT SELECT ON  [dbo].[PRCAEmployerItems] TO [public]
GRANT INSERT ON  [dbo].[PRCAEmployerItems] TO [public]
GRANT DELETE ON  [dbo].[PRCAEmployerItems] TO [public]
GRANT UPDATE ON  [dbo].[PRCAEmployerItems] TO [public]
GO
