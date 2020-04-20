SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE proc [dbo].[vspPMGetContractFromProject]
CREATE proc [dbo].[vspPMGetContractFromProject]
/*************************************
* CREATED BY:	DAN SO 3/24/2011
* MODIFIED BY:	
*
*
*	Return the Contract associated with the Project.
*
*
* INPUT
*	@PMCo		- PM Compnay
*	@Project	- PM Project
*	
* OUTPUT
*	@Contract	- Contract
*	@msg		- Succesful -> Contract Description
*				- Failure -> Error Message
*
**************************************/
   (@PMCo bCompany = NULL, @Project bProject = NULL,
    @Contract bContract output, @msg varchar(255) output)
   
   
	AS
	
	SET NOCOUNT ON 
	
	DECLARE	@rcode int
	
	
	------------------
	-- PRIME VALUES --
	------------------
	SET @rcode = 0
	SET @Contract = ''
	SET @msg = ''
	 
	 
	----------------------------
	-- CHECK INPUT PARAMETERS --
	----------------------------
	IF @PMCo IS NULL
		BEGIN
			SET @msg = 'Missing PM Company!'
			SET @rcode = 1
			GOTO vspexit
		END
	
	IF @Project IS NULL
		BEGIN
			SET @msg = 'Missing PM Project!'
			SET @rcode = 1
			GOTO vspexit
		END
	
   
	-----------------------------
	-- GET ASSOCIATED CONTRACT --	
	-----------------------------
	SELECT  @Contract = [Contract], @msg = [Description]
	  FROM	JCJMPM WITH (NOLOCK)
	 WHERE	PMCo = @PMCo
	   AND	Project = @Project
   
	IF @@ROWCOUNT = 0
		BEGIN
			SET @msg = 'No Contract Found!'
			SET @rcode = 1
			GOTO vspexit
		END
   
   
   
	vspexit:
   		RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMGetContractFromProject] TO [public]
GO
