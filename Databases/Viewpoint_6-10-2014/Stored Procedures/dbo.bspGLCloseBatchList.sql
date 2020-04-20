SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLCloseBatchList    Script Date: 8/28/99 9:34:42 AM ******/
CREATE  procedure [dbo].[bspGLCloseBatchList]
/**************************************************
* Created: ??
* Modified: GG	11/17/1999	- Cleanup
*			GG	08/01/2006	- #120609 - added nolock hints AND ORDER BY clause
*			GG	02/22/2008	- #120107 - separate subledger close
*			CHS	09/02/2011	- TK-08021 - added vSMMiscellaneousBatch
*
* Usage:
*   Called by GL Close Control form to list unprocessed batches
*   prior to closing a month.
*
* Inputs:
*   @glco       GL company
*   @mth        Month to close
*   @ledger     'General' = check for GL Close, 'Sub' = check for subledger close
*	@apclose	Check for AP batches - Y/N
*	@arclose	Check for AR batches - Y/N
*	@subclose	Check for all subledger batches - Y/N
*
* Return: set of unprocessed batches (status < 5)
**************************************************/
	(@glco bCompany = null, @mth bMonth = null, @ledger varchar(8) = null,
	 @apclose bYN = null, @arclose bYN = null, @subclose bYN = null)
as
set nocount on

if @ledger = 'General'   -- check for unposted GL batches
	BEGIN
	SELECT b.Co, b.Mth, b.BatchId, Source, CreatedBy, InUseBy, Status
	FROM dbo.bHQBC b (NOLOCK)
	JOIN dbo.bHQCC c (NOLOCK) ON c.Co = b.Co AND c.Mth = b.Mth AND c.BatchId = b.BatchId
	WHERE c.GLCo = @glco AND c.Mth <= @mth AND Status < 5 AND Source like 'GL%'
	ORDER BY b.Co, b.Mth, b.BatchId
	END
else
	BEGIN
	-- AP batches
	SELECT b.Co, b.Mth, b.BatchId, Source, CreatedBy, InUseBy, Status
	FROM dbo.bHQBC b (NOLOCK)
	JOIN dbo.bHQCC c (NOLOCK) ON c.Co = b.Co AND c.Mth = b.Mth AND c.BatchId = b.BatchId
	WHERE c.GLCo = @glco AND c.Mth <= @mth AND Status < 5
		AND (@apclose = 'Y' AND (Source like 'AP%' OR Source in ('MS MatlPay', 'MS HaulPay')))
	
	UNION
	-- AR batches
	SELECT b.Co, b.Mth, b.BatchId, Source, CreatedBy, InUseBy, Status
	FROM dbo.bHQBC b (NOLOCK)
	JOIN dbo.bHQCC c (NOLOCK) ON c.Co = b.Co AND c.Mth = b.Mth AND c.BatchId = b.BatchId
	WHERE c.GLCo = @glco AND c.Mth <= @mth AND Status < 5
		AND (@arclose = 'Y' AND (Source like 'AR%' OR Source like 'JB%' OR Source = 'MS Invoice'))
	
	UNION
	-- all other subledger batches (including AP AND AR)
	SELECT b.Co, b.Mth, b.BatchId, Source, CreatedBy, InUseBy, Status
	FROM dbo.bHQBC b (NOLOCK)
	JOIN dbo.bHQCC c (NOLOCK) ON c.Co = b.Co AND c.Mth = b.Mth AND c.BatchId = b.BatchId
	WHERE c.GLCo = @glco AND c.Mth <= @mth AND Status < 5 AND (@subclose = 'Y' AND Source not like 'GL%')
	--ORDER BY b.Co, b.Mth, b.BatchId
	
	UNION
	-- SM Work Completed batches
	SELECT bHQBC.Co, bHQBC.Mth, bHQBC.BatchId, bHQBC.Source, bHQBC.CreatedBy, bHQBC.InUseBy, bHQBC.Status
	FROM dbo.vSMMiscellaneousBatch
		INNER JOIN dbo.SMWorkCompletedAllCurrent ON vSMMiscellaneousBatch.SMWorkCompletedID = SMWorkCompletedAllCurrent.SMWorkCompletedID
		INNER JOIN dbo.bHQBC ON vSMMiscellaneousBatch.Co = bHQBC.Co AND vSMMiscellaneousBatch.Mth = bHQBC.Mth AND vSMMiscellaneousBatch.BatchId = bHQBC.BatchId
	WHERE SMWorkCompletedAllCurrent.GLCo = @glco AND bHQBC.Mth <= @mth AND bHQBC.Status < 5 AND @subclose = 'Y'
	
	ORDER BY Co, Mth, BatchId
	END
	
return
GO
GRANT EXECUTE ON  [dbo].[bspGLCloseBatchList] TO [public]
GO
