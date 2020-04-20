SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE  procedure [dbo].[vspRPReportByFormParticipantLookupIDVal]
/******************************************************
* CREATED BY:	GP 5/23/2013 TFS-44904
* MODIFIED BY: 
*
* Usage:  Validates a RP Report by Form Participant Lookup ID value
*	
*
* Input params:
*
*	@LookupID - Lookup ID
*	
*	
*
* Output params:
*	@msg		Error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/

@LookupID INT, @msg VARCHAR(255) OUTPUT   	
   	
AS
BEGIN

	SET NOCOUNT ON
   		
	IF @LookupID IS NULL
	BEGIN
		SET @msg = 'Missing Builder Name.'
		RETURN 1
	END

		
	SELECT @msg = LookupDescription FROM VDocIntegration.ParticipantLookup WHERE LookupID = @LookupID
	IF @@ROWCOUNT = 0
	BEGIN
		SET @msg = 'Invalid Lookup ID.'
		RETURN 1
	END
	
	RETURN 0

END

GO
GRANT EXECUTE ON  [dbo].[vspRPReportByFormParticipantLookupIDVal] TO [public]
GO
