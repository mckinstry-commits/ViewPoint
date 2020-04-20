SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspCMClearUpdate]
/************************************************************************
* CREATED:	mh 6/29/06    
* MODIFIED:		mh 03/17/09 - Issue 132408  
*				mh 03/15/10 - Issue 132324 - include month in update statement.
*
* Purpose of Stored Procedure
*
*    Update CMDT with Cleared Transaction Info
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@cmco bCompany, @cmacct bCMAcct, @cmtrans bTrans, @cmref bCMRef, @cmrefseq tinyint, @cleardate bDate, 
	@clearedamt bDollar, @stmtdate bDate, @mth bMonth, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @cmco is null
	begin
		select @msg = 'Missing CM Company.', @rcode = 1
		goto vspexit
	end

	if @cmacct is null
	begin
		select @msg = 'Missing CM Account.', @rcode = 1
		goto vspexit
	end

	if @cmtrans is null
	begin
		select @msg = 'Missing CM Trans.', @rcode = 1
		goto vspexit
	end

	if @cmref is null
	begin
		select @msg = 'Missing CM Reference.', @rcode = 1
		goto vspexit
	end

	if @cmrefseq is null
	begin
		select @msg = 'Missing CM Reference Seq.', @rcode = 1
		goto vspexit
	end

	--132408 - If clear date is null statement date and cleared amount must be null and zero.
	if @cleardate is null 
	begin
		select @stmtdate = null, @clearedamt = 0
	end

	Update CMDT set ClearDate = @cleardate, ClearedAmt = @clearedamt, StmtDate = @stmtdate 
	where CMCo = @cmco and CMAcct = @cmacct and CMTrans = @cmtrans and CMRef = @cmref and 
	CMRefSeq = @cmrefseq and Mth = @mth

vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspCMClearUpdate] TO [public]
GO
