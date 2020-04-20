SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRAUEmployerSuperItems]
AS
	SELECT * FROM dbo.vPRAUEmployerSuperItems


GO
GRANT SELECT ON  [dbo].[PRAUEmployerSuperItems] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployerSuperItems] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployerSuperItems] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployerSuperItems] TO [public]
GO
