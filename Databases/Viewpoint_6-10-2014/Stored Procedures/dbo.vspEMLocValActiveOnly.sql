SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   procedure [dbo].[vspEMLocValActiveOnly]
/*************************************
* Created By:	GF 02/11/2013 TFS-40186 EM Location Active Flag
* Modified By:	
*
* Purpose: validates EM Location and returns error if inactive.
*
*	
*
* INPUT:
* EMCO
* Location
* 
*
* OUTPUT
* @Active flag
*
* Success returns:
* 0
*
* Error returns:
* 1 and error message
**************************************/
(@EMCo bCompany = null,
 @Location bLoc = null,
 @Active CHAR(1) = 'Y' OUTPUT,
 @msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT

SET @rcode = 0

---- do we have a location
IF ISNULL(@Location,'') = ''
	BEGIN
	SET @msg = 'Missing EM Location'   
	SET @rcode = 1
	GOTO vspexit
	END
  
---- get location info
SELECT  @msg = [Description]
		,@Active = Active
FROM dbo.EMLM
WHERE EMCo = @EMCo
	AND EMLoc = @Location
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @msg = 'Not a valid Location', @rcode = 1
	GOTO vspexit
	END
 IF @Active <> 'Y'
	BEGIN
	SELECT @msg = 'EM Location is inactive', @rcode = 1
	GOTO vspexit
	END  
   

vspexit:
   	IF @rcode <> 0 SELECT @msg = ISNULL(@msg,'')
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMLocValActiveOnly] TO [public]
GO
