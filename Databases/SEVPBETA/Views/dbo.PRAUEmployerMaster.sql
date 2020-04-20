SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE VIEW [dbo].[PRAUEmployerMaster] 
AS 
SELECT * FROM dbo.[vPRAUEmployerMaster]









GO
GRANT SELECT ON  [dbo].[PRAUEmployerMaster] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployerMaster] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployerMaster] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployerMaster] TO [public]
GO
