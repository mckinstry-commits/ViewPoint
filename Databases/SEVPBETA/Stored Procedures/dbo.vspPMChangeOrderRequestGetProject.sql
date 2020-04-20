SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE proc [dbo].[vspPMChangeOrderRequestGetProject]
CREATE  proc [dbo].[vspPMChangeOrderRequestGetProject]
/***********************************************************
* CREATED BY:	DAN SO	03/26/2011
* MODIFIED BY:	
*				
* USAGE:
* Return a valid Project from a Contract
*
* INPUT PARAMETERS
*   PMCo   
*   Contract
*
* OUTPUT PARAMETERS
*	@Project	- PM Project associated with the Contract
*   @msg		- Description of Department if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

	(@PMCo bCompany = NULL, @Contract bContract = NULL, 
	 @Project bProject output, @msg varchar(255) output)
	 
	AS
	SET NOCOUNT ON


	DECLARE	@rcode int
	
	SET @rcode = 0

	-------------------------------
	-- CHECK INCOMING PARAMETERS --
	-------------------------------
	IF @PMCo IS NULL
		BEGIN
			SET @msg = 'Missing PM Company.'
			SET @rcode = 1
			GOTO vspexit
		END

	IF @Contract IS NULL
		BEGIN
			SET @msg = 'Missing Contract.'
			SET @rcode = 1
			GOTO vspexit
		END


	-------------------------------
	-- GET AN ASSOCIATED PROJECT --
	-------------------------------

	 --IF PROJECT = CONTRACT - USE IT --
	SELECT	@Project = Project
	  FROM	dbo.JCJMPM with (NOLOCK)
	 WHERE	PMCo = @PMCo
	   AND	Project = @Contract

	-- GET ANY ASSOCIATED PROJECT -- (1)
	IF @Project IS NULL
		BEGIN
			-- GET FIRST PROJECT --
			SELECT	TOP 1 @Project = Project
			  FROM	dbo.JCJMPM with (NOLOCK)
			 WHERE	PMCo = @PMCo
			   AND	Contract = @Contract
			   
			-- GET ANY PROJECT IN THE PMDistribution TABLE -- (2)
			IF @Project IS NULL
				BEGIN
					-- GET ANY PROJECT --
					SELECT	TOP 1 @Project = Project
					  FROM	dbo.PMDistribution with (NOLOCK)
					 WHERE	PMCo = @PMCo			   
			   
					-- CHECK FOR A VALID PROJECT --
					IF @Project IS NULL
						BEGIN
							SET @msg = 'Could not find a Project associated with Contract .' + ISNULL(@Contract,'N/A')
							SET @rcode = 1
							GOTO vspexit
						END	
						
				END -- (2)		   
		END -- (1)

		
	vspexit:
		RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMChangeOrderRequestGetProject] TO [public]
GO
