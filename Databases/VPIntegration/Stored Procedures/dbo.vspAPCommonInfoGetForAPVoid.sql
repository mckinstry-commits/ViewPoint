SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspAPCommonInfoGetForAPVoid]
/********************************************************
* CREATED BY: 	KK 04/24/12 - B-08618 Scaled down the previously used LoadProc (vspAPCommonInfoGet) and added Credit Svc criteria
* MODIFIED BY:	
*
*      
* USAGE:
* 	Retrieves common info from AP Company for use in AP Void DDFH LoadProc field 
*
* INPUT PARAMETERS:
*	@co			AP Co#
*
* OUTPUT PARAMETERS:
*	@co				AP Co #
*	@glco			GL Co #
*	@cmco			CM Co #
*	@cmacct			CM Account #
*	@cscmco			Credit Service CM Company #
*	@cscmacct		Credit Service CM Account #
*	
* RETURN VALUE:
* 	0 			Success
*	1 + msg		Failure
*
**********************************************************/
 (	@co bCompany = 0,
	@glco bCompany = NULL OUTPUT,
	@cmco bCompany = NULL OUTPUT,
	@cmacct bCMAcct = NULL OUTPUT,
	@cscmco bCompany = NULL OUTPUT,
	@cscmacct bCMAcct = NULL OUTPUT,
	@msg varchar(100) OUTPUT )

AS
SET NOCOUNT ON

-- Get info from APCO
SELECT	@glco = GLCo,
		@cmco = CMCo, 
		@cmacct = CMAcct,
		@cscmco = CSCMCo,
		@cscmacct = CSCMAcct                
FROM APCO WITH(NOLOCK)
WHERE APCo = @co

IF @@rowcount = 0
BEGIN
	SELECT @msg = 'Company # ' + convert(varchar,@co) + ' not setup in AP'
	RETURN 1
END

RETURN 0


GO
GRANT EXECUTE ON  [dbo].[vspAPCommonInfoGetForAPVoid] TO [public]
GO
