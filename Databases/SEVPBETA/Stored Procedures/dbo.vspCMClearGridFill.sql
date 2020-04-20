SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspCMClearGridFill]
/************************************************************************
* CREATED:	mh    
* MODIFIED: 05/12/2008 - Issue 128276   
*			05/16/2008 - Issue 128315
*			09/02/2008 - Issue 129636
*			11/03/2008 - Issue 130888
*			02/20/2008 - Issue 129778 - Need to pass in cleared and outstanding flags
*			to restrict dataset.  Doing this in the form dataview was causing unexpected
*			consequences.
*			02/25/2009 - Issue 132408 - Added @displaythru parameter.
*			03/26/2009 - Issue 132589 - Addded parameters for CM Trans Types.  Rewrote to 
*			generate dynamic sql statements to get the correct CM Trans Types.
*			07/10/09 - Issue 134311 - Corrected @wherein statement
*
* Purpose of Stored Procedure
*
*    Query to get list of items to populate CMClear
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@cmco bCompany, @cmacct bCMAcct, @stmtdate bDate, @displaythru bDate, @cleared bYN, 
	@outstanding bYN, @checks bYN, @deposits bYN, @adjust bYN, @trans bYN, @msg varchar(80) = '' output)


as
set nocount on

    declare @rcode int, @laststmt bDate, @lastdate bDate, @sql varchar(8000), @wherein varchar(8000)

    select @rcode = 0

	
	if isdate(@stmtdate) = 0
	begin
		select @msg = 'Statement date value is not a valid date.', @rcode = 1
		--goto vspexit
	end

	select @lastdate = max(StmtDate) from CMST (nolock) 
	where CMCo = @cmco and CMAcct = @cmacct and [Status] = 1

	--These are the transaction types to be pulled in
	select @wherein = '('

	if @adjust = 'Y'
	begin
		select @wherein = @wherein + '0,'
	end

	if @checks = 'Y'
	begin
		select @wherein = @wherein + '1,4,'
	end

	if @deposits = 'Y'
	begin
		select @wherein = @wherein + '2,'
	end
	
	if @trans = 'Y'
	begin
		select @wherein = @wherein + '3,'
	end

	--Issue 134311
	if len(@wherein) > 1
	begin
		select @wherein = ''' and CMDT.CMTransType in ' + substring(@wherein, 1, len(@wherein) - 1) + ')'
	end
	else
	begin
		select @wherein = ''' and CMDT.CMTransType in ' + @wherein + substring(@wherein, 1, len(@wherein) - 1) + '99)'
	end

	/*Add join to PRVP.  Will prevent users from clearing items that are voided in PRVP. */

--Viewing Cleared and Outstanding

	if @cleared = 'Y' and @outstanding = 'Y' 
	begin
