SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspINCompanyVal    Script Date: 12/12/2001 3:29:11 PM ******/
   /****** Object:  Stored Procedure dbo.bspINCompanyVal    Script Date: 8/28/99 9:34:57 AM ******/
   CREATE proc [dbo].[bspINCompanyVal]
    /***********************************************************
     * CREATED BY: CJW 3/6/97
     * MODIFIED By : JM 12/29/99 - Removed an incorrect line in valid portion.
     * Modified by:  GR 1/29/00  add an output parameter to return GL Company
     *				RM 12/23/02 Cleanup Double Quotes
     *
     * USAGE:
     * validates IN Company number
     *
     * INPUT PARAMETERS
     *   INCo   IN Co to Validate
     *
     * OUTPUT PARAMETERS
     *   @msg If Error, error message, otherwise description of Company
     * RETURN VALUE
     *   0   success
     *   1   fail
     *****************************************************/
    	(@inco bCompany = 0, @glco bCompany output, @msg varchar(60) output)
    as
    set nocount on
    declare @rcode int
    select @rcode = 0
    if @inco = 0
    	begin
    	select @msg = 'Missing IN Company#', @rcode = 1
    	goto bspexit
    	end
    select @glco=GLCo from dbo.INCO with(nolock) where INCo = @inco
        if @@rowcount=0
    	   begin
           select @msg = 'Not a valid IN company ', @rcode = 1
    	   goto bspexit
    	   end
        else
    	   begin
           select @msg = Name from dbo.HQCO with(nolock) where HQCo = @inco
    	   end
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINCompanyVal] TO [public]
GO
