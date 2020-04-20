SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRAUEmployees]
AS
	SELECT * FROM dbo.vPRAUEmployees


GO
GRANT SELECT ON  [dbo].[PRAUEmployees] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployees] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployees] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployees] TO [public]
GO
