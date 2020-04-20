SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRAUEmployeeMiscItemAmounts]
AS
	SELECT * FROM dbo.vPRAUEmployeeMiscItemAmounts


GO
GRANT SELECT ON  [dbo].[PRAUEmployeeMiscItemAmounts] TO [public]
GRANT INSERT ON  [dbo].[PRAUEmployeeMiscItemAmounts] TO [public]
GRANT DELETE ON  [dbo].[PRAUEmployeeMiscItemAmounts] TO [public]
GRANT UPDATE ON  [dbo].[PRAUEmployeeMiscItemAmounts] TO [public]
GO
