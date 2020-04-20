SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspAPOnCostTypeVal]
/***********************************************************
* CREATED BY:	MV	01/09/2012	- B-08283 - AP OnCost 
* MODIFIED By:	CHS	01/24/2012	- B-08285 - added ouput fields.
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
	@CalcMethod char(1) OUTPUT,	
  	@Rate bUnitCost OUTPUT,	
  	@Amount bDollar OUTPUT,	
  	@PayType tinyint OUTPUT,
  	@OnCostVendor bVendor OUTPUT,
  	@ATOCategory varchar(4) OUTPUT,
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
			SELECT @msg = Description, @CalcMethod = CalcMethod, @Rate = Rate, @Amount = Amount, 
				@PayType = PayType, @ATOCategory = ATOCategory, @OnCostVendor = OnCostVendor
			FROM dbo.vAPOnCostType 
			WHERE  APCo=@APCo AND OnCostID=@OnCostID
											
		END
		
	ELSE
		BEGIN
			SELECT @msg = 'Not a valid OnCostID.', @RCode = 1
		END	
		
	END
		
ELSE
	BEGIN
		SELECT @msg = 'Not a valid OnCostID.', @RCode = 1
	END		
	 
 RETURN @RCode

GO
GRANT EXECUTE ON  [dbo].[vspAPOnCostTypeVal] TO [public]
GO
