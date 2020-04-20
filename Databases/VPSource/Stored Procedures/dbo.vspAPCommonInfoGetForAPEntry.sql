SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAPCommonInfoGetForAPEntry]
/********************************************************
* CREATED BY: 	MV 04/07/05
* MODIFIED BY:	TJL 01/18/08 - Issue #123687, EMLineDescDflt and JobLineJobPhaseUMDflt enhancement
*		MV 06/24/08 - #128288 - return HQCO default country
*		TJL 03/12/09 - Issue #129889, SL Claims and Certifications
*		MV 07/08/09 - #134088 get EMGroup from HQCO = APCO.EMCO if <> @co
*		MV 02/01/10 - #136500 - get APCO TaxBasisNetRetgYN flag		
*		MH 04/02/11 - TK-02796 Add SM Pay Type output parameter
*		EN 01/05/2012 B-08098 added APCO_CSCMCo and APCo_CSCMAcct to output param list 
*								and reformatted code as per best practice
*		GF 10/20/2012 TK-18032 SL Claim enhancement clean up
*               
*
* USAGE:
* 	Retrieves common info use in APEntry, APUnapproved
*		and APRecur DDFH LoadProc  
*
* INPUT PARAMETERS:
*	AP Company
*
* OUTPUT PARAMETERS:
*	From APCO
*	From HQCO
*	From POCO
* From DDUP
*	From APPC
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@co bCompany=0, -- input
 @jcco bCompany OUTPUT, -- APCO
 @emco bCompany OUTPUT,
 @inco bCompany OUTPUT,
 @apglco bCompany OUTPUT,
 @glco bCompany OUTPUT,
 @cmco bCompany OUTPUT,
 @cmacct bCMAcct OUTPUT,
 @exppaytype int OUTPUT,
 @jobpaytype int OUTPUT,
 @subpaytype int OUTPUT,
 @retpaytype int OUTPUT,
 @retholdcode bHoldCode OUTPUT,
 @invtotyn bYN OUTPUT,
 @usetaxdiscyn bYN OUTPUT,
 @overridepaytype bYN OUTPUT,
 @netamtoptyn bYN OUTPUT,
 @paycategoryyn bYN OUTPUT,
 @paycategory int OUTPUT, --DDUP or APCO
 @defaultjoblinedesc bYN OUTPUT,
 @poreceiptupdateyn bYN OUTPUT,	-- POCO
 @vendorgroup bGroup OUTPUT,	-- HQCO
 @phasegroup bGroup OUTPUT,
 @matlgroup bGroup OUTPUT,
 @taxgroup bGroup OUTPUT,
 @emgroup bGroup OUTPUT,
 @appcexppaytype int OUTPUT, -- APPC
 @appcjobpaytype int OUTPUT,
 @appcsubpaytype int OUTPUT,
 @appcretpaytype int OUTPUT,
 @pocompchkyn bYN OUTPUT,
 @slcompchkyn bYN OUTPUT,
 @aprefunqyn bYN OUTPUT,
 @defaultemlinedesc bYN OUTPUT,
 @defaultjoblineJobPhaseUM bYN OUTPUT,
 @defaultHQCOcountry varchar(3) OUTPUT,
 @APCOTaxBasisNetRetgYN bYN OUTPUT,
 @smpaytype int OUTPUT,
 @appcsmpaytype int OUTPUT,
 @cscmco bCompany OUTPUT,
 @cscmacct bCMAcct OUTPUT,
 @msg varchar(100) OUTPUT)

AS 
SET NOCOUNT ON

DECLARE @userprofilepaycategory int, 
		@username bVPUserName
		
SELECT @userprofilepaycategory=0

-- Get info from APCO
SELECT 	@jcco = a.JCCo,
		@emco = a.EMCo,
		@inco = a.INCo,
		@apglco = a.GLCo,
		@glco = a.GLCo,
		@cmco = a.CMCo,
		@cmacct = a.CMAcct,
		@exppaytype = a.ExpPayType,
		@jobpaytype = a.JobPayType,
		@subpaytype = a.SubPayType,
		@retpaytype = a.RetPayType,
		@retholdcode = a.RetHoldCode,
		@invtotyn = a.InvTotYN,
		@usetaxdiscyn = a.UseTaxDiscountYN,
		@overridepaytype = a.OverridePayType,
		@netamtoptyn = a.NetAmtOpt,
		@paycategoryyn = a.PayCategoryYN,
		@paycategory = a.PayCategory,
		@defaultjoblinedesc = a.JobLineDescDfltYN,
		@pocompchkyn = a.POCompChkYN,                  
		@slcompchkyn = a.SLCompChkYN,
		@aprefunqyn = a.APRefUnqYN,
		@defaultemlinedesc = a.EMLineDescDfltYN,
		@defaultjoblineJobPhaseUM = a.JobLineJobPhaseUMDfltYN,
		@APCOTaxBasisNetRetgYN = a.TaxBasisNetRetgYN, 
		@smpaytype = a.SMPayType,
		@cscmco = a.CSCMCo,
		@cscmacct = a.CSCMAcct
FROM bAPCO a WITH (NOLOCK) 
LEFT JOIN bSLCO s ON s.SLCo = a.APCo
WHERE a.APCo = @co

IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'Company# ' + CONVERT(varchar,@co) + ' not setup in AP'
	RETURN 1
END

--Get EMGroup from HQCO if APCO.EMCo <> APCO
IF @emco IS NOT NULL AND @emco <> @co 
BEGIN
	SELECT @emgroup = ISNULL(EMGroup,0) 
	FROM HQCO 
	WHERE HQCo = @emco
END
IF @emco IS NULL OR @emco = @co
BEGIN
	SELECT @emgroup = ISNULL(EMGroup,0) 
	FROM HQCO 
	WHERE HQCo = @co
END

-- Get info from HQCO
SELECT	@vendorgroup = ISNULL(VendorGroup,0), 
		@matlgroup = ISNULL(MatlGroup,0), 
		@phasegroup = ISNULL(PhaseGroup,0),
		@taxgroup = ISNULL(TaxGroup,0),
		@defaultHQCOcountry = DefaultCountry 
FROM bHQCO 
WHERE HQCo = @co 

-- Get info from POCO
SELECT @poreceiptupdateyn = ReceiptUpdate 
FROM bPOCO 
WHERE POCo = @co

IF @@rowcount = 0
BEGIN
	SELECT @poreceiptupdateyn = 'N'
END

-- Get info from DDUP
IF @paycategoryyn = 'Y'
BEGIN
	SELECT @username = USER_NAME()
	SELECT @userprofilepaycategory = PayCategory 
	FROM vDDUP WITH (NOLOCK)
	WHERE UPPER(VPUserName) = UPPER(@username)
	IF ISNULL(@userprofilepaycategory, 0) > 0 SELECT @paycategory = @userprofilepaycategory 
END

-- If using Pay Category, get Pay Category Pay Types
IF @paycategoryyn = 'Y' AND @paycategory > 0
BEGIN
	SELECT	@appcexppaytype = ExpPayType,
			@appcjobpaytype = JobPayType,
			@appcsubpaytype = SubPayType,
			@appcretpaytype = RetPayType,
			@appcsmpaytype = SMPayType
	FROM bAPPC WITH (NOLOCK)
	WHERE APCo = @co AND PayCategory = @paycategory
END


RETURN 0



GO
GRANT EXECUTE ON  [dbo].[vspAPCommonInfoGetForAPEntry] TO [public]
GO
