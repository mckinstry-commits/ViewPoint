SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMBFCount]
/********************************************************
* CREATED BY: DANF 04/04/07
* USAGE:	
*
* 	Return record count of EMBF batch
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
*  Record Count
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/

(@emco bCompany, @batchid int, @batchmth bMonth, @recordcount int output, @msg varchar(60) output) 
as 
set nocount on

declare @rcode int
select @rcode = 0

if @emco is null
	begin
	select @msg = 'Missing EM Company.', @rcode = 1
	goto vspexit
	end

if @batchid is null
	begin
	select @msg = 'Missing Batch ID.', @rcode = 1
	goto vspexit
	end

if @batchmth is null
	begin
	select @msg = 'Missing Batch Month.', @rcode = 1
	goto vspexit
	end


select	@recordcount = count(*) 
from bEMBF e with (nolock)
where e.Co = @emco and e.BatchId = @batchid and e.Mth = @batchmth


vspexit:

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMBFCount] TO [public]
GO
