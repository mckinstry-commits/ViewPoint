SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRAUSuperSchemes]
AS
	SELECT * FROM dbo.vPRAUSuperSchemes


GO
GRANT SELECT ON  [dbo].[PRAUSuperSchemes] TO [public]
GRANT INSERT ON  [dbo].[PRAUSuperSchemes] TO [public]
GRANT DELETE ON  [dbo].[PRAUSuperSchemes] TO [public]
GRANT UPDATE ON  [dbo].[PRAUSuperSchemes] TO [public]
GRANT SELECT ON  [dbo].[PRAUSuperSchemes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAUSuperSchemes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAUSuperSchemes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAUSuperSchemes] TO [Viewpoint]
GO