--		Select CMDT.CMTrans, CMDT.CMTransType, CMDT.CMRef, CMDT.CMRefSeq, 
--		Case when CMDT.CMTransType in (1,4) then Amount * -1 else Amount end as [Amount], 
--		CMDT.ActDate as [ActDate], CMDT.Description, CMDT.Void, Case when CMDT.StmtDate is null then 0 else 1 end as [Cleared], 
--		CMDT.ClearDate, CMDT.Mth, 
--		Case when CMTransType in (1,4) then ClearedAmt * -1 else ClearedAmt end as [ClearedAmtVis], 
--		CMDT.ClearedAmt, CMDT.StmtDate, case when PRVP.PaidDate is null then 'N' else 'Y' end as [PRVoidChk], 
--		CMDT.Amount as [DBAmt], case when CMDT.StmtDate is not null then (case when CMDT.Void = 'Y' then 0 else CMDT.Amount end) else 0 end as [WorkBalAmt]
--		from CMDT (nolock)
--		left Join PRVP (nolock) on PRVP.CMCo = CMDT.CMCo and PRVP.CMRef = CMDT.CMRef and PRVP.CMRefSeq = CMDT.CMRefSeq
--		and PRVP.CMAcct=CMDT.CMAcct  /*Issue 130888 Add join on CMAcct*/
--		Where CMDT.CMCo = @cmco and CMDT.CMAcct = @cmacct and CMDT.InUseBatchId is null 
--		and (CMDT.StmtDate is null or CMDT.StmtDate > isnull(@lastdate,'01/01/1900')) and ActDate <= @displaythru
--		and CMDT.CMTransType in (1,4)

		select @sql = 'Select CMDT.CMTrans, CMDT.CMTransType, CMDT.CMRef, CMDT.CMRefSeq, 
		Case when CMDT.CMTransType in (1,4) then Amount * -1 else Amount end as [Amount], 
		CMDT.ActDate as [ActDate], CMDT.Description, CMDT.Void, Case when CMDT.StmtDate is null then 0 else 1 end as [Cleared], 
		CMDT.ClearDate, CMDT.Mth, Case when CMTransType in (1,4) then ClearedAmt * -1 else ClearedAmt end as [ClearedAmtVis], 
		CMDT.ClearedAmt, CMDT.StmtDate, case when PRVP.PaidDate is null then ''N'' else ''Y'' end as [PRVoidChk], 
		CMDT.Amount as [DBAmt], case when CMDT.StmtDate is not null then (case when CMDT.Void = ''Y'' 
		then 0 else CMDT.Amount end) else 0 end as [WorkBalAmt]
		from CMDT (nolock)
		left Join PRVP (nolock) on PRVP.CMCo = CMDT.CMCo and PRVP.CMRef = CMDT.CMRef and PRVP.CMRefSeq = CMDT.CMRefSeq
		and PRVP.CMAcct=CMDT.CMAcct Where CMDT.CMCo = ' + convert(varchar, @cmco) + 'and CMDT.CMAcct = ' + convert(varchar,@cmacct) + ' and CMDT.InUseBatchId is null 
		and (CMDT.StmtDate is null or CMDT.StmtDate > ''' + convert(varchar, isnull(@lastdate, '01/01/1900')) + 
		''') and ActDate <= ''' + 
		convert(varchar,@displaythru) + @wherein

	end

--Viewing Outstanding only
	if @cleared = 'N' and @outstanding = 'Y'
	begin
--		Select CMDT.CMTrans, CMDT.CMTransType, CMDT.CMRef, CMDT.CMRefSeq, 
--		Case when CMDT.CMTransType in (1,4) then Amount * -1 else Amount end as [Amount], 
--		CMDT.ActDate as [ActDate], CMDT.Description, CMDT.Void, Case when CMDT.StmtDate is null then 0 else 1 end as [Cleared], 
--		CMDT.ClearDate, CMDT.Mth, 
--		Case when CMTransType in (1,4) then ClearedAmt * -1 else ClearedAmt end as [ClearedAmtVis], 
--		CMDT.ClearedAmt, CMDT.StmtDate, case when PRVP.PaidDate is null then 'N' else 'Y' end as [PRVoidChk], 
--		CMDT.Amount as [DBAmt], case when CMDT.StmtDate is not null then (case when CMDT.Void = 'Y' then 0 else CMDT.Amount end) else 0 end as [WorkBalAmt]
--		from CMDT (nolock)
--		left Join PRVP (nolock) on PRVP.CMCo = CMDT.CMCo and PRVP.CMRef = CMDT.CMRef and PRVP.CMRefSeq = CMDT.CMRefSeq
--		and PRVP.CMAcct=CMDT.CMAcct  /*Issue 130888 Add join on CMAcct*/
--		Where CMDT.CMCo = @cmco and CMDT.CMAcct = @cmacct and CMDT.InUseBatchId is null 
--		and (CMDT.StmtDate is null) and ActDate <= @displaythru

		select @sql = 'Select CMDT.CMTrans, CMDT.CMTransType, CMDT.CMRef, CMDT.CMRefSeq, 
		Case when CMDT.CMTransType in (1,4) then Amount * -1 else Amount end as [Amount], 
		CMDT.ActDate as [ActDate], CMDT.Description, CMDT.Void, Case when CMDT.StmtDate is null then 0 else 1 end as [Cleared], 
		CMDT.ClearDate, CMDT.Mth, 
		Case when CMTransType in (1,4) then ClearedAmt * -1 else ClearedAmt end as [ClearedAmtVis], 
		CMDT.ClearedAmt, CMDT.StmtDate, case when PRVP.PaidDate is null then ''N'' else ''Y'' end as [PRVoidChk], 
		CMDT.Amount as [DBAmt], case when CMDT.StmtDate is not null then (case when CMDT.Void = ''Y'' then 0 else CMDT.Amount end) else 0 end as [WorkBalAmt]
		from CMDT (nolock)
		left Join PRVP (nolock) on PRVP.CMCo = CMDT.CMCo and PRVP.CMRef = CMDT.CMRef and PRVP.CMRefSeq = CMDT.CMRefSeq
		and PRVP.CMAcct=CMDT.CMAcct  /*Issue 130888 Add join on CMAcct*/
		Where CMDT.CMCo = ' + convert(varchar,@cmco) + ' and CMDT.CMAcct = ' + convert(varchar,@cmacct) + ' and CMDT.InUseBatchId is null 
		and (CMDT.StmtDate is null) and ActDate <= ''' + convert(varchar,@displaythru) + @wherein
	end


