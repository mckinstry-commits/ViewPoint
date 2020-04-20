SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      procedure [dbo].[bspHRCompAssetDateVal]
   /************************************************************************
   * CREATED:  mh 6/22/04    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   
   	(@hrco bCompany, @asset varchar(20), @dateout bDate, @valdate bDate, @msg varchar(100) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @datein bDate, @lastdateout bDate
   
       select @rcode = 0
   
   	--Get the last checkout record.
   	select @lastdateout = DateOut, @datein = DateIn
   	from dbo.HRTA with (nolock) where HRCo = @hrco and Asset = @asset and 
   	DateOut = (select max(DateOut) from dbo.HRTA with (nolock)
   	where HRCo = @hrco and Asset = @asset)
   
   	if @dateout is null --We are working a check out record.
   	begin
   
   		if @lastdateout is not null
   		begin
   			if @valdate < @datein
   				select @msg = 'Invalid Date:  Date Out entered is prior to last Date In.', @rcode = 1
   		end
   		else -- this is the first checkout record.  Should we validate against purchase date?
   			goto bspexit
   	end
   
   	if @dateout is not null -- We are working a check in record.
   	begin
   
   		--if @lastdateout = @valdate
   		--begin
   			if @valdate < @dateout
   			begin
   				select @msg = 'Invalid Date:  Check In date entered is prior to Check Out date.', @rcode = 1		
   				goto bspexit
   			end
   		--end
   		
   		if @lastdateout <> @valdate
   		begin
   			if @valdate > (select DateOut from dbo.HRTA with (nolock)
   				where HRCo = @hrco and Asset = @asset and 
   				DateOut = (select min(DateOut) from dbo.HRTA with (nolock)
   				where HRCo = @hrco and Asset = @asset and DateOut > @dateout))	
   			begin
   				select @msg = 'Invalid Date:  Check In date conflicts with next Check Out record.', @rcode = 1
   				goto bspexit
   			end
   		end
   
   		if (@valdate is null or @valdate = '') 
   		begin
   			 if exists(select DateOut from dbo.HRTA with (nolock)
   				where HRCo = @hrco and Asset = @asset and 
   				DateOut = (select min(DateOut) from dbo.HRTA with (nolock)
   				where HRCo = @hrco and Asset = @asset and DateOut > @dateout))
   				begin
   					select @msg = 'Invalid Date:  Check In date cannot be changed to null when subsequent Check Out record exists.', @rcode = 1
   					goto bspexit		
   				end
   		end		
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCompAssetDateVal] TO [public]
GO
