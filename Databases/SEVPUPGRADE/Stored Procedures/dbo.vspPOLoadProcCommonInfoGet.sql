SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPOLoadProcCommonInfoGet]
/********************************************************
* CREATED BY: 	DC 07/23/2007
* MODIFIED BY:	TRL 02/20/08 - Issue 21452
*				DC 08/21/08 - #128925 - Added HQ Country to the output params
*              
* USAGE:
* 	Retrieves common info from AP Company for use in various
*	PO form's DDFH LoadProc field 
*
* INPUT PARAMETERS:
*	@co			PO Co#
*
* OUTPUT PARAMETERS:
*	@glco				GL Co#
*	@vendorgroup		Vendor Group
*	@taxgroup			Tax Group from bHQCO
*	
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
 (@co bCompany=0, @glco bCompany =null output, @vendorgroup bGroup = null output,
	@taxgroup tinyint = null output, @attachbatchreports bYN output, 
	@hqcountry char(2) output,  --DC #128925
	@errmsg varchar(255) output)

  as 
set nocount on
declare @rcode int
select @rcode = 0

	--Validate the PO Company+
	IF not exists(select top 1 1 from dbo.POCO with (nolock) where POCo = @co)
	BEGIN
		select @errmsg = 'Invalid PO Company.', @rcode = 1
		goto vspexit
	end
	
	Select @attachbatchreports = IsNull(AttachBatchReportsYN,'N') From dbo.POCO with(nolock) Where POCo = @co

	-- Get info from APCO
	SELECT @glco=GLCo	
	FROM dbo.APCO with (nolock)
	WHERE APCo=@co
	IF @@rowcount < 1 
		BEGIN
		select @errmsg = 'Invalid Company.', @rcode = 1
		goto vspexit
		end

 
	-- Get info from HQCO
	SELECT  @vendorgroup =VendorGroup,
			@taxgroup = TaxGroup,
			@hqcountry = DefaultCountry  --DC #128925
	FROM dbo.HQCO with (nolock)
	WHERE HQCo = @co 
	IF @@rowcount < 1 
		BEGIN
		select @errmsg = 'Invalid Company.', @rcode = 1
		goto vspexit
		end



vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPOLoadProcCommonInfoGet] TO [public]
GO
