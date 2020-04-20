SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspGLDBTotals]
/**********************************************************************
* Created: ??
* Modified: GG 05/18/01 - exclude entries posted to Memo accounts from totals (#13186)
*			GG 12/05/02 - #19372 - modify join with bGLAC to use InterCo
*			GC 11/16/04 - #25584 - modify GLDB query statements into single query to improve
*								   performance of the stored procedure
*			GG 02/27/06 - VP6.0 recode, corrected query, added output params, and nolock hints
*
* Used by GL Journal Entry to provide Batch, Journal, and GL Reference totals from bGLDB
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
	@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @jrnl bJrnl = null,
	@glref bGLRef = null, @batchtotal bDollar = 0 output, @jrnltotal bDollar = 0 output,
	@glreftotal bDollar = 0 output
    
as
set nocount on
    
declare @rcode int
    
select @rcode = 0

-- Batch total
 select @batchtotal = isnull(sum(isnull(-1 * d.OldAmount,0)
                          + isnull(case d.BatchTransType when 'D' then 0 else d.Amount end,0)),0)
 from bGLDB d (nolock)
 join bGLAC a (nolock) on d.InterCo = a.GLCo and d.GLAcct = a.GLAcct	-- use InterCo
 where d.Co = @co and d.Mth = @mth and d.BatchId = @batchid and a.AcctType <> 'M'   -- exclude Memo accounts
 
 -- Journal total
 select @jrnltotal = isnull(sum(isnull(-1 * d.OldAmount,0)
                          + isnull(case d.BatchTransType when 'D' then 0 else d.Amount end,0)),0)
 from bGLDB d (nolock)
 join bGLAC a (nolock) on d.InterCo = a.GLCo and d.GLAcct = a.GLAcct	-- use InterCo
 where d.Co = @co and d.Mth = @mth and d.BatchId = @batchid and d.Jrnl = @jrnl
 	and a.AcctType <> 'M'   -- exclude Memo accounts
 
 -- GL Reference total
 select @glreftotal = isnull(sum(isnull(-1 * d.OldAmount,0)
                          + isnull(case d.BatchTransType when 'D' then 0 else d.Amount end,0)),0)
 from bGLDB d (nolock)
 join bGLAC a (nolock) on d.InterCo = a.GLCo and d.GLAcct = a.GLAcct	-- use InterCo
 where d.Co = @co and d.Mth = @mth and d.BatchId = @batchid and d.Jrnl = @jrnl and d.GLRef = @glref
 	and a.AcctType <> 'M'   -- exclude Memo accounts
  
bspexit:
    return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLDBTotals] TO [public]
GO
