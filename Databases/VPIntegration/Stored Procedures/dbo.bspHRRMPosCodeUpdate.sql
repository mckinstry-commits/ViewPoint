SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspHRRMPosCodeUpdate]
     /************************************************************************
     * CREATED:  mh (who knows when)    
     * MODIFIED: mh 2/2/2005 -    
     *
     * Purpose of Stored Procedure
     *
     *		Update a Position Code to HRRM.  Intended for use in HRResourceSalary.    
     *    
     *           
     * Notes about Stored Procedure
     * 
     *
     * returns 0 if successfull 
     * returns 1 and error msg if failed
     *
     *************************************************************************/
     
          (@hrco bCompany, @hrref bHRRef, @poscode varchar(10) = null, @msg varchar(250) = null output)
     
     as
     set nocount on
     
         declare @rcode int
     
         select @rcode = 0
     
     if @hrco is null
     	begin
     		select @msg = 'Missing required HR Company.', @rcode = 1
     		goto bspexit
     	end
     
     if @hrref is null
     	begin
     		select @msg = 'Missing required HR Reference.', @rcode = 1
     		goto bspexit
     	end
     /*
     if @poscode is null
     	begin
     		select @msg = 'Missing required Position Code.', @rcode = 1
     		goto bspexit
     	end
     */
     	
   	if @poscode is not null
   	begin
   		if not exists(select 1 from dbo.HRPC with (nolock) where HRCo = @hrco and PositionCode = @poscode)
   		begin
   			select @msg = @poscode + ' is not set up in HR Position Codes.', @rcode = 1
   			goto bspexit
   		end
   	end
   
   
     	begin transaction
     
     	update HRRM set PositionCode = @poscode where HRCo = @hrco and HRRef = @hrref
     
     	if @@rowcount = 1
     		commit transaction
     	else
     	begin
     		rollback transaction
   
     		select @msg = 'Unable to update HR Resource Master.', @rcode = 1
     	end
     
     
     bspexit:
     
     	select @msg = @msg + char(13) + '  Position code not updated to HR Resource Master.'
          return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRRMPosCodeUpdate] TO [public]
GO
