SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE proc [dbo].[vspPMRFIResponsePullLastResponse]
   
   /***********************************************************
    * CREATED BY:	JG	09/07/2010 - Issue #140529
    * MODIFIED BY:	
    *
    * USAGE:
    * Return last response entered for RFIKeyID.
    *
    *
    * INPUT PARAMETERS
    *	@RFIKeyID
    *
    * OUTPUT PARAMETERS
    *	Dataset containing latest response.
    *
    * RETURN VALUE
    *   0         Success
    *   1         Failure or nothing to format
    *****************************************************/
   (@RFIKeyID bigint, @msg varchar(255) output)
	AS
	BEGIN
	
		SET NOCOUNT ON

		IF @RFIKeyID IS NULL
		BEGIN
			SET @msg = 'The RFIKeyID must be supplied'
			RETURN 1
		END

		SELECT TOP 1 RespondFirm, RespondContact, ToFirm, ToContact 
		FROM PMRFIResponse
		WHERE RFIID = @RFIKeyID
		ORDER By KeyID DESC
	END
GO
GRANT EXECUTE ON  [dbo].[vspPMRFIResponsePullLastResponse] TO [public]
GO
