SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
*    CREATED BY: Lane Gresham
*  CREATED DATE: 8/23/12
*   MODIFIED BY: 
* 
* USAGE:
*	Validates TaxCode including the Tax redirects.
* 
***********************************************************/

CREATE   proc [dbo].[vspJCTaxCodeVal] 
(
	@taxgroup bGroup = NULL, 
   	@taxcode bTaxCode = NULL, 
   	@compdate bDate = NULL, 
   	@taxtype int = NULL,
   	@jcco bCompany = NULL,
   	@job bJob = NULL,
   	@phasegroup tinyint = NULL,
   	@phase bPhase = NULL,
	@taxrate bRate = NULL OUTPUT, 
	@gstrate bRate = NULL OUTPUT, 
	@taxphase bPhase = NULL OUTPUT, 
	@taxjcctype bJCCType = NULL OUTPUT, 
	@pstrate bRate = NULL OUTPUT, 
	@msg varchar(256) = NULL OUTPUT
)
AS
BEGIN
   
	SET NOCOUNT ON
   
	DECLARE @rcode tinyint

	--Validates the Tax Code
	EXEC @rcode = vspHQTaxCodeVal @taxgroup, @taxcode, @compdate, @taxtype,
								  @taxrate OUTPUT, @gstrate OUTPUT, @taxphase OUTPUT, 
								  @taxjcctype OUTPUT, @pstrate OUTPUT, @msg OUTPUT
	IF (@rcode <> 0)
	BEGIN
		SET @msg = @msg
		RETURN @rcode
	END

	--Validates if a Job
	IF @job IS NOT NULL AND 
	   @taxphase IS NOT NULL 
	BEGIN
	
		EXEC @rcode = bspJCVPHASE @jcco = @jcco, @job = @job, @phase = @taxphase, @phasegroup = @phasegroup, 
								  @msg = @msg OUTPUT
		IF (@rcode <> 0)
		BEGIN
			SET @msg = 'Tax redirect: ' + @msg
			RETURN @rcode
		END
		
		-- Validate the @taxjcctype with the @taxphase
		IF @taxjcctype IS NOT NULL
		BEGIN 
			EXEC @rcode = bspJCVCOSTTYPE @jcco = @jcco, @job = @job, @PhaseGroup = @phasegroup, @phase = @taxphase, @costtype = @taxjcctype, 
										 @msg = @msg OUTPUT
			IF (@rcode <> 0)
			BEGIN
				SET @msg = 'Tax redirect: ' + @msg
				RETURN @rcode
			END
		END
		
	END
	ELSE IF @job IS NOT NULL AND 
			@phase IS NOT NULL AND 
			@taxjcctype IS NOT NULL
	BEGIN
		
		-- Validate the @taxjcctype with the @phase
		EXEC @rcode = bspJCVCOSTTYPE @jcco = @jcco, @job = @job, @PhaseGroup = @phasegroup, @phase = @phase, @costtype = @taxjcctype, 
								     @msg = @msg OUTPUT
		IF (@rcode <> 0)
		BEGIN
			SET @msg = 'Tax redirect: ' + @msg
			RETURN @rcode
		END
		
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspJCTaxCodeVal] TO [public]
GO
