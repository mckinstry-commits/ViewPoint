SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPOJobVal    Script Date: 8/28/99 9:33:10 AM ******/
CREATE  proc [dbo].[bspPOJobVal]
/***********************************************************
* CREATED BY: kb 10/26/98
* MODIFIED By : kb 12/4/98
*               GF 01/05/2001 Added check for tax based on job or vendor
*				MV 02/10/05 #27047 validate job.
*				CHS 11/16/2009	- issue #135565
*
* USAGE:
* validates PO Entry job using the standard job validation.
* an error is returned if any of the following occurs
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate agains
*   Job    Job to validate
*   VendorGroup
*   Vendor
* OUTPUT PARAMETERS
*   @jobstate
*   @msg      error message if error occurs otherwise Description of EarnCode
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = 0, @job bJob = null, @vendorgroup bGroup = null, @vendor bVendor = null,
@contract bContract output, @status tinyint output, @lockphases bYN output,
@taxcode bTaxCode output, @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int, @basetaxon varchar(1), @errmsg varchar(60)
   
   select @rcode = 0
   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @job is null
   	begin
   	select @msg = 'Missing Job!', @rcode = 1
   	goto bspexit
   	end
   
   if not exists (select 1 from JCJM where JCCo = @jcco and Job = @job) --#27047
   	begin
   	select @msg='Invalid Job!', @rcode=1
   	goto bspexit
   	end 
   
   exec @rcode = bspJCJMPostVal @jcco, @job, @contract output, @status output, @lockphases output,
   	@taxcode output, @msg=@errmsg output
   if @rcode = 1
   	begin
   	select @msg=@errmsg
   	goto bspexit
      	end
   
   if @status<1
   	begin
   	select @msg='Job status cannot be (Pending)', @rcode=1
   	goto bspexit
   	end
   
	select @msg=Description, @basetaxon=BaseTaxOn, @taxcode=TaxCode -- issue #135565
	from JCJM where JCCo = @jcco and Job = @job
	if @basetaxon = 'V'
	   begin
	   select @taxcode=TaxCode
	   from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor
	   end
   
	if @basetaxon = 'O'	-- issue #135565
		begin
		select @taxcode=isnull(TaxCode, @taxcode)
		from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor
		end

   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOJobVal] TO [public]
GO
