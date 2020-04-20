SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE PROCEDURE [dbo].[vspEMAssetCurrentFYEMO]
CREATE procedure [dbo].[vspEMAssetCurrentFYEMO]
/*************************************
* CREATED BY: DAN SO 06/16/2008 - Issue: 126847 - Return current FYEMO
* MODIFIED BY: DAN SO 07/22/2008 - Issue: 128708 - Return current FYEMO taking into account closed dates
*			DAN SO 03/30/2009 - Issue: #132648 - Added error message if cannot find current FYEM
*
* Returns current FYEMO
*
* Pass:
*	EMCO
*
* Success returns:
*	0 
*
* Error returns:
*	1 and error message
**************************************/
(@EMCo bCompany = NULL, 
 @CurrFYEMO bMonth OUTPUT, @errmsg VARCHAR(200) OUTPUT)

AS

	SET NOCOUNT ON

   	DECLARE	@CurrDate	bMonth,
			@rcode		int


	------------------
	-- PRIME VALUES --
	------------------
	SET @CurrDate = GETDATE()
	SET	@rcode = 0
   	
	IF @EMCo IS NULL
		BEGIN
			SELECT @errmsg = 'Missing Company', @rcode = 1
			GOTO vspExit
		END

	-----------------------
	-- GET CURRENT FYEMO --
	-----------------------
	SELECT @CurrFYEMO = MIN(y.FYEMO) 
	  FROM GLCO o WITH (NOLOCK)
	  JOIN GLFY y WITH (NOLOCK) ON o.GLCo = y.GLCo
	 WHERE o.GLCo = @EMCo
	   AND o.LastMthGLClsd < y.FYEMO
	   AND y.FYEMO >= @CurrDate 
	

	IF @CurrFYEMO IS NULL
		BEGIN
			SET @errmsg = 'Cannot locate a fiscal year end month for the current year.' + CHAR(10) +
							'Please verify a FYEM for the current year is set up in GL Fiscal Years.'
			SET @rcode = 1
			GOTO vspExit
		END


--------------------
-- ERROR HANDLING --
--------------------
vspExit:
   	IF @rcode <> 0 SELECT @errmsg = ISNULL(@errmsg,'')
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMAssetCurrentFYEMO] TO [public]
GO
