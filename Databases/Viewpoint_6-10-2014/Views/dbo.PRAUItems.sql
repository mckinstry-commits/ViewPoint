SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRAUItems]
AS
	SELECT * FROM [dbo].[vPRAUItems]

GO
GRANT SELECT ON  [dbo].[PRAUItems] TO [public]
GRANT INSERT ON  [dbo].[PRAUItems] TO [public]
GRANT DELETE ON  [dbo].[PRAUItems] TO [public]
GRANT UPDATE ON  [dbo].[PRAUItems] TO [public]
GRANT SELECT ON  [dbo].[PRAUItems] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAUItems] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAUItems] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAUItems] TO [Viewpoint]
GO
