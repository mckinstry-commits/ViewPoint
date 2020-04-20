SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRAUEmployerATOItems]
AS
	SELECT * FROM dbo.vPRAUEmployerATOItems


GO
GRANT SELECT ON  [dbo].[PRAUEmployerATOItems] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployerATOItems] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployerATOItems] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployerATOItems] TO [public]
GRANT SELECT ON  [dbo].[PRAUEmployerATOItems] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAUEmployerATOItems] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAUEmployerATOItems] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAUEmployerATOItems] TO [Viewpoint]
GO
