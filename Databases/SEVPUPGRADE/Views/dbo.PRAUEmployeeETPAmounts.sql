SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO













CREATE VIEW [dbo].[PRAUEmployeeETPAmounts] 
AS 
SELECT * FROM dbo.[vPRAUEmployeeETPAmounts] 














GO
GRANT SELECT ON  [dbo].[PRAUEmployeeETPAmounts] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployeeETPAmounts] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployeeETPAmounts] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployeeETPAmounts] TO [public]
GO
