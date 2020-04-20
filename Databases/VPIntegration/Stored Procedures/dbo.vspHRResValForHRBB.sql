SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRResValForHRBB]
/************************************************************************
* CREATED:    
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

    (@hrco bCompany = null, @mth bMonth, @batchid bBatchID, @hrref varchar(15),  
	 @refout int output, @msg varchar(75) output)

as
set nocount on

    declare @rcode int, @position varchar(10) 

    select @rcode = 0

	exec @rcode = bspHRResVal @hrco, @hrref, @refout output, @position output, @msg output

	if @rcode = 0
	begin
		If (select count(Co) from HRBB where Co = @hrco and Mth = @mth and BatchId = @batchid and HRRef = @hrref) = 0
		begin
			select @msg = 'HR Resource # does not exist in this batch.', @rcode = 1
			goto vspexit
		end
	end

vspexit:

    return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRResValForHRBB] TO [public]
GO
