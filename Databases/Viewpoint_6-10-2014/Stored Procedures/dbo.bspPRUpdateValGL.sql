SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspPRUpdateValGL]
/***********************************************************
 * Created: GG 07/01/98
 * Modified: GG 03/19/99
 *		    GH 05/28/99 Don't error out when paidmonth is blank, if paymethod = 'X'.
 *          GG 07/12/99 Additional fixes for 'No-Pay'
 *          GG 08/16/99 Added GL distributions for EM
 *          GG 09/13/99 Fixed return value from bspPRUpdateValGLUsage
 *          GG 09/23/99 Fix for null burden rates in EMCO
 *          GG 10/14/99 Remove Equip Category as parameter passed to bspPRUpdateValGLUsage
 *          GG 05/08/00 Make total earns and dedns check w/o regard to PayPd status
 *          GG 06/01/00 Check for unprocessed override liabs
 *          GG 02/01/01 Paid month required if PayMethod = X - No Pay #12097
 *          GG 02/06/01 Added validation for checks and voids (#9886,#11356),
 *                      proc too large, moved GL expense processing to bspPRUpdateValGLExp
 *          EN 4/27/01 - issue #11553 - enhancement to interface hours to GL memo acccounts
 *          EN 7/18/01 - issue #14014
 *			 GG 02/16/02 - #15712 - credit net pay in CM GL Co#, add interco entries
 *			EN 10/9/02 - issue 18877 change double quotes to single
 *			EN 12/09/03 - issue 23061  added isnull check, with (nolock), and dbo
 *			EN 2/6/04 - issue 22936  check for existence of fiscal year in GL
 *			GG 03/02/06 - #120248 - correct fiscal year validation to eliminate resultset
 *			GG 11/14/06 - #123034 - JC Fixed Rate Template
 *			EN/MV 9/18/2012 B-10153/TK-17826 added code to include potential payback/payback update amounts when getting total dedns
 *
 * Called from main bspPRUpdateVal procedure to validate and load
 * GL distributions into bPRGL prior to a Pay Period update.
 *
 * Errors are written to bPRUR unless fatal.
 *
 * Inputs:
 *   @prco   		PR Company
 *   @prgroup  	PR Group to validate
 *   @prenddate	Pay Period Ending Date
 *   @beginmth		Pay Period Beginning Month
 *   @endmth		Pay Period Ending Month
 *   @cutoffdate	Pay Period Cutoff Date
 *   @status       Pay Period status - 0 = open, 1 = closed
 *
 * Output:
 *   @errmsg      error message if error occurs
 *
 * Return Value:
 *   0         success
 *   1         failure
 *****************************************************/
     (@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @beginmth bMonth = null,
      @endmth bMonth = null, @cutoffdate bDate = null, @status tinyint = null, @PRLedgerUpdateDistributionID bigint, @errmsg varchar(255) = null output)
    as
   
    set nocount on

