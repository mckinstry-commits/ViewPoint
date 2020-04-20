SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[PRCAEmployer]
AS
SELECT     dbo.bPRCAEmployer.*
FROM         dbo.bPRCAEmployer


GO
GRANT SELECT ON  [dbo].[PRCAEmployer] TO [public]
GRANT INSERT ON  [dbo].[PRCAEmployer] TO [public]
GRANT DELETE ON  [dbo].[PRCAEmployer] TO [public]
GRANT UPDATE ON  [dbo].[PRCAEmployer] TO [public]
GRANT SELECT ON  [dbo].[PRCAEmployer] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCAEmployer] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCAEmployer] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCAEmployer] TO [Viewpoint]
GO
