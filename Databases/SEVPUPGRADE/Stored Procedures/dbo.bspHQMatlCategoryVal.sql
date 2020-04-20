SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMatlCategoryVal    Script Date: 8/28/99 9:32:48 AM ******/
   CREATE  proc [dbo].[bspHQMatlCategoryVal]
   /*************************************
   * validates HQ Material Category vs HQMC.Category
   *
   * Pass:
   *	HQ MatlGroup
   *	HQ Category
   *
   * Success returns:
   *	0 and Description from bHQMC
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@matlgroup bGroup = null, @category varchar(10) = null, @msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group', @rcode = 1
   	goto bspexit
   	end
   
   if @category is null
   	begin
   	select @msg = 'Missing Material Category', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from HQMC where MatlGroup = @matlgroup and 
   	Category = @category
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Material Category', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQMatlCategoryVal] TO [public]
GO
