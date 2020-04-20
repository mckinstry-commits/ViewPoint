SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspCMCalculateWorkingBalance]
	/******************************************************
	* CREATED BY:	mh 04/17/2008 
	* MODIFIED By:  mh 11/18/2008 - Issue 131030.
	*				MV 07/10/2012 - D-05240/TK-16248 new CMAcct with no prior statement dates 
	*
	* Usage:	Calculates working balance upon change to Statement beginning balance.
	*	
	*
	* Input params:
	*
	*		@cmco - CMCompany
	*		@cmacct - CMAcct
	*		@stmtdate - Statement Date
	*		@begbal - Beginning balance
	*
	* Output params:
	*
	*	@workbal - New working balance.
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
	@cmco bCompany, @cmacct bCMAcct, @stmtdate bDate, @begbal bDollar, 
	@workbal bDollar output, @msg varchar(100) output

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	declare @adjust bDollar, @check bDollar, @deposit bDollar, @transfer bDollar, @eft bDollar,
	@laststmtdate bDate

	select @adjust = 0, @check = 0, @deposit = 0, @transfer = 0, @eft = 0, @workbal = 0

	select @laststmtdate = max(s.StmtDate)
	from bCMST s (nolock) where s.CMCo = @cmco and s.CMAcct = @cmacct and s.StmtDate < @stmtdate
	--D-05240/TK-16248 if no prior statement date for new CMAcct then create a last statement date
	IF ISNULL(@laststmtdate,Space(1)) = ''
	BEGIN
		SELECT @laststmtdate = DATEADD(dd,-1,@stmtdate)
	END

	select @adjust = isnull(sum(ClearedAmt),0)
	from bCMDT c (nolock)
	Where c.CMCo = @cmco and c.CMAcct = @cmacct and c.InUseBatchId is null 
	and (c.StmtDate is null or c.StmtDate > @laststmtdate)
	and c.CMTransType = 0  --adjustments

	select @check = (isnull(sum(ClearedAmt),0) * -1)
	from bCMDT c (nolock) 
	Where c.CMCo = @cmco and c.CMAcct = @cmacct and c.InUseBatchId is null 
	and (c.StmtDate is null or c.StmtDate > @laststmtdate)
	and c.CMTransType = 1  --Check

	select @deposit = isnull(sum(ClearedAmt),0)
	from bCMDT c (nolock) 
	Where c.CMCo = @cmco and c.CMAcct = @cmacct and c.InUseBatchId is null 
	and (c.StmtDate is null or c.StmtDate > @laststmtdate)
	and c.CMTransType = 2  --Deposit

	select @transfer = isnull(sum(ClearedAmt),0)
	from bCMDT c (nolock) 
	Where c.CMCo = @cmco and c.CMAcct = @cmacct and c.InUseBatchId is null 
	and (c.StmtDate is null or c.StmtDate > @laststmtdate)
	and c.CMTransType = 3  --Transfer

	select @eft = (isnull(sum(ClearedAmt),0) * -1)
	from bCMDT c (nolock) 
	Where c.CMCo = @cmco and c.CMAcct = @cmacct and c.InUseBatchId is null 
	and (c.StmtDate is null or c.StmtDate > @laststmtdate)
	and c.CMTransType = 4  --EFT
	
	select @workbal = (@begbal - (@check + @eft) + @deposit + @transfer + @adjust)
	 
	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspCMCalculateWorkingBalance] TO [public]
GO
