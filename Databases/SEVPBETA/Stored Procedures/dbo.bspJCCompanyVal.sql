SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCCompanyVal    Script Date: 8/28/99 9:35:01 AM ******/
   CREATE   proc [dbo].[bspJCCompanyVal]
   /*************************************
   *	modified: TV - 23061 added isnulls
   *
   * validates JC Company number and returns Description from HQCo
   *	
   * Pass:
   *	JC Company number
   *
   * Success returns:
   *	0 and Company name from bJCCO
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@jcco bCompany = 0, @msg varchar(60) output)
   as 
   set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @jcco = 0
   	begin
   	select @msg = 'Missing JC Company#', @rcode = 1
   	goto bspexit
   	end
   
if exists(select * from JCCO where @jcco = JCCo)
	begin
	select @msg = Name from HQCO where HQCo = @jcco
	goto bspexit
	end
else
	begin
	select @msg = 'Not a valid JC Company', @rcode = 1
	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCompanyVal] TO [public]
GO
