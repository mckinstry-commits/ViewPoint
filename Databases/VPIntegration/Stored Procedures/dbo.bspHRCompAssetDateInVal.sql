SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspHRCompAssetDateInVal]
   /************************************************************************
   * CREATED:  mh 6/22/04    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Validate the check in date of an asset.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @asset varchar(20), @dateout bDate, @datein bDate, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @nextdateout bDate
   
       select @rcode = 0
   
   	--This will check the date in against the date out...same line in grid
   	if @datein < @dateout
   	begin
   		select @msg = 'Check In date: ' + convert(varchar(20),@datein) + ' conflicts with Check Out date: ' + convert(varchar(20),@dateout) /*+ ' for Asset ' + @asset*/, @rcode = 1
   		goto bspexit
   	end
   
   	--Are there records after the one we are on?  Will the new check in date clobber
   	--one of those?
   
   	select @nextdateout = min(DateOut) from dbo.HRTA with (nolock) where HRCo = @hrco and Asset = @asset and DateOut > @dateout
   
   	if @datein > @nextdateout
   	begin
   		select @msg = 'New Check In date will conflict with subsequent Check Out record.', @rcode = 1
   		goto bspexit
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCompAssetDateInVal] TO [public]
GO
