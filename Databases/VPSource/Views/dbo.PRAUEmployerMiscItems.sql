SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRAUEmployerMiscItems]
AS
	SELECT * FROM dbo.vPRAUEmployerMiscItems


GO
GRANT SELECT ON  [dbo].[PRAUEmployerMiscItems] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployerMiscItems] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployerMiscItems] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployerMiscItems] TO [public]
GO
