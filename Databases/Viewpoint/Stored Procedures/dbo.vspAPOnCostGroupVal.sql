SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspAPOnCostGroupVal]
/***********************************************************
* CREATED BY: CHS 01/13/2012 - B-08283 - AP OnCost 
* MODIFIED By :	
*              
*
* USAGE:
* validates an OnCost Group and returns the description
* 
* INPUT PARAMETERS
*	APCo   
*	GroupID
*
* OUTPUT PARAMETERS
*	 
*    @msg If Error, error message, otherwise description of OnCostType
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/ 
  	(@APCo bCompany, @GroupID tinyint = NULL, @msg VARCHAR(200)OUTPUT)
  AS
  
  SET NOCOUNT ON
  
  
  DECLARE @RCode int
  SELECT @RCode = 0
  	
 IF @APCo IS NULL
 BEGIN
  	SELECT @msg = 'Missing AP Company', @RCode = 1
  	RETURN @RCode
 END
 
 IF @GroupID IS NOT NULL
 BEGIN
	IF EXISTS(
				SELECT * 
				FROM dbo.vAPOnCostGroups 
				WHERE APCo=@APCo AND GroupID=@GroupID
			)
  	BEGIN
  		SELECT @msg = Description 
  		FROM dbo.vAPOnCostGroups 
  		WHERE  APCo=@APCo AND GroupID=@GroupID
  	END
	ELSE
  	BEGIN
  		SELECT @msg = 'Not a valid OnCost group.', @RCode = 1
  	END
 END
  
 RETURN @RCode

GO
GRANT EXECUTE ON  [dbo].[vspAPOnCostGroupVal] TO [public]
GO
