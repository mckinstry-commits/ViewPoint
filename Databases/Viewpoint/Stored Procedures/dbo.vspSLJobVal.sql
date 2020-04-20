SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspSLJobVal    Script Date: 11/05/2009 10:00:05 AM ******/
   CREATE  proc [dbo].[vspSLJobVal]
   /***********************************************************
    * CREATED BY:		GP	11/05/2009	- Issue #132805
    * MODIFIED By:		CHS 11/16/2009	- issue #135565	 
    *					GF  06/25/2010  - issue #135813 expanded SL to varchar(30)
    *
    * USAGE:
    * Validates SL Entry & SL Add Item - Job using the standard job validation.
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   @jcco   JC Co to validate agains
    *   @job    Job to validate
    *	@vendorgroup
    *	@vendor
    * OUTPUT PARAMETERS
    *   @contract
    *	@status
    *	@lockphases
    *	@taxcode
    *   @msg      error message if error occurs otherwise Description of EarnCode
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@slco bCompany = 0, @jcco bCompany = 0, @job bJob = null, 
	@vendorgroup bGroup = null, @vendor bVendor = null, @sl VARCHAR(30) = null,
    @contract bContract = null output, @status tinyint = null output, @lockphases bYN = null output,
    @taxcode bTaxCode = null output, @usedefaulttax bYN = null output, @msg varchar(60) output)
   as
   set nocount on
   
	declare @rcode int, @basetaxon varchar(1), @errmsg varchar(60)

	select @rcode = 0
   
	--Validation
	if @jcco is null
	begin
		select @msg = 'Missing JC Company!', @rcode = 1
		goto vspexit
	end

	if @job is null
	begin
		select @msg = 'Missing Job!', @rcode = 1
		goto vspexit
	end

	if not exists (select 1 from JCJM where JCCo = @jcco and Job = @job) --#27047
	begin
		select @msg='Invalid Job!', @rcode=1
		goto vspexit
	end 

	--Get JCJM Status, LockPhases, and TaxCode
	exec @rcode = bspJCJMPostVal @jcco, @job, @contract output, @status output, @lockphases output,
	@taxcode output, null, null, null, null, null, null, null, null, @usedefaulttax output, @msg=@errmsg output
	if @rcode = 1
	begin
		select @msg=@errmsg
		goto vspexit
	end

	if @status<1
	begin
		select @msg='Job status cannot be (Pending)', @rcode=1
		goto vspexit
	end

	--Get VendorGroup and Vendor if not passed in based off SL
	if @vendorgroup is null and @vendor is null
	begin
		select @vendorgroup=VendorGroup, @vendor=Vendor
		from dbo.SLHD with (nolock)
		where SLCo=@slco and SL=@sl
	end


	--If JCJM.BaseTaxOn = V-Vendor then use APVM.TaxCode
	select @msg=Description, @basetaxon=BaseTaxOn, @taxcode=TaxCode -- issue #135565
	from dbo.JCJM with (nolock) where JCCo=@jcco and Job=@job
	if @basetaxon = 'V'
	begin
		select @taxcode=TaxCode
		from dbo.APVM with (nolock)
		where VendorGroup=@vendorgroup and Vendor=@vendor
	end
  
	if @basetaxon = 'O'	-- issue #135565
		begin
		select @taxcode=isnull(TaxCode, @taxcode)
		from bAPVM with (nolock) where VendorGroup=@vendorgroup and Vendor=@vendor
		end


	vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSLJobVal] TO [public]
GO
