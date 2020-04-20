SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPRCheckEmplStatus]
/***********************************************************
* Created: GG 02/07/07
* Modified:
*
* Used by PR Check Print to see if all unpaid employees with earnings in
* a given pay period are fully processed.  Excludes employees to be paid by EFT.
*
* Input params:
*	@prco		PR company
*	@prgroup	PR Group
*	@prenddate  Period End Date
*
* Output params:
*	none
*
* Returns:
*	# of records
**************************************************************************/
	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null)

as
set nocount on

-- return # of records in bPRSP for a given PRCo, PRGroup, and PR Ending Date
select count(*) from dbo.bPRSQ s (nolock)
where s.PRCo = @prco and s.PRGroup = @prgroup and s.PREndDate = @prenddate
	and s.CMRef is null and s.PayMethod = 'C' and isnull(s.ChkType,'') <> 'M' 
	and (s.Processed = 'N' or
		exists(select top 1 1 from dbo.bPRTB b (nolock)
				join dbo.bHQBC c (nolock) on c.Co = b.Co and c.Mth = b.Mth and c.BatchId = b.BatchId
				where b.Co = @prco and b.Employee = s.Employee and b.PaySeq = s.PaySeq
					and c.PRGroup = @prgroup and c.PREndDate = @prenddate))
  
 
vspexit:
   	return

GO
GRANT EXECUTE ON  [dbo].[vspPRCheckEmplStatus] TO [public]
GO