--Viewing Cleared only
	if @cleared = 'Y' and @outstanding = 'N'
	begin
--		Select CMDT.CMTrans, CMDT.CMTransType, CMDT.CMRef, CMDT.CMRefSeq, 
--		Case when CMDT.CMTransType in (1,4) then Amount * -1 else Amount end as [Amount], 
--		CMDT.ActDate as [ActDate], CMDT.Description, CMDT.Void, Case when CMDT.StmtDate is null then 0 else 1 end as [Cleared], 
--		CMDT.ClearDate, CMDT.Mth, 
--		Case when CMTransType in (1,4) then ClearedAmt * -1 else ClearedAmt end as [ClearedAmtVis], 
--		CMDT.ClearedAmt, CMDT.StmtDate, case when PRVP.PaidDate is null then 'N' else 'Y' end as [PRVoidChk], 
--		CMDT.Amount as [DBAmt], case when CMDT.StmtDate is not null then (case when CMDT.Void = 'Y' then 0 else CMDT.Amount end) else 0 end as [WorkBalAmt]
--		from CMDT (nolock)
--		left Join PRVP (nolock) on PRVP.CMCo = CMDT.CMCo and PRVP.CMRef = CMDT.CMRef and PRVP.CMRefSeq = CMDT.CMRefSeq
--		and PRVP.CMAcct=CMDT.CMAcct  /*Issue 130888 Add join on CMAcct*/
--		Where CMDT.CMCo = @cmco and CMDT.CMAcct = @cmacct and CMDT.InUseBatchId is null 
--		and (CMDT.StmtDate = @stmtdate) and ActDate <= @displaythru

		select @sql = 'Select CMDT.CMTrans, CMDT.CMTransType, CMDT.CMRef, CMDT.CMRefSeq, 
		Case when CMDT.CMTransType in (1,4) then Amount * -1 else Amount end as [Amount], 
		CMDT.ActDate as [ActDate], CMDT.Description, CMDT.Void, Case when CMDT.StmtDate is null then 0 else 1 end as [Cleared], 
		CMDT.ClearDate, CMDT.Mth, 
		Case when CMTransType in (1,4) then ClearedAmt * -1 else ClearedAmt end as [ClearedAmtVis], 
		CMDT.ClearedAmt, CMDT.StmtDate, case when PRVP.PaidDate is null then ''N'' else ''Y'' end as [PRVoidChk], 
		CMDT.Amount as [DBAmt], case when CMDT.StmtDate is not null then (case when CMDT.Void = ''Y'' then 0 else CMDT.Amount end) else 0 end as [WorkBalAmt]
		from CMDT (nolock)
		left Join PRVP (nolock) on PRVP.CMCo = CMDT.CMCo and PRVP.CMRef = CMDT.CMRef and PRVP.CMRefSeq = CMDT.CMRefSeq
		and PRVP.CMAcct=CMDT.CMAcct  /*Issue 130888 Add join on CMAcct*/
		Where CMDT.CMCo = ' + convert(varchar,@cmco) + ' and CMDT.CMAcct = ' + convert(varchar, @cmacct) + ' and CMDT.InUseBatchId is null 
		and (CMDT.StmtDate = ''' + convert(varchar, @stmtdate) + ''') and ActDate <= ''' + convert(varchar,@displaythru) + @wherein
	end

--neither Cleared or Outstanding
	if @cleared = 'N' and @outstanding = 'N'
	begin
--		Select CMDT.CMTrans, CMDT.CMTransType, CMDT.CMRef, CMDT.CMRefSeq, 
--		Case when CMDT.CMTransType in (1,4) then Amount * -1 else Amount end as [Amount], 
--		CMDT.ActDate as [ActDate], CMDT.Description, CMDT.Void, Case when CMDT.StmtDate is null then 0 else 1 end as [Cleared], 
--		CMDT.ClearDate, CMDT.Mth, 
--		Case when CMTransType in (1,4) then ClearedAmt * -1 else ClearedAmt end as [ClearedAmtVis], 
--		CMDT.ClearedAmt, CMDT.StmtDate, case when PRVP.PaidDate is null then 'N' else 'Y' end as [PRVoidChk], 
--		CMDT.Amount as [DBAmt], case when CMDT.StmtDate is not null then (case when CMDT.Void = 'Y' then 0 else CMDT.Amount end) else 0 end as [WorkBalAmt]
--		from CMDT (nolock)
--		left Join PRVP (nolock) on PRVP.CMCo = CMDT.CMCo and PRVP.CMRef = CMDT.CMRef and PRVP.CMRefSeq = CMDT.CMRefSeq
--		and PRVP.CMAcct=CMDT.CMAcct  /*Issue 130888 Add join on CMAcct*/
--		Where CMDT.CMCo = @cmco and CMDT.CMAcct = @cmacct and CMDT.InUseBatchId is null 
--		and 1=3

		select @sql = 'Select CMDT.CMTrans, CMDT.CMTransType, CMDT.CMRef, CMDT.CMRefSeq, 
		Case when CMDT.CMTransType in (1,4) then Amount * -1 else Amount end as [Amount], 
		CMDT.ActDate as [ActDate], CMDT.Description, CMDT.Void, Case when CMDT.StmtDate is null then 0 else 1 end as [Cleared], 
		CMDT.ClearDate, CMDT.Mth, 
		Case when CMTransType in (1,4) then ClearedAmt * -1 else ClearedAmt end as [ClearedAmtVis], 
		CMDT.ClearedAmt, CMDT.StmtDate, case when PRVP.PaidDate is null then ''N'' else ''Y'' end as [PRVoidChk], 
		CMDT.Amount as [DBAmt], case when CMDT.StmtDate is not null then (case when CMDT.Void = ''Y'' then 0 else CMDT.Amount end) else 0 end as [WorkBalAmt]
		from CMDT (nolock)
		left Join PRVP (nolock) on PRVP.CMCo = CMDT.CMCo and PRVP.CMRef = CMDT.CMRef and PRVP.CMRefSeq = CMDT.CMRefSeq
		and PRVP.CMAcct=CMDT.CMAcct  /*Issue 130888 Add join on CMAcct*/
		Where 1 = 3 ' --CMDT.CMCo = @cmco and CMDT.CMAcct = @cmacct and CMDT.InUseBatchId is null 
		--and 1=3'
	end

	execute (@sql)

vspexit:

     return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspCMClearGridFill] TO [public]
GO
