SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mckspPRDL] 
AS
BEGIN
	SELECT 
		PRCo,
		DLCode,
		'' as Description,
		'' as DLType,
		Method				
	FROM PRDL
	WHERE Method = 'V'
END
GO
