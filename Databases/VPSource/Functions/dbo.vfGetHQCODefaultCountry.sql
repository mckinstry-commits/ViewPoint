SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfGetHQCODefaultCountry]
(@HQCo bCompany = null)
RETURNS CHAR(2)
/***********************************************************
* CREATED BY	: MV 12/17/12
* MODIFIED BY	
*
* USAGE:
* 	Returns HQCO Default Country 
*
* INPUT PARAMETERS:
*	@HQCo		HQ Company
*
* OUTPUT PARAMETERS:
*	@DefaultCountry		HQCo Default Country
*	
*
*****************************************************/
AS
BEGIN

DECLARE @DefaultCountry CHAR(2)

SELECT  @DefaultCountry = DefaultCountry
FROM dbo.bHQCO (nolock)
WHERE HQCo = @HQCo 
  			
RETURN ISNULL(@DefaultCountry,'US')
END
GO
GRANT EXECUTE ON  [dbo].[vfGetHQCODefaultCountry] TO [public]
GO
