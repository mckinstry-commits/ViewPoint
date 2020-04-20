SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  Procedure [dbo].[vspAPOnCostTypeDesc]
/***********************************************************
* CREATED BY:	CHS	01/24/2012	- B-08285 - added ouput fields.
* MODIFIED By:
*              
*
* USAGE:
* validates an OnCostType and returns the description
* 
* INPUT PARAMETERS
*	APCo   
*	OnCostID
*
* OUTPUT PARAMETERS
*	 
*    @msg If Error, error message, otherwise description of OnCostType
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/ 
(@APCo bCompany, 
	@OnCostID tinyint = NULL, 
  	@msg VARCHAR(200)OUTPUT)
  	
  AS
  
  SET NOCOUNT ON  
  
  DECLARE @RCode int
  SELECT @RCode = 0
  
 	
 IF @APCo IS NULL
 BEGIN
  	SELECT @msg = 'Missing AP Company', @RCode = 1
  	RETURN @RCode
 END
  
 IF @OnCostID IS NOT NULL
	BEGIN
			
	IF EXISTS(
			SELECT TOP 1 1 
			FROM dbo.vAPOnCostType 
			WHERE APCo=@APCo AND OnCostID=@OnCostID
		)
		BEGIN
			SELECT @msg = Description
			FROM dbo.vAPOnCostType 
			WHERE  APCo=@APCo AND OnCostID=@OnCostID
											
		END
				
	END
	
	 
 RETURN @RCode

GO
GRANT EXECUTE ON  [dbo].[vspAPOnCostTypeDesc] TO [public]
GO
