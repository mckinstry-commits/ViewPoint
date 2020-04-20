SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRTBDeleteEmployee    Script Date: 5/20/05 9:32:34 AM ******/
CREATE   proc [dbo].[vspPRTBDeleteEmployee]
/***********************************************************
* CREATED BY	: EN 3/13/06
* MODIFIED BY	: 
*
* USED IN: PREmplTimeCardDelete to delete all timecards in a batch for a specified employee.
*
* INPUT PARAMETERS
*	@co			PR company #
*	@mth		batch month
*	@batchid	batch id
*	@employee	employee to delete
*
* OUTPUT PARAMETERS
*   @msg      message whether or not entries were deleted
*
*****************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @employee bEmployee, @msg varchar(255) output)
as

set nocount on

declare @rcode int

select @rcode = 0

delete from dbo.PRTB where Co=@co and Mth=@mth and BatchId=@batchid and Employee=@employee
select @msg=convert(varchar,@@rowcount) + ' entries for employee# ' + convert(varchar,@employee) + ' have been deleted.'
if @@rowcount = 0
 	begin
 	select @msg = 'No entries were found for employee# ' + convert(varchar,@employee)
 	goto bspexit
 	end


bspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRTBDeleteEmployee] TO [public]
GO
