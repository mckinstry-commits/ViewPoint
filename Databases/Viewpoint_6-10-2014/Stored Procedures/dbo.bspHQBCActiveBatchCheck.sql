SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspHQBCActiveBatchCheck]
/*****************************************************************
* Created by EN 2/24/98
* Modified by EN 2/24/98
*   
* Check for open batches for a select Company and Source.
*
* Input Params:
*	@co        	Company
*   @source  	Batch Source
*   
* Return Code:
*	0	Batches found
*   1	No batches meet the criteria
*        
******************************************************************/ 
	(@co bCompany, @source bSource)
   
as
declare @rcode int
set nocount on

select @rcode = 0

/* check for missing params */
if @co is null or @source is null
	begin
	select @rcode = 1
	goto bspexit
	end

/* check for any open batch for this company and source */
if not exists(select top 1 1 from dbo.bHQBC (nolock)
			where Co = @co and Source = @source and InUseBy is null and Status = 0)
 	begin
	select @rcode = 1
	goto bspexit
	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQBCActiveBatchCheck] TO [public]
GO
