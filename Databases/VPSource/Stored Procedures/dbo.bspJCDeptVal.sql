SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCDeptVal    Script Date: 8/28/99 9:35:02 AM ******/
   /****** Object:  Stored Procedure dbo.bspJCDeptVal    Script Date: 2/12/97 3:25:04 PM ******/
   CREATE   proc [dbo].[bspJCDeptVal]
   /*************************************
   * validates JC Department
   *	TV - 23061 added isnulls
   * Pass:
   *	JC Company and JC Department to be validated
   *
   * Success returns:
   *	0 and Group Description from bJCDM
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@JCCo bCompany = null, @dept char(10) = null, @msg varchar(60) output)
   as
   set nocount on
   	declare @rcode int
   	select @rcode = 0

   
   if @JCCo is null
   	begin
   	select @msg = 'Missing JC Company', @rcode = 1
   	goto bspexit
   	end
   
   
   if @dept is null
   	begin
   	select @msg = 'Missing JC Department', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bJCDM
     where JCCo=@JCCo and Department = @dept
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid JC Department', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCDeptVal] TO [public]
GO
