SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Gil Fox>
-- Create date: <10.22.2010>
-- Description:	< This function will return a date without time using
-- the HQCO.ReportDateFormat to define the style for the date.
-- ReportDateFormat:
--	1 - mm/dd/yyyy	Style equals 101
--	2 - dd/mm/yyyy	Style equals 103
--	3 - yyyy/mm/dd	Stype equals 111
--
-- Parameters:
-- @Date	DateTime - pass the date to format. if no date will return null
-- @HQCo	Integer	 - will use HQCO to define style if passed in. can be null
-- @Style	Integer	 - used to define a style. default will be U.S. style.
--
-- When calling a function with optional parameters you must specify DEFAULT for
-- the optional parameters when not passing in a parameter value.
-- Example: dbo.vfDateOnlyAsStringUsingStyle (@Date, DEFAULT, 101)
--
-- Returns a date formatted as a string in the style specified.
-- If no date is passed returns empty string
-- =============================================
CREATE FUNCTION [dbo].[vfDateOnlyAsStringUsingStyle]
(
	@Date AS DATETIME = NULL,
	@HQCo AS INT = NULL,
	@Style AS INT = NULL
)

RETURNS VARCHAR(20)

AS
BEGIN

	IF @Date IS NULL RETURN NULL
	
	---- get the ReportDateFormat from HQCO
	IF @HQCo IS NOT NULL
		BEGIN
		SELECT @Style = CASE HQCO.ReportDateFormat WHEN 1 THEN 101 WHEN 2 THEN 103 WHEN 3 THEN 111 ELSE 101 END
		FROM dbo.bHQCO HQCO WHERE HQCO.HQCo = @HQCo
		END
	
	---- format the date as a string using the style
	RETURN CONVERT(VARCHAR(20), @Date, isnull(@Style,101))

END


GO
GRANT EXECUTE ON  [dbo].[vfDateOnlyAsStringUsingStyle] TO [public]
GO
