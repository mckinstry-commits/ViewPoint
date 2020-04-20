SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[vfSMGetJBCostTypeFromSMLineType]
(@lineType CHAR, @currentJBCT CHAR)
RETURNS CHAR
/***********************************************************
* CREATED BY	: JG 01/25/2012 - TK-00000
* MODIFIED BY	
*
* USAGE:
* 	Returns the JB Cost Type from the supplied SM Line Type.
*
*
* INPUT PARAMETERS:
*	SM Line Type
*	Current JB Cost Type
*
* OUTPUT PARAMETERS:
*	JBCostType
*
*****************************************************/
AS
BEGIN

DECLARE @JBCostType CHAR
SET @JBCostType = @lineType

IF ISNUMERIC(@lineType) = 1
BEGIN 
	SELECT @JBCostType = CASE 
							WHEN 1=CONVERT(TINYINT, @lineType) THEN 'E' 
							WHEN 2=CONVERT(TINYINT, @lineType) THEN 'L' 
							WHEN 4=CONVERT(TINYINT, @lineType) THEN 'M'
							ELSE @currentJBCT END
END

IF @JBCostType IS NULL SET @JBCostType = @currentJBCT

exitfunction:
  			
RETURN @JBCostType
END
GO
GRANT EXECUTE ON  [dbo].[vfSMGetJBCostTypeFromSMLineType] TO [public]
GO
