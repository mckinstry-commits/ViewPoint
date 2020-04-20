SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspSLLoadProcCommonInfoGet]
/********************************************************
* CREATED BY: 	DC  5/22/07  - I need to get SLTotYN when SL Worksheet loads
* MODIFIED BY:	DC  7/23/07  - Modified sp so it can be used as the load proc for SL forms
*				TL 02/20/08 - Issue 21452
*				DC  06/18/08 - #128435 - return Country from HQCO for Tax defaults
*				GF 10/06/2012 TK-18354 added APRefUnqYN flag from APCO
*				GF 10/20/2012 TK-18032 removed user certified flag
*
*
* USAGE:
* 	Retrieves common info from AP Company for use in SL Worksheet
*	 
*
* INPUT PARAMETERS:
*	@co			AP Co#
*
* OUTPUT PARAMETERS:
*	@jcco				JC Co#
*	@glco				GL Co#
*	@cmco				CM Co#
*	@cmacct				CM Account
*	@vendorgroup		Vendor Group
*	@phasegrp			Phase Group
*	@sltotalyn			SLTotYN
*	@HQCountry			HQCO! Country 
*	@taxgroup			HQCO! TaxGroup
*	@APRefUnqYN			APCO: AP Reference Unique
*	
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
 (@co bCompany=0,
	@jcco bCompany =null output,
	@glco bCompany =null output,
	@cmco bCompany =null output,
	@cmacct bCMAcct =null output,
	@vendorgroup bGroup = null output,
	@phasegrp bGroup = null output,
	@sltotalyn bYN output,
	@attachbatchreports bYN output,
	@hqcountry char(2) output,  --DC #128435
	@taxgroup bGroup =  null output, --DC #128435
	----TK-18354
	@APRefUnqYN bYN = NULL OUTPUT,
	@errmsg varchar(255) output)

  as 
set nocount on
declare @rcode int
select @rcode = 0

	--Validate the SL Company+
	IF not exists(select top 1 1 from SLCO with (nolock) where SLCo = @co)
	BEGIN
		select @errmsg = 'Invalid SL Company.', @rcode = 1
		goto vspexit
	end

	select @attachbatchreports = IsNull(AttachBatchReportsYN,'N')
	From SLCO with(nolock) Where SLCo=@co

	-- Get info from APCO
	SELECT @jcco=JCCo, 
			@glco=GLCo,
			@cmco=CMCo, 
			@cmacct = CMAcct
			----TK-18354
			,@APRefUnqYN=APRefUnqYN
	FROM bAPCO with (nolock)
	WHERE APCo=@co

	SELECT @sltotalyn = SLTotYN 
	FROM bAPCO with (nolock)
	WHERE APCo = @co and JCCo = APCo

	-- Get info from HQCO
	SELECT  @vendorgroup =VendorGroup, @phasegrp = PhaseGroup, 
			@hqcountry = DefaultCountry, @taxgroup=TaxGroup  --DC #128435
	FROM bHQCO with (nolock)
	WHERE HQCo = @co 


vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSLLoadProcCommonInfoGet] TO [public]
GO
