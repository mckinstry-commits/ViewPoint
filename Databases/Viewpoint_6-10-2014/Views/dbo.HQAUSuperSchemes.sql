SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[HQAUSuperSchemes]
AS
	SELECT * FROM dbo.vHQAUSuperSchemes


GO
GRANT SELECT ON  [dbo].[HQAUSuperSchemes] TO [public]
GRANT INSERT ON  [dbo].[HQAUSuperSchemes] TO [public]
GRANT DELETE ON  [dbo].[HQAUSuperSchemes] TO [public]
GRANT UPDATE ON  [dbo].[HQAUSuperSchemes] TO [public]
GRANT SELECT ON  [dbo].[HQAUSuperSchemes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQAUSuperSchemes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQAUSuperSchemes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQAUSuperSchemes] TO [Viewpoint]
GO
