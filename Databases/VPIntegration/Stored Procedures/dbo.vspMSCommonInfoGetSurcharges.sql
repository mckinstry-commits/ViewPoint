SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************
* Created By:  DAN SO 10/01/2009 - ISSUE: #129350
* Modified By: GF 03/31/2010 - #129350 added em group to output
*
*
*
*
* USAGE:
* Gets MS company info for use in MS Surcharge program.
*
* Returns success, or error
*
* INPUT PARAMETERS
* @msco - MS Company to use to get company info
*
* OUTPUT PARAMETERS
*	@matlgroup			Material Group assigned in bHQCO
*
*	@errmsg				Error message
*
* RETURN VALUE
*   0 - Success
*   1 - Failure
*
*****************************************************/
--CREATE PROC [dbo].[vspMSCommonInfoGetSurcharges]
CREATE PROC [dbo].[vspMSCommonInfoGetSurcharges]

   (@msco bCompany = 0,
	@MatlGroup bMatl = null output,
	@EMGroup bGroup = null output,
	@errmsg varchar(255) output)
	
AS
SET NOCOUNT ON


	DECLARE @rcode int


	-- PRIME VARIABLES --
	SET @rcode = 0

	------------------------------
	-- CHECK INCOMING PARAMTERS --
	------------------------------
	IF @msco IS NULL
		BEGIN
			SELECT @errmsg = 'Missing MS Company!', @rcode = 1
			GOTO vspexit
		END


	---------------------
	-- GET INFORMATION --
	---------------------

	-- GET MatlGroup --
	SELECT @MatlGroup = MatlGroup, @EMGroup=EMGroup
	  FROM HQCO WITH (NOLOCK) 
	 WHERE HQCo = @msco

	IF @MatlGroup IS NULL
		BEGIN
			SELECT @errmsg = 'Material group not setup for company ' + CONVERT(varchar(3), ISNULL(@msco,'')) + '!', @rcode=1
			GOTO vspexit
		END


-----------------
-- END ROUTINE --
-----------------
vspexit:
	IF @rcode <> 0 
		SET @errmsg = isnull(@errmsg,'')
		
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSCommonInfoGetSurcharges] TO [public]
GO
