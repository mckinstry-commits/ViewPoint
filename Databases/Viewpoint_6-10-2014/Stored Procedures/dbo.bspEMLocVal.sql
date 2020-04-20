SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   procedure [dbo].[bspEMLocVal]
/*************************************
* Created By:	TV 02/11/04 - 23061 added isnulls
* Modified By:	GF 02/07/2013 TFS-40037 added output param for active flag
*
* Purpose: validates Location
*
*	
*
* INPUT:
* EMCO, Location
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
(@EMCo bCompany = null, @Location bLoc = null,
 @Active CHAR(1) = 'Y' OUTPUT,
 @msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT

SET @rcode = 0

---- do we have a location
IF ISNULL(@Location,'') = ''
	BEGIN
	SELECT @msg = 'Missing location', @rcode = 1
	GOTO bspexit
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
	GOTO bspexit
	END
   

bspexit:
   	IF @rcode <> 0 SELECT @msg = ISNULL(@msg,'')
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMLocVal] TO [public]
GO
