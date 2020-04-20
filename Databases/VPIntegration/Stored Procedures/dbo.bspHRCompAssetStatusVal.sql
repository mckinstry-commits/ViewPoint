SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRCompAssetStatusVal]
   /************************************************************************
   * CREATED:	mh 5/25/04    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Validate a change in Status.  If an item is checked out user should
   *	not be able to change a Status code     
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @asset varchar(20), @newstatus tinyint, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	--Is item checked out?  If so, cannot change Status until Asset checked in.
   	if (select max(DateOut) from dbo.HRTA with (nolock)
   		where HRCo = @hrco and Asset = @asset and DateIn is null) is not null
   	begin
   		if (select Status from dbo.HRCA with (nolock) 
   			where HRCo = @hrco and Asset = @asset) <> @newstatus
   		begin
   			select @msg = 'Asset is currently checked out, cannot change Status.', @rcode = 1
   			goto bspexit
   		end
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCompAssetStatusVal] TO [public]
GO
