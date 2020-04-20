SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQBatchProcessLock    Script Date: 8/28/99 9:34:49 AM ******/
CREATE procedure [dbo].[vspHQBatchInfoGet]
/**************************************************************
*  Created:		TJL 03/29/05 - As a part of 6x rewrite
*  Modified: 
*	
*	
*  Usage:
*	Though we have many HQ Batch Procedures, it appears that we have none that
*	simply return values back without making a change to HQBC.  In AR during
*	Batch Processing there was a need to Refresh information on the Batch
*	Processing Form after Validation, Posting and Clearing of the Batch. (This 
*	was being done via SQL code imbedded in VB in 5x).  This is the result of
*	moving this code from VB to Stored Procedure.  If other modules are doing 
*	this in a similar manner, this procedure could be used by these other modules
*	as well.  (For best results, call from VB using SqlHelper.ExecuteDataset)
*
*	All Values are selected so coder can pick the desired column information as
*	needed for individual forms.  (See VB frmARBatchProcessing.BatchInfoRefresh)
*
*  Inputs:
*	@co			Company
*	@mth		Batch Month
*	@batchid	Batch ID#
*	
*  DataSet Item IDs:
*	Source		0
*	TableName	1
*	InUseBy		2
*	DateCreated	3
*	CreatedBy	4
*	Status		5	(Status original integer value)
*	StatusText	6	(Status converted to text value)
*	Rstrict		7
*	Adjust		8
*	PRGroup		9
*	PREndDate	10
*	DatePosted	11
*	DateClosed	12
*
* Output:
*	@errmsg		Error message
*
* Returns
*	@rcode		0 = success, 1 = error
*
***************************************************************/
  
(@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output)
  
as
set nocount on

declare @rcode int

select @rcode = 0
  
/* Validate BatchId. Minimal validation required. More could be added if beneficial. */
select Source, TableName, InUseBy, DateCreated, CreatedBy, Status,
	case Status when 0 then 'Open' when 1 then 'Validation in Progress' when 2 then 'Errors'
		when 3 then 'Validated' when 4 then 'Update in Progress' when 5 then 'Updated'
		when 6 then 'Canceled' end, 
	Rstrict, Adjust, PRGroup, PREndDate, DatePosted, DateClosed
from bHQBC with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid BatchId #!', @rcode = 1
	goto vspexit
	end

/* This procedure is informational only.  Any Batch Locking or Unlocking has already been done
   as a result of other procedures. */

vspexit:
	--if @rcode <> 0 select @errmsg = isnull(@errmsg,'') + char(13) + char(10) + '[vspHQBatchInfoGet2]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQBatchInfoGet] TO [public]
GO
