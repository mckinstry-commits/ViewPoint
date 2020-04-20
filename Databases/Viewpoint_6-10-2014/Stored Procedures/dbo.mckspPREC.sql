SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mckspPREC] 
AS
BEGIN
	SELECT 
		PRCo,
		EarnCode,
		'' as Description,
		Method,
		Factor		
	FROM PREC
	--WHERE Method = 'V'
END
GO
