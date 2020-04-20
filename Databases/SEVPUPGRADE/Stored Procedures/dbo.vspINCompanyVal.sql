SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspINCompanyVal]
    /***********************************************************
     * CREATED BY: DANF 07/31/06
     * MODIFIED By : 
	 
     * USAGE:
     * validates IN Company number
     *
     * INPUT PARAMETERS
     *   INCo   IN Co to Validate
     *
     * OUTPUT PARAMETERS
     *   @glco				GL Company
	 *	 @matlgroup			Material Group
     *   @incooverridegl	Over Ride GL Account.
     *   @msg If Error, error message, otherwise description of Company
     * RETURN VALUE
     *   0   success
     *   1   fail
     *****************************************************/
    	(@inco bCompany = 0, @glco bCompany output, @matlgroup bGroup output, @incooverridegl bYN output, @msg varchar(60) output)
    as
    set nocount on
    declare @rcode int
    select @rcode = 0
    if @inco = 0
    	begin
    	select @msg = 'Missing IN Company#', @rcode = 1
    	goto bspexit
    	end
    select @glco=GLCo,  @incooverridegl = OverrideGL
	from dbo.INCO with (nolock)
	where INCo = @inco
        if @@rowcount=0
    	   begin
           select @msg = 'Not a valid IN Company', @rcode = 1
    	   goto bspexit
    	   end
        else
    	   begin
			select @msg = Name, @matlgroup = MatlGroup
			from dbo.HQCO with (nolock) 
			where HQCo = @inco
			if @@rowcount=0
    		   begin
			   select @msg = 'Missing Head Quarter', @rcode = 1
    		   goto bspexit
    		   end
    	   end
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINCompanyVal] TO [public]
GO