DECLARE @DebugFlag bit
SET @DebugFlag=0
     
   declare @openEmplSeq tinyint, @openVoid tinyint, @prglco bCompany, @jrnl bJrnl, @lastmthprsubclsd bMonth,
   	@lastmthprglclsd bMonth, @maxprglopen tinyint, @glaccrualacct bGLAcct, @employee bEmployee, @payseq tinyint,
       @cmco bCompany, @cmacct bCMAcct, @paymethod char(1), @cmref bCMRef, @cmrefseq tinyint, @paidmth bMonth,
       @totalearns bDollar, @totaldedns bDollar, @processed bYN, @dtearns bDollar, @dtdedns bDollar, @empjcrate bUnitCost,
       @emrate bUnitCost, @glacct bGLAcct, @glamt bDollar, @rcode int, @errortext varchar(255), @nopaymth bMonth,
       @xmth bMonth, @xtrans bTrans, @payee varchar(20), @stmtdate bDate, @sourceco bCompany, @cminterface bYN,
       @glhrs bHrs, @cmglco bCompany, @lastmthsubclsd bMonth, @lastmthglclsd bMonth, @maxopen tinyint, 
   	@intercoARGLAcct bGLAcct, @intercoAPGLAcct bGLAcct
   
   select @rcode = 0, @glhrs = 0
   
    -- get GL Interface options from the PR Company
    select @prglco = GLCo, @jrnl = Jrnl
    from dbo.bPRCO with (nolock) where PRCo = @prco
    if @@rowcount = 0
        begin
        select @errmsg = 'Missing PR Company!', @rcode = 1
        goto bspexit
        end
    -- get PR GL Company info
    select @lastmthprsubclsd = LastMthSubClsd, @lastmthprglclsd = LastMthGLClsd, @maxprglopen = MaxOpen
    from dbo.bGLCO with (nolock) where GLCo = @prglco
    if @@rowcount = 0
        begin
        select @errmsg = 'Missing GL Company ' + convert(varchar(4),@prglco), @rcode = 1
        goto bspexit
        end
    -- validate Journal
    if not exists(select 1 from dbo.bGLJR with (nolock) where GLCo = @prglco and Jrnl = @jrnl)
        begin
        select @errmsg = 'Invalid Journal ' + @jrnl, @rcode = 1
        goto bspexit
        end
    -- get Payroll Accrual GL Account from PR Group
    select @glaccrualacct = GLAcct
    from dbo.bPRGR with (nolock) where PRCo = @prco and PRGroup = @prgroup
    if @@rowcount = 0
        begin
        select @errmsg = 'Missing PR Group ' + convert(varchar(4),@prgroup), @rcode = 1
        goto bspexit
        end
    -- validate Accrual GL Account - subledger type must be null
    exec @rcode = bspGLACfPostable @prglco, @glaccrualacct, 'N', @errortext output
    if @rcode = 1
        begin
        select @errmsg = 'Invalid PR Group GL Accrual Account.', @rcode = 1
        goto bspexit
        end
    -- set default Paid Month from Pay Pd Control - used for 'No-Pay' - should not be needed after issue #12097
    select @nopaymth = @endmth
    if @nopaymth is null select @nopaymth = @beginmth
    if @nopaymth is null
        begin
        select @errmsg = 'Missing default Paid Month from Pay Period Control.', @rcode = 1
        goto bspexit
        end
	
    -- remove entries from bPRGL interface table where 'old' values equal 0.00
    delete dbo.bPRGL
    where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and OldAmt = 0
    and OldHours = 0 --issue #14014
    -- reset 'current' values on remaining entries
    update dbo.bPRGL set Amt = 0, Hours = 0 --issue #14014
    where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate

	INSERT dbo.vSMDetailTransaction (IsReversing, Posted, PRLedgerUpdateDistributionID, HQDetailID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, SourceCo, Mth, PRMth, GLCo, GLAccount, Amount)
	SELECT 1 IsReversing, 0 Posted, @PRLedgerUpdateDistributionID, HQDetailID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, 2 LineType/*2 for labor*/, 'C' TransactionType/*C for cost*/, @prco, PRMth, PRMth, GLCo, GLAccount, -SUM(Amount)
	FROM
	(
		SELECT vSMDetailTransaction.*
		FROM dbo.vPRLedgerUpdateMonth
			INNER JOIN dbo.vSMWorkCompleted ON vPRLedgerUpdateMonth.PRLedgerUpdateMonthID = vSMWorkCompleted.PRLedgerUpdateMonthID
			INNER JOIN dbo.vSMDetailTransaction ON vSMWorkCompleted.SMWorkCompletedID = vSMDetailTransaction.SMWorkCompletedID
		WHERE vPRLedgerUpdateMonth.PRCo = @prco AND vPRLedgerUpdateMonth.PRGroup = @prgroup AND vPRLedgerUpdateMonth.PREndDate = @prenddate AND
			--Include all WIP transactions and PR transactions that were posted. Exclude the PR transactions that weren't posted to mirror the fact that the values are only copied to the old values when the GL Interface is turned on.
			vSMDetailTransaction.TransactionType = 'C' AND vSMDetailTransaction.LineType = 2 AND vSMDetailTransaction.Posted = 1 AND vSMDetailTransaction.BatchId IS NOT NULL
	) ReversingDetail
	GROUP BY HQDetailID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, PRMth, GLCo, GLAccount
	HAVING SUM(Amount) <> 0
	
    -- create cursor to process all Employee Pay Seqs within Pay Period
    declare bcEmplSeq cursor for
    select Employee, PaySeq, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, PaidMth, Earnings, Dedns, Processed, CMInterface
    from dbo.bPRSQ with (nolock)
    where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   
    open bcEmplSeq
    select @openEmplSeq = 1
   
    -- loop through all Employee Sequences
    next_EmplSeq:
       	fetch next from bcEmplSeq into @employee, @payseq, @cmco, @cmacct, @paymethod, @cmref,
            @cmrefseq, @paidmth, @totalearns, @totaldedns, @processed, @cminterface
   
        if @@fetch_status = -1 goto end_EmplSeq
        if @@fetch_status <> 0 goto next_EmplSeq
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1: Employee='+Convert(varchar,@employee)+' PaySeq='+CONVERT(varchar,@payseq)+' CMCo='+CONVERT(varchar,@cmco)+' CMAcct='+CONVERT(varchar,@cmacct)
   
        if @processed = 'N'
            begin
            if @status = 1  -- Pay Pd is closed, everyone should be full processed
                begin
                select @errortext = 'Employee/Pay Seq must be reprocessed. '
                exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
           	    if @rcode = 1 goto bspexit
                end
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1a: Skipping employee: '+@errortext
            goto next_EmplSeq	-- skip this Employee/PaySeq
            end
   
        -- use default Paid Month if No-Pay and Paid Mth is missing - should not be needed after issue #12097
        if @paymethod = 'X' and @paidmth is null select @paidmth = @nopaymth
   
        if @paidmth is null
            begin
            if @status = 1  -- Pay Pd is closed, everyone should be paid
                begin
                select @errortext = 'Missing Paid Month. '
                exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
           	    if @rcode = 1 goto bspexit
                end
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1b: Skipping employee: Paid mth is null. '+@errortext
            goto next_EmplSeq	-- skip this Employee/PaySeq
           	end
   
        -- check for unprocessed override liabs - indicates liab has no basis and has not been distributed
        if exists(select 1 from dbo.bPRDT with (nolock) where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                    and Employee = @employee and PaySeq = @payseq and EDLType = 'L' and UseOver = 'Y' and OverProcess = 'N')
            begin
            if @status = 1  -- Pay Pd is closed, all liab overrides should be processed
                begin
                select @errortext = 'Employee has unprocessed liabilities.  Check for overridden amounts with 0.00 basis.'
                exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
           	    if @rcode = 1 goto bspexit
                end
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1c: Skipping employee: '+@errortext
            goto next_EmplSeq	-- skip this Employee/PaySeq
            end
   
        -- even if paid and processed, if Pay Pd is open we must compare calculated total in bPRDT with
        -- paid totals in bPRSQ - get total earnings and deductions from bPRDT
        select @dtearns = isnull(sum(Amount),0)     -- earnings
        from dbo.bPRDT with (nolock)
        where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
            and PaySeq = @payseq and EDLType = 'E'
   
        SELECT @dtdedns = ISNULL(SUM(CASE UseOver WHEN 'Y' THEN OverAmt ELSE Amount END),0) +    -- deductions
						  ISNULL(SUM(CASE PaybackOverYN WHEN 'Y' THEN PaybackOverAmt ELSE PaybackAmt END),0)
        FROM dbo.bPRDT WITH (NOLOCK)
        WHERE PRCo = @prco AND 
			   PRGroup = @prgroup AND 
			   PREndDate = @prenddate AND 
			   Employee = @employee AND 
			   PaySeq = @payseq AND 
			   EDLType = 'D'
   
        -- make sure paid amts in bPRSQ match totals in bPRDT
        if @totalearns <> @dtearns or @totaldedns <> @dtdedns
            begin
            select @errortext = 'Employee/Pay Seq''s calculated and paid amounts don''t match. '
            exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
           if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1d: Skipping employee: '+@errortext
      		goto next_EmplSeq	-- skip this Employee/PaySeq
            end
   
        -- validate paid month
        if @paidmth <> @beginmth and (@paidmth <> @endmth  or @endmth is null)
            begin
            select @errortext = 'Paid month ' + substring(convert(varchar(8),@paidmth,3),4,5) + ' must equal Pay Period''s Beginning or Ending Month!'
            exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
            if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1e: Skipping employee: '+@errortext
            goto next_EmplSeq	-- skip this Employee/PaySeq
            end
        if (@paidmth <= @lastmthprglclsd) or (@paidmth > dateadd(month, @maxprglopen, @lastmthprsubclsd))
            begin
       		select @errortext = 'Paid month ' + substring(convert(varchar(8),@paidmth,3),4,5) + ' is not an open month in GL Co# ' + convert(varchar(4),@prglco)
            exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
           	if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1f: Skipping employee: '+@errortext
            goto next_EmplSeq	-- skip this Employee/PaySeq
           	end
   
   	 -- issue 22936  validate Fiscal Year - #120248 remove resultset
   	 if not exists(select * from dbo.bGLFY with (nolock)
   	 			where GLCo = @prglco and @paidmth >= BeginMth and @paidmth <= FYEMO)
   	 	 begin
   	 	 select @errortext = 'Missing Fiscal Year for month ' + substring(convert(varchar(8),@paidmth,3),4,5) + ' to GL Co# ' + convert(varchar(4),@prglco)
   		 exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
   		 if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1g: Skipping employee: '+@errortext
   	 	 goto next_EmplSeq
   	 	 end
   
        -- validate CM Reference and Seq
        if @paymethod <> 'X'
            begin
            if @cmref is null or @cmrefseq is null
                begin
                select @errortext = 'Missing CM Reference and/or Reference Seq#'
                exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
           	    if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1h: Skipping employee: '+@errortext
                goto next_EmplSeq	-- skip this Employee/PaySeq
           	    end
            -- checks should not exist in CM Detail
            if @paymethod = 'C' and @cminterface = 'N'
                begin
                select @xmth = Mth, @xtrans = CMTrans from dbo.bCMDT with (nolock) where CMCo = @cmco and CMAcct = @cmacct
                        and CMTransType = 1 and CMRef = @cmref and CMRefSeq = @cmrefseq
                if @@rowcount <> 0
                    begin
                    select @errortext = 'CM Reference and Reference Seq# already exists in CM Detail -  Mth: '
                        + convert(varchar(3),@xmth,1) + substring(convert(varchar(8),@xmth,1),7,2)
                        + ' Trans#:' + convert(varchar(6),@xtrans)
                    exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
           	        if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1i: Skipping employee: '+@errortext
                    goto next_EmplSeq	-- skip this Employee/PaySeq
           	        end
                end
            -- if EFT exists, should not be cleared
            if @paymethod = 'E' and @cminterface = 'N'
                begin
                select @stmtdate = StmtDate
                from dbo.bCMDT with (nolock)
                where CMCo = @cmco and CMAcct = @cmacct and CMTransType = 4 and CMRef = @cmref
                if @@rowcount <> 0 and @stmtdate is not null
                    begin
                    select @errortext = 'EFT# ' + @cmref + ' has been cleared on statement dated ' + convert(varchar(8),@stmtdate,1)
                        + ' cannot be voided.'
                    exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
           	        if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1j: Skipping employee: '+@errortext
                    goto next_EmplSeq
                    end
                end
            end
   
   	-- get Employee Header info
       select @empjcrate = JCFixedRate, @emrate = EMFixedRate
       from dbo.bPREH with (nolock)
       where PRCo = @prco and Employee = @employee
       if @@rowcount = 0
   		begin
           select @errortext = 'Missing Header record for Employee#. '
           exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
           if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1k: Skipping employee: '+@errortext
           goto next_EmplSeq	-- skip this Employee
           end
   
       if @totalearns - @totaldedns = 0 goto process_DLCredits     -- don't add Net Pay entry if 0
   
        -- Net Pay Credit based on CM Account
        select @cmglco = GLCo, @glacct = GLAcct
        from dbo.bCMAC with (nolock) where CMCo = @cmco and CMAcct = @cmacct
        if @@rowcount = 0
            begin
            select @errortext = 'CM Account ' + convert(varchar(6),@cmacct) + ' is not on file!'
            exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
     		if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1l: Skipping employee: '+@errortext
            goto next_EmplSeq	-- skip this Employee/PaySeq
            end
        -- validate GL Account - subledger type must be 'C' or null - #15712 - validate in CM GL Co#
        exec @rcode = bspGLACfPostable @cmglco, @glacct, 'C', @errmsg output
        if @rcode = 1
            begin
            select @errortext = 'Net Pay Credit based on CM Acct ' + convert(varchar(6),@cmacct) + ': ' + isnull(@errmsg,'')
            exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
            if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1m: Skipping employee: '+@errortext
            goto next_EmplSeq
            end
        -- add GL distribution for Net Pay Credit - CM GL Co#, Paid month
        select @glamt = -(@totalearns - @totaldedns)
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL G1: GLCo='+Convert(varchar,@cmglco)+' GLAcct='+@glacct+' GLAmt='+convert(varchar,@glamt)+' GLHrs='+convert(varchar,@glhrs)
        exec bspPRGLInsert @prco, @prgroup, @prenddate, @paidmth, @cmglco, @glacct, @employee, @payseq, @glamt, @glhrs
   
   	-- check for intercompany distributions
   	if @cmglco <> @prglco
           begin
           -- validate CM GL Company and Month 
           select @lastmthsubclsd = LastMthSubClsd, @lastmthglclsd = LastMthGLClsd, @maxopen = MaxOpen
           from dbo.bGLCO with (nolock) where GLCo = @cmglco
           if @@rowcount = 0
               begin
               select @errortext = 'Invalid CM GL Company #' + convert(varchar(4),@cmglco)
      			exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
          		if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1n: Skipping employee: '+@errortext
               goto next_EmplSeq
          		end
           if @paidmth <= @lastmthglclsd or @paidmth > dateadd(month, @maxopen, @lastmthsubclsd)
               begin
      		    select @errortext = substring(convert(varchar(8),@paidmth,3),4,5) + ' is not an open Month in GL Co# ' + convert(varchar(4),@cmglco)
      		    exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
      		    if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1o: Skipping employee: '+@errortext
               goto next_EmplSeq
               end
   		-- issue 22936  validate Fiscal Year - #120248 remove resultset
   		if not exists(select * from dbo.bGLFY with (nolock)
   					where GLCo = @cmglco and @paidmth >= BeginMth and @paidmth <= FYEMO)
   			begin
   		 	select @errortext = 'Missing Fiscal Year for month ' + substring(convert(varchar(8),@paidmth,3),4,5) + ' to GL Co# ' + convert(varchar(4),@cmglco)
       		exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
       		if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1p: Skipping employee: '+@errortext
   		 	goto next_EmplSeq
   		 	end
           -- get Intercompany GL Accounts
           select @intercoARGLAcct = ARGLAcct, @intercoAPGLAcct = APGLAcct
           from dbo.bGLIA with (nolock) where ARGLCo = @cmglco and APGLCo = @prglco
           if @@rowcount = 0
               begin
               select @errortext = 'Missing Intercompany GL Accounts entry for GL Co#s ' + convert(varchar(4),@prglco)
                   + ' and ' + convert(varchar(4),@cmglco)
               exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
      		    if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1q: Skipping employee: '+@errortext
               goto next_EmplSeq
               end
           -- validate Interco AR GL Account
           exec @rcode = bspGLACfPostable @cmglco, @intercoARGLAcct, 'N', @errmsg output
           if @rcode = 1
               begin
               select @errortext = 'Intercompany AR GL Account: ' + isnull(@errmsg,'')
               exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
          	    if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1r: Skipping employee: '+@errortext
               goto next_EmplSeq
               end
           -- validate Interco AP GL Account
           exec @rcode = bspGLACfPostable @prglco, @intercoAPGLAcct, 'N', @errmsg output
           if @rcode = 1
               begin
               select @errortext = 'Intercompany AP GL Account: ' + isnull(@errmsg,'')
               exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
          	    if @rcode = 1 goto bspexit
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL 1s: Skipping employee: '+@errortext
               goto next_EmplSeq
               end
   		 -- add intercompany AR debit in CM GL Co# 
   		select @glamt = @totalearns - @totaldedns	-- net pay
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL G2: GLCo='+Convert(varchar,@cmglco)+' GLAcct='+@intercoARGLAcct+' GLAmt='+convert(varchar,@glamt)
   		exec bspPRGLInsert @prco, @prgroup, @prenddate, @paidmth, @cmglco, @intercoARGLAcct, @employee, @payseq, @glamt, 0
   		-- add intercompany AP credit in PR GL Co# 
   		select @glamt = -(@totalearns - @totaldedns)
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL G3: GLCo='+Convert(varchar,@prglco)+' GLAcct='+@intercoAPGLAcct+' GLAmt='+convert(varchar,@glamt)+' GLHrs='+convert(varchar,0)
        	exec bspPRGLInsert @prco, @prgroup, @prenddate, @paidmth, @prglco, @intercoAPGLAcct, @employee, @payseq, @glamt, 0
           end
   
   
        process_DLCredits:  -- add GL dists for Dedn/Liab Credits - PR GL Co#, Paid month
            exec @rcode = bspPRUpdateValGLCredits @prco, @prgroup, @prenddate, @employee, @payseq, @prglco, @paidmth, @errmsg output
            if @rcode = 1 goto bspexit
   
        -- process Timecards, Addons, and Liabs to create expense distributions
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGL G5: PRCo='+Convert(varchar,@prco)
        exec @rcode = bspPRUpdateValGLExp @prco, @prgroup, @prenddate, @employee, @payseq, @paidmth, @beginmth, @endmth,
            @cutoffdate, @prglco, @glaccrualacct, @empjcrate, @emrate, @PRLedgerUpdateDistributionID, @errmsg output
        if @rcode = 1 goto bspexit
   
        goto next_EmplSeq   -- get next Employee/Pay Seq#
   
    end_EmplSeq:    -- finished with all Employees
        close bcEmplSeq
        deallocate bcEmplSeq
        select @openEmplSeq = 0
   
    -- make sure debits and credits balance within GL Co# and Month
    if exists(select * from dbo.bPRGL g with (nolock) join dbo.bGLAC a with (nolock) on a.GLCo = g.GLCo and a.GLAcct = g.GLAcct
                where g.PRCo = @prco and g.PRGroup = @prgroup and g.PREndDate = @prenddate
                and a.AcctType <> 'M'
                group by g.Mth, g.GLCo having sum(isnull(g.Amt,0))<>0)
        begin
        select @errortext = 'Total GL Debits and Credits do not balance!'
        exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, 0, 0, 0, @errortext, @errmsg output
        end
   
    -- create cursor to validate voids in bPRVP
    declare bcVoid cursor for
    select CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, Employee, PaySeq
    from dbo.bPRVP with (nolock)
    where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   
    open bcVoid
    select @openVoid = 1
   
    -- loop through all Voids
    next_Void:
        fetch next from bcVoid into @cmco, @cmacct, @paymethod, @cmref, @cmrefseq, @employee, @payseq
   
        if @@fetch_status = -1 goto end_Void
        if @@fetch_status <> 0 goto next_Void
   
        if @paymethod = 'C' -- if check exists in CM, make sure it has not been cleared or posted to another Employee
            begin
            select @stmtdate = StmtDate, @payee = Payee, @sourceco = SourceCo
            from dbo.bCMDT with (nolock)
            where CMCo = @cmco and CMAcct = @cmacct and CMTransType = 1 and CMRef = @cmref and CMRefSeq = @cmrefseq
            if @@rowcount <> 0
                begin
                if @stmtdate is not null
                    begin
                    select @errortext = 'Check# ' + @cmref + ' has been cleared on statement dated ' + convert(varchar(8),@stmtdate,1)
                        + '.  Cannot clear or void.'
                    exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
           	        if @rcode = 1 goto bspexit
                    goto next_Void
                    end
                else
                    begin
                    if @sourceco <> @prco or @payee <> convert(varchar(20),@employee)
                        begin
                        select @errortext = 'Check# ' + @cmref + ' originally posted to Employee ' + isnull(@payee,'') + '.  Cannot clear or void.'
                        exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
           	            if @rcode = 1 goto bspexit
                        goto next_Void
                        end
                    end
                end
            end
        if @paymethod = 'E' -- if EFT exists in CM, make sure it as not been cleared
            begin
            select @stmtdate = StmtDate
            from dbo.bCMDT with (nolock)
            where CMCo = @cmco and CMAcct = @cmacct and CMTransType = 4 and CMRef = @cmref
            if @@rowcount <> 0
                begin
                if @stmtdate is not null
                    begin
                    select @errortext = 'EFT# ' + @cmref + ' has been cleared on statement dated ' + convert(varchar(8),@stmtdate,1)
                        + ' cannot be voided.'
                    exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
           	        if @rcode = 1 goto bspexit
                    goto next_Void
                    end
                end
            end
   
        goto next_Void
   
    end_Void:   -- finished with Voids
        close bcVoid
        deallocate bcVoid
        select @openVoid = 0
   
    bspexit:
        if @openEmplSeq = 1
            begin
            close bcEmplSeq
            deallocate bcEmplSeq
            end
        if @openVoid = 1
            begin
            close bcVoid
            deallocate bcVoid
            end
   
           --select @errmsg = @errmsg + char(13) + char(10) + 'bspPRUpdateValGL'
       	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUpdateValGL] TO [public]
GO
