SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBDistFlagGet    Script Date: 8/28/99 9:33:57 AM ******/
CREATE proc [dbo].[bspJBDistFlagGet]
/***********************************************************
* CREATED BY	: kb 11/26/1
* MODIFIED BY	:	TJL 01/12/06 - Issue #28182, 6x recode.  Modified to be same as ARDistFlagGet for consistency
*
* USAGE:
* called from JB Batch Process form. Send it batch source
* and based on that source it checks to see what distributions
* lists are available
*
* INPUT PARAMETERS
*   JBCo  JB Co to validate against
*   Source of batch
*   BatchId
*   BatchMth
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of PO, Vendor,
*   @flag - 0 if no in and no jc entries
*	     1st bit=gl entry
*	     2nd bit=jc entry
*	     3rd bit=in entry
*	     4th bit=em entry
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
   
(@jbco bCompany = 0, @source bSource,
	@mth bMonth=null, @batchid bBatchID=null, @flag varchar(8) output, @msg varchar(60) output )
as

set nocount on

declare @rcode int
select @rcode = 0,  @flag='00000000'

if @source='JB'
	begin
	/* Job distributions*/
	if exists(select JBCo from bJBJC where JBCo=@jbco and Mth=@mth and BatchId=@batchid) select @flag = @flag | 2
	/*GL distributions*/
	if exists(select JBCo from bJBGL where JBCo=@jbco and Mth=@mth and BatchId=@batchid) select @flag = @flag | 4
	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBDistFlagGet] TO [public]
GO
