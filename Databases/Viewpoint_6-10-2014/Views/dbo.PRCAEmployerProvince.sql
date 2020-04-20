SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[PRCAEmployerProvince]
AS
SELECT     dbo.bPRCAEmployerProvince.*
FROM         dbo.bPRCAEmployerProvince


GO
GRANT SELECT ON  [dbo].[PRCAEmployerProvince] TO [public]
GRANT INSERT ON  [dbo].[PRCAEmployerProvince] TO [public]
GRANT DELETE ON  [dbo].[PRCAEmployerProvince] TO [public]
GRANT UPDATE ON  [dbo].[PRCAEmployerProvince] TO [public]
GRANT SELECT ON  [dbo].[PRCAEmployerProvince] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRCAEmployerProvince] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRCAEmployerProvince] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRCAEmployerProvince] TO [Viewpoint]
GO
