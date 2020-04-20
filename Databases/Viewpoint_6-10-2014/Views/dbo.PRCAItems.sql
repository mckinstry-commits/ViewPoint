SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[PRCAItems]
AS
SELECT     dbo.bPRCAItems.*
FROM         dbo.bPRCAItems


GO
GRANT SELECT ON  [dbo].[PRCAItems] TO [public]
GRANT INSERT ON  [dbo].[PRCAItems] TO [public]
GRANT DELETE ON  [dbo].[PRCAItems] TO [public]
GRANT UPDATE ON  [dbo].[PRCAItems] TO [public]
GRANT SELECT ON  [dbo].[PRCAItems] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCAItems] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCAItems] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCAItems] TO [Viewpoint]
GO
