SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMLocVal    Script Date: 8/28/99 9:34:29 AM ******/
   CREATE   procedure [dbo].[bspEMLocVal]
   /*************************************
   * validates Location
   *
   *	TV 02/11/04 - 23061 added isnulls
   *
   * Pass:
   *	EMCO, Location
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@emco bCompany = null, @loc bLoc = null, @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   
   if @loc is null
   	begin
   	select @msg = 'Missing location', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bEMLM where EMCo = @emco and EMLoc = @loc
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Location', @rcode = 1
   		end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMLocVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMLocVal] TO [public]
GO
