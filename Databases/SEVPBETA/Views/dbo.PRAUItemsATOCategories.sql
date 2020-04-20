SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRAUItemsATOCategories]
AS
	SELECT * FROM [dbo].[vPRAUItemsATOCategories]

GO
GRANT SELECT ON  [dbo].[PRAUItemsATOCategories] TO [public]
GRANT INSERT ON  [dbo].[PRAUItemsATOCategories] TO [public]
GRANT DELETE ON  [dbo].[PRAUItemsATOCategories] TO [public]
GRANT UPDATE ON  [dbo].[PRAUItemsATOCategories] TO [public]
GO
