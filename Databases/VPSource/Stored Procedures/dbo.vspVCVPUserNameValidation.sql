SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspVCVPUserNameValidation]

(@vpUserName bVPUserName = NULL, @msg VARCHAR(60) = NULL OUTPUT)
AS 
SET NOCOUNT ON
   	DECLARE @rcode INT
   	SELECT @rcode = 0
   	
   	IF @vpUserName IS NULL
   		BEGIN
   			GOTO spExit
   		END
   	
	SELECT @msg = VPUserName FROM DDUP WITH (NOLOCK) WHERE VPUserName = @vpUserName
	
	IF @@rowcount = 0
   		BEGIN
   			SELECT @msg = 'Invalid VP User Name', @rcode = 1
	   		GOTO spError
   		END
	
	SELECT @msg = VPUserName FROM VCUsers WITH (NOLOCK) WHERE VPUserName = @vpUserName
	
	IF @@rowcount > 0
		BEGIN
			SELECT @msg = 'VPUserName already in use by another Connects user', @rcode=1
			GOTO spError
		END
	
	spExit:
		RETURN @rcode

	spError:
	
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVCVPUserNameValidation] TO [public]
GO
