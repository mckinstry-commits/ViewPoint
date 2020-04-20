SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSCompanyVal]
   /*************************************
   * Created By:   GF 02/24/2000
   * Modified By:
   *
   * validates MS Company number and returns Description from HQCo
   *
   * Pass:
   *	MS Company number
   *
   * Success returns:
   *	0 and Company name from HQCo
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = 0, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @msco = 0
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end
   
   if exists(select * from bMSCO where @msco = MSCo)
   	begin
   	select @msg = Name from bHQCO where HQCo = @msco
   	goto bspexit
   	end
   else
   	begin
   	select @msg = 'Not a valid MS Company', @rcode = 1
   	end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSCompanyVal] TO [public]
GO
