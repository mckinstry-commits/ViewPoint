SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRAUEmployer] 
AS 
SELECT * FROM dbo.vPRAUEmployer


GO
GRANT SELECT ON  [dbo].[PRAUEmployer] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployer] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployer] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployer] TO [public]
GO
