SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPORSCount    Script Date: 8/28/99 9:36:29 AM ******/
CREATE              procedure [dbo].[vspPORSCount]
/************************************************************************
* Created: DarrenC 01/12/06 
* Modified by: 
*
* Checks batch and returns the count of records from PORS
* 
*
* Inputs:
*   @co             PO Company
*   @mth            Batch month
*   @batchid        Batch ID
*   @source         Source - 'PO RecInit'
*   @count		total number of records in PORS
*
* returns # of records in PORS
************************************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID,
@source bSource, @count int output, @errmsg varchar(255) output)
   
	as
	set nocount on
	
	Declare @rcode int, @rows int,@Notes varchar(256)
	
	select @rcode = 0
	select @count = 0
	
	if @source <> 'PO InitRec' 
	begin 
		select @rcode = 1, @errmsg = ' Invalid source. ' 
	  	goto bspexit
	end
	
	-- count records in PORS
 	SELECT @count = isnull(count(0),0)
	FROM PORS with (nolock) 
	WHERE Co= @co and Mth = @mth and BatchId=@batchid


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPORSCount] TO [public]
GO
