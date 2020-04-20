SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      procedure [dbo].[bspHRCompAssetDateOutVal]
   /************************************************************************
   * CREATED:	mh 6/22/04    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Validate the checkout date of an asset.    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @asset varchar(20), @dateout bDate, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @lastdatein bDate, @lastdateout bDate
   
       select @rcode = 0
   
   	select @lastdatein = DateIn, @lastdateout = DateOut from dbo.HRTA with (nolock) where HRCo = @hrco and Asset = @asset 
   	and DateOut = (select max(DateOut) from dbo.HRTA with (nolock) where HRCo = @hrco and Asset = @asset and DateIn is not null)

   	if @dateout < @lastdatein
   	begin
   		if @dateout <> @lastdateout
   		begin
   			select @msg = 'Check out date conflicts with prior check in record.' /* for Asset ' + @asset*/, @rcode = 1
   			goto bspexit
   		end
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCompAssetDateOutVal] TO [public]
GO
