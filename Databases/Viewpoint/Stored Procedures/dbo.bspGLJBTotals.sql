SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspGLJBTotals]
/**********************************************************************
* Created: ??
* Modified: MV 01/31/03 - #20246 dbl quote cleanup.
*			GG 08/18/06 - VP6.0 re-code, added output params and nolock hints
*			GG 03/28/08 - #30071 - interco auto journal entries, exclude memo accounts from totals
*
* Used by GL Auto Journal Entry to provide Batch, Journal, and GL Reference totals from bGLJB
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
select @batchtotal = isnull(sum(j.Amount),0)
from dbo.bGLJB j (nolock)
join dbo.bGLAC a (nolock) on j.InterCo = a.GLCo and j.GLAcct = a.GLAcct	-- use InterCo
where j.Co = @co and j.Mth = @mth and j.BatchId = @batchid and a.AcctType <> 'M'   -- exclude Memo accounts

-- Journal total
select @jrnltotal = isnull(sum(j.Amount),0)
from dbo.bGLJB j (nolock)
join dbo.bGLAC a (nolock) on j.InterCo = a.GLCo and j.GLAcct = a.GLAcct	-- use InterCo
where j.Co = @co and j.Mth = @mth and j.BatchId = @batchid
	and j.Jrnl = @jrnl and a.AcctType <> 'M'   -- exclude Memo accounts

-- Reference total   
select @glreftotal = isnull(sum(j.Amount),0)
from dbo.bGLJB j (nolock)
join dbo.bGLAC a (nolock) on j.InterCo = a.GLCo and j.GLAcct = a.GLAcct	-- use InterCo
where j.Co = @co and j.Mth = @mth and j.BatchId = @batchid
	and j.Jrnl = @jrnl and j.GLRef = @glref and a.AcctType <> 'M'   -- exclude Memo accounts
        
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLJBTotals] TO [public]
GO
