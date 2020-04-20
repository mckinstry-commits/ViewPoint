SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************/
   CREATE   proc [dbo].[vspDMAttIndexGetVendorGroupFromJCCo]
   /*********************************************
    * Created by:	 JonathanP 06/07/2007
    * Histroy:		 JonathanP 06/27/2007 - Now gets the Vendor group from HQCO instead of APCO, since APCO might be secured.	
    *				 JonathanP 06/18/2008 - See #128718. Now we check if the company exists in PMCO and JCCO. In addition,we 
    *										don't throw an error if the vendor can not be found.  										
    *
    * Gets the vendor group for a given JC Company. This is used in the Attachment Index form to get the firm number.
    *
    * Inputs:
	*		@jcco - The JC Company.
    *
    * Outputs:
    *		@vendorgroup - The vendor group for that JC Company.
    *		@msg - Error message string.
	*
    * Success returns:
    *      
    *
    * Error returns:
    
    *	1 and error message
    **************************************/
    (@jcco bCompany, @vendorgroup bGroup output, @msg varchar(255) output)
    as
    set nocount on
    
    declare @rcode int
    select @rcode = 0

	if not exists(select 1 from PMCO where PMCo=@jcco) and not exists(select 1 from JCCO where JCCo=@jcco) -- #128718
		begin
		select @msg = 'Invalid company.', @rcode = 1
		goto bspexit
		end
    
    -- Try to get a vendor group. See issue #128718
	select distinct @vendorgroup = HQCO.VendorGroup 
	from HQCO 
	join PMCO on dbo.PMCO.APCo = dbo.HQCO.HQCo 
	where dbo.PMCO.PMCo = @jcco
   
    -- Commented out for #128718.
	--if @@ROWCOUNT = 0
	--begin
		--select @msg = 'Error: Can not return the vendor group for the given Job Cost Company.'
		--select @rcode = 1
		--goto bspexit
	--end	
	--
   

   bspexit:
   	if @rcode <> 0 
		select @msg = isnull(@msg,'')
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDMAttIndexGetVendorGroupFromJCCo] TO [public]
GO
