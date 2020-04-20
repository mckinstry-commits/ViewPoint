SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMEntity]
AS
SELECT *
FROM dbo.vSMEntity
GO
GRANT SELECT ON  [dbo].[SMEntity] TO [public]
GRANT INSERT ON  [dbo].[SMEntity] TO [public]
GRANT DELETE ON  [dbo].[SMEntity] TO [public]
GRANT UPDATE ON  [dbo].[SMEntity] TO [public]
GRANT SELECT ON  [dbo].[SMEntity] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMEntity] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMEntity] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMEntity] TO [Viewpoint]
GO
