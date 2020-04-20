SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPOCopyDefaultTaxCodes]
   /***********************************************************
    * Created By:	GF 03/24/2003
    * Modified By:
    * 
    *
    * USAGE: returns Tax Codes to the bspPOCopy stored procedure
    *
    * INPUT PARAMETERS
    *	POCo
    *	VendorGroup
    *	Vendor
    *	JCCo
    *	Job
    *	ShipLocation
    *	INCo
    *	InLocation
    *
    * OUTPUT PARAMETERS
    *	@vendortaxcode
    *	@jobtaxcode
    *	@invtaxcode
    *	@posltaxcode
    *  @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@poco bCompany = null, @vendorgroup bGroup = null, @vendor bVendor = null, @jcco bCompany = null,
    @job bJob = null, @shiploc varchar(10) = null, @inco bCompany = null, @inloc bLoc = null,
    @vendortaxcode bTaxCode output, @jobtaxcode bTaxCode output, @invtaxcode bTaxCode output,
    @posltaxcode bTaxCode output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @basetaxon varchar(1)
   
   select @rcode = 0
   
   if @poco is null
   	begin
   	select @msg = 'Missing PO Company!', @rcode = 1
   	goto bspexit
   	end
   
   -- vendor tax code
   if @vendor is not null
   	begin
   	select @vendortaxcode=TaxCode
   	from bAPVM with (nolock) where VendorGroup=@vendorgroup and Vendor=@vendor
   	end
   
   -- job tax code
   if @jcco is not null and @job is not null
   	begin
   	select @jobtaxcode=TaxCode, @basetaxon=BaseTaxOn
   	from bJCJM with (nolock) where JCCo=@jcco and Job=@job
   	if @@rowcount <> 0 and @basetaxon = 'V' select @jobtaxcode=@vendortaxcode
   	end
   
   -- inventory tax code
   if @inco is not null and @inloc is not null
   	begin
   	select @invtaxcode=TaxCode
   	from bINLM with (nolock) where INCo=@inco and Loc=@inloc
       end
   
   -- ship location tax code
   if @shiploc is not null
   	begin
   	select @posltaxcode=TaxCode
   	from bPOSL with (nolock) where POCo=@poco and ShipLoc=@shiploc
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOCopyDefaultTaxCodes] TO [public]
GO
