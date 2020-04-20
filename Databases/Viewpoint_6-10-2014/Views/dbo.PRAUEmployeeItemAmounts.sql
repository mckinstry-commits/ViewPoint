SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRAUEmployeeItemAmounts]
AS
	SELECT * FROM dbo.vPRAUEmployeeItemAmounts


GO
GRANT SELECT ON  [dbo].[PRAUEmployeeItemAmounts] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployeeItemAmounts] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployeeItemAmounts] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployeeItemAmounts] TO [public]
GRANT SELECT ON  [dbo].[PRAUEmployeeItemAmounts] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRAUEmployeeItemAmounts] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRAUEmployeeItemAmounts] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRAUEmployeeItemAmounts] TO [Viewpoint]
GO
