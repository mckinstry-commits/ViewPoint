SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspGLRBTotals]
/**********************************************************************
* Created: ??
* Modified: MV 01/31/03 - #20246 dbl quote cleanup.
*			GG 08/24/06 - VP6.0 re-code, added output params and nolock hints
*
* Used by GL Auto Reversal Entry to provide Batch, Journal, and GL Reference totals from bGLRB
*
* Inputs:
*   @co         	GL Co#
*   @mth        	Batch month
*   @batchid    	Batch ID#
*   @jrnl       	Journal
*   @glref      	GL Reference
*
* Ouput:
*	@batchtotal		Batch Total
*	@jrnltotal		Journal Total w/in Batch
*	@glreftotal		Reference Total w/in Batch
*
* Return code:
*   0 = success, 1 = failure
*
**********************************************************************/
	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @jrnl bJrnl = null,
	@glref bGLRef = null, @batchtotal bDollar = 0 output, @jrnltotal bDollar = 0 output,
	@glreftotal bDollar = 0 output)
   
as
set nocount on

declare @rcode int
    
select @rcode = 0
   
-- Batch total 
select @batchtotal = isnull(sum(Amount),0)
from dbo.bGLRB (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
-- Journal total
select @jrnltotal = isnull(sum(Amount),0)
from dbo.bGLRB (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid and Jrnl = @jrnl
-- Reference total   
select @glreftotal = isnull(sum(Amount),0)
from dbo.bGLRB (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid and Jrnl = @jrnl and GLRef = @glref
        
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLRBTotals] TO [public]
GO
