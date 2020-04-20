SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE proc [dbo].[vspPMGetNextCOR]
CREATE proc [dbo].[vspPMGetNextCOR]
/*************************************
* CREATED BY:	DAN SO 3/24/2011
* MODIFIED BY:	
*
*
*	Get next COR number.
*
*
* INPUT
*	@PMCo		- PM Compnay
*	@Contract	- Contract
*	
* OUTPUT
*	@NextCOR	- Next COR Value
*	@msg		- Failure -> Error Message
*
**************************************/
   (@PMCo bCompany = NULL, @Contract bContract = NULL,
    @NextCOR smallint output, @msg varchar(255) output)
      
	AS
	
	SET NOCOUNT ON 
	
	DECLARE	@rcode int
	
	
	------------------
	-- PRIME VALUES --
	------------------
	SET @rcode = 0
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
	
	IF @Contract IS NULL
		BEGIN
			SET @msg = 'Missing Contract!'
			SET @rcode = 1
			GOTO vspexit
		END
	
   
	------------------
	-- GET NEXT COR --	
	------------------
	SELECT  @NextCOR = ISNULL(MAX(COR),0) + 1
	  FROM	vPMChangeOrderRequest WITH (NOLOCK)
	 WHERE	PMCo = @PMCo
	   AND	[Contract] = @Contract
   
	IF @@ROWCOUNT = 0
		BEGIN
			SET @msg = 'Error getting next COR value!'
			SET @rcode = 1
			GOTO vspexit
		END
   
   
   
	vspexit:
   		RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMGetNextCOR] TO [public]
GO
