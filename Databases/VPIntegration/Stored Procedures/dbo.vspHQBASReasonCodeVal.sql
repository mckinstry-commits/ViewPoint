SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


	CREATE  procedure [dbo].[vspHQBASReasonCodeVal]
	/******************************************************
	* CREATED BY:	MV 03/07/11 - #138181
	* MODIFIED By: 
	*
	* Usage:	Validates HQ BAS Reason Code and returns description.  
	*			Called from PRAUEmployerBAS.
	*
	* Input params:
	*
	*	@ReasonCode - HQ BAS Reason Code	
	*	
	*
	* Output params:
	*	@Msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@ReasonCode tinyint, @Msg varchar(100) output)
	AS
	SET NOCOUNT ON
	DECLARE @rcode INT

	SELECT @rcode = 0
                     
	IF @ReasonCode IS NULL
	BEGIN
		SELECT @Msg = 'Missing Reason Code.', @rcode = 1
		GOTO  vspexit
	END

	IF EXISTS
		(
			SELECT 1 
			FROM dbo.HQBASReasonCodes 
			WHERE ReasonCode=@ReasonCode
		)
	BEGIN
		SELECT @Msg = [Reason]
		FROM dbo.HQBASReasonCodes
		WHERE ReasonCode=@ReasonCode
	END
	ELSE
	BEGIN
		SELECT @Msg = 'Invalid Reason Code.', @rcode = 1
	END
	
	 
	vspexit:
	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspHQBASReasonCodeVal] TO [public]
GO
