SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE  procedure [dbo].[vspRPFRDefaultParticipantsLookupIDVal]
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

@Form VARCHAR(30), @ReportID INT, @LookupID INT, @msg VARCHAR(255) OUTPUT   	
   	
AS
BEGIN

	SET NOCOUNT ON
   		
	IF @LookupID IS NULL
	BEGIN
		SET @msg = 'Missing Builder Name.'
		RETURN 1
	END

	--Check that lookup id exists in source table	
	SELECT @msg = LookupDescription FROM VDocIntegration.ParticipantLookup WHERE LookupID = @LookupID
	IF @@ROWCOUNT = 0
	BEGIN
		SET @msg = 'Invalid Lookup ID.'
		RETURN 1
	END

	--Check that lookup id hasn't already been used on this parent record
	IF EXISTS (SELECT 1 FROM VDocIntegration.ParticipantLookupRPForm WHERE Form = @Form AND ReportID = @ReportID AND LookupID = @LookupID)
	BEGIN
		SET @msg = 'Lookup ID ' + CAST(@LookupID AS VARCHAR(20)) + ' has already been assigned to this Report by Form record.'
		RETURN 1
	END
	
	RETURN 0

END

GO
GRANT EXECUTE ON  [dbo].[vspRPFRDefaultParticipantsLookupIDVal] TO [public]
GO
