SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6-24-09
-- Description:	Returns whether a Employee Time Card is locked down
-- =============================================
CREATE FUNCTION [dbo].[vpIsMyTimeSheetInStatus]
	(@PRCo bCompany, @EntryEmployee bEmployee, @StartDate bDate, @Sheet SMALLINT, @Status INT)
RETURNS BIT
AS
BEGIN
	DECLARE @CurrentStatus AS TINYINT, @IsInStatus AS BIT

	SELECT @CurrentStatus = [Status]
	FROM [dbo].[bPRMyTimesheet] WITH (NOLOCK)
	WHERE PRCo = @PRCo AND EntryEmployee = @EntryEmployee AND StartDate = @StartDate AND Sheet = @Sheet

	IF @CurrentStatus = @Status
	BEGIN
		SET @IsInStatus = 1
	END
	ELSE
	BEGIN
		SET @IsInStatus = 0
	END
	
	RETURN @IsInStatus
END

GO
