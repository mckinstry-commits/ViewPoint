SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRAutoLeavePosting    Script Date: 8/28/99 9:35:28 AM ******/
    CREATE          procedure [dbo].[bspPRAutoLeavePosting]
    /***********************************************************
     * CREATED BY: EN 2/21/98
     * MODIFIED By : EN 3/8/99
     *               EN 2/17/00 - when insert bPRAB, set Cap1Amt, Cap2Amt and AvailBalAmt (used to get them from bspPRLeaveAccumsCalc)
     *               EN 9/8/00 - delete entries posted to bPRAB are missing desc, PRGroup, PREndDate and PaySeq from orig bPRLH posting
     *               EN 2/12/01 - issue #10073 - translate fixed units to 0 if null
     *               EN 4/3/02 - Issue 15788 Adjust for renamed bPRAB fields
     *				 EN 4/25/02 - issue 17000  Fixed accrual amt override not working unless fixed accrual freq override is selected
     *				 EN 7/31/02 - issue 17690  restrict employee usage posting by PREL eligible date
     *				 EN 8/20/02 - issue 18231  use PRAU/PRLB Type column as a key field
     *			     EN 9/12/02 - issue 18231  add type to where clause when look up rate in PRAU/PRLB
     *				 EN 9/27/02 - issue 18638  correct eligible date comparison for fixed accruals and rate-based addon earnings
     *				 EN 9/27/02 - issue 18418  fix routine to delete previously posted rate based a/u's include ALL previously post a/u's
     *				EN 9/22/03 - issue 20159  fix to allow fixed freq override of 0 to keep leave from being accrued on selected employees
     *				EN 1/12/04 - issue 18855  include description field values when insert bPRLH
     *
     * USAGE:
     * Posts a batch of fixed accruals and/or rate based usage and accruals
     * to bPRAB.
     *
     * INPUT PARAMETERS
     *   @co	Company
     *   @mth	Month
     *   @batchid	Batch ID
     *   @updfixed	Flag indicating whether to update fixed accruals
     *   @accdate	Accrual Date
     *   @leavecode	Leave Code
     *   @freq	Frequency
     *   @delfixed	Flag indicating if previously posted fixed accruals
     *		for same leave code/date should be deleted
     *   @updratebased	Flag indicating whether to update rate based usage/accruals
     *   @prgroup	PR Group
     *   @begindate	Beginning PR ending date to check for rate based posting
     *   @enddate	Ending PR ending date to check for rate based posting
     *   @delratebased	Flag indicating if previously posted rate based accruals/usage
     *			for same PR Group within date range specified should be deleted.
     *	  @desc1	Description to use when posting fixed accruals
     *   @desc2	Description to use when posting usage and rate based accruals
     *
     * OUTPUT PARAMETERS
     *   @errmsg     if something went wrong
     * RETURN VALUE
     *   0   success
     *   1   fail
     *****************************************************/
    
    	(@co bCompany, @mth bMonth, @batchid bBatchID, @updfixed varchar(1),
    	 @accdate bDate, @leavecode bLeaveCode = null, @freq bFreq = null, @delfixed varchar(1),
    	 @updratebased varchar(1), @prgroup bGroup, @begindate bDate, @enddate bDate,
    	 @delratebased varchar(1), @desc1 bDesc, @desc2 bDesc, @errmsg varchar(60) output)
    as
    set nocount on
    declare @rcode int, @opencursor tinyint, @employee bEmployee, @fixedunits bHrs, @seq int,
    	@curraccum1 bHrs, @curraccum2 bHrs, @curravailbal bHrs, @cap1max bHrs, @cap2max bHrs,
    	@availbalmax bHrs, @cap1freq bFreq, @cap2freq bFreq, @availbalfreq bFreq,
    	@cap1date bDate, @cap2date bDate, @availbaldate bDate, @praucursor tinyint,
    	@prthcursor tinyint, @amt bHrs, @postamt bHrs, @eleavecode bLeaveCode,
    	@type varchar(1), @prenddate bDate, @basis varchar(1), @rate bUnitCost, @actdate bDate,
    	@earncode bEDLCode, @payseq tinyint, @prthhours bHrs, @prthamt bDollar,
    	@prtaamt bDollar, @lvcode bLeaveCode, @PRABadded char(1), @prlhtrans bTrans,
        @postdesc bDesc, @postprgroup bGroup, @postprenddate bDate, @postpayseq tinyint,
    	@eligibledate bDate /* issue 17690 - declare @eligibledate */
   
    select @rcode = 0, @PRABadded = 'N'
    
    /* set open cursor flags to false */
    select @opencursor = 0, @praucursor = 0, @prthcursor = 0
 
    /* process fixed accruals */
    if @updfixed = 'Y'
    	begin
    	 /* validate leave code */
    	 if @leavecode is not null
    		begin
    		 if not exists (select * from PRLV where PRCo=@co and LeaveCode=@leavecode)
   
    			begin
    			 select @errmsg = 'Invalid leave code!', @rcode = 1
    			 goto bspexit
    			end
    		end
    	 /* validate frequency */
    	 if @freq is not null
    	 	begin
    		 if not exists (select * from HQFC where Frequency=@freq)
    			begin
    			 select @errmsg = 'Invalid frequency code!', @rcode = 1
    			 goto bspexit
    			end
    		end
    
    	 /* initialize cursor to find fixed accruals for posting */
    	 declare bcPREL cursor for
    		select l.Employee, l.LeaveCode,
    			case when l.FixedUnits is null then isnull(v.FixedUnits,0) else l.FixedUnits end --issue 20159
    	 	from bPREL l
    		join bPRLV v on v.PRCo=l.PRCo and v.LeaveCode=l.LeaveCode
    	 	where l.PRCo=@co and l.LeaveCode=isnull(@leavecode,l.LeaveCode) and l.EligibleDate<=@accdate
    	 	and (l.FixedFreq=isnull(@freq,l.FixedFreq) or (l.FixedFreq is null and v.FixedFreq=isnull(@freq,v.FixedFreq)))
    	 	and exists (select * from bPREH where PRCo=@co and Employee=l.Employee and ActiveYN='Y')
    
    	 /* open cursor */
    	 open bcPREL
    
    	 /* set open cursor flag to true */
    	 select @opencursor = 1
    
    	 /* loop through cursor */
    	 fixed_accruals_loop:
    	 fetch next from bcPREL into @employee, @lvcode, @amt
    	 if @@fetch_status <> 0
    	 	goto fixed_posting_end
    
    	 BEGIN TRANSACTION
     	 /* delete previously posted fixed accruals (if any) */
     	 if @delfixed = 'Y'
     		begin
     		 if exists (select * from bPRLH where PRCo = @co and Mth = @mth and
     	 	    	Employee = @employee and LeaveCode = @lvcode and ActDate = @accdate and
     	 	    	Type = 'A')
    
    			begin
    		 	   SELECT @prlhtrans = min(Trans) from bPRLH h where PRCo = @co
    		 	   	and Mth = @mth and Employee = @employee and LeaveCode = @lvcode
    		 	   	and ActDate = @accdate and Type = 'A'
    		 	   	and not exists (select * from bPRAB where PRCo = @co
    		 	   			and Mth = @mth and Trans = h.Trans
    		 	   			and BatchTransType = 'D')
    		 	   WHILE @prlhtrans is not null
    			   BEGIN
    			     /* read transaction detail */
    			     select @postamt = Amt, @postdesc = Description from bPRLH 
   				 where PRCo = @co and Mth = @mth and Trans = @prlhtrans
    
    			     /* get next available sequence # for this batch */
    		 	     select @seq = isnull(max(BatchSeq),0)+1 from bPRAB
    				 where Co = @co and Mth = @mth and BatchId = @batchid
    
    		 	     /* add Transaction to PRAB */
    		 	     insert into bPRAB (Co, Mth, BatchId, BatchSeq, BatchTransType, Trans, Employee, LeaveCode,
    				ActDate, Type, Amt, Accum1Adj, Accum2Adj, AvailBalAdj, Description, PRGroup, PREndDate,
    				PaySeq, OldEmployee, OldLeaveCode, OldActDate, OldType, OldAmt, OldAccum1Adj, OldAccum2Adj,
    				OldAvailBalAdj, OldDesc, OldPRGroup, OldPREndDate, OldPaySeq)
    		 	     values (@co, @mth, @batchid, @seq, 'D', @prlhtrans, @employee, @lvcode, @accdate, 'A',
    				@postamt, 0, 0, 0, @postdesc, null, null, null, @employee, @lvcode, @accdate, 'A',
    				@postamt, 0, 0, 0, @postdesc, null, null, null)
    		 	     if @@rowcount <> 1
    				begin
    				select @errmsg = 'Unable to add entry to PR Leave Entry Batch!', @rcode = 1
    				goto bsperror
    				end
    		 	     else
    		 		select @PRABadded = 'Y'
    
    		 	     SELECT @prlhtrans = min(Trans) from bPRLH where PRCo = @co and
    			 	Mth = @mth and Employee = @employee and LeaveCode = @lvcode and
    			 	ActDate = @accdate and Type = 'A' and Trans > @prlhtrans
    			   END
    			end
    		end
 
    
    	 /* compute employee leave balance amounts */
    	 exec @rcode = bspPRLeaveAccumsCalc @co, @mth, @batchid, @employee, @lvcode, @accdate,
    	 	'A', @amt, @postamt output, @errmsg output
    	 if @rcode<>0 goto bsperror
    
    	 /* add accrual posting to PRAB batch */
    	 if @postamt<>0
    		begin
    	 	 /* get next available sequence # for this batch */
    		 select @seq = isnull(max(BatchSeq),0)+1 from bPRAB
    			where Co = @co and Mth = @mth and BatchId = @batchid
    
    		 /* add Transaction to PRAB */
    		 insert into bPRAB (Co, Mth, BatchId, BatchSeq, BatchTransType, Trans, Employee, LeaveCode,
    			ActDate, Type, Amt, Accum1Adj, Accum2Adj, AvailBalAdj, Description, PRGroup, PREndDate,
    			PaySeq, OldEmployee, OldLeaveCode, OldActDate, OldType, OldAmt, OldAccum1Adj, OldAccum2Adj,
    			OldAvailBalAdj, OldDesc, OldPRGroup, OldPREndDate, OldPaySeq)
    		 values (@co, @mth, @batchid, @seq, 'A', null, @employee, @lvcode, @accdate, 'A',
    			@postamt, 0, 0, 0, @desc1, null, null, null,
    			null, null, null, null, null, null, null, null, null, null, null, null)
    		 if @@rowcount <> 1
    			begin
    			select @errmsg = 'Unable to add entry to PR Leave Entry Batch!', @rcode = 1
    			goto bsperror
    			end
    		 else
    		 	select @PRABadded = 'Y'
    		end
    	 COMMIT TRANSACTION
    
    	 goto fixed_accruals_loop
    
    	 fixed_posting_end:	/* no more fixed accruals to process */
    	end
    
    /* process rate based usage/accruals */
    if @updratebased = 'Y'
    	begin
   	BEGIN TRANSACTION
   	/* delete previously posted rate based accruals (if any) */
   	if @delratebased = 'Y'
   	 	begin
   	 	 if exists (select * from bPRLH where PRCo = @co and Mth = @mth and PRGroup = @prgroup and 
   					PREndDate >= @begindate and PREndDate <= @enddate)
   			begin
   			   SELECT @prlhtrans = min(Trans) from bPRLH h where PRCo = @co and Mth = @mth and
   					PRGroup = @prgroup and PREndDate >= @begindate and PREndDate <= @enddate
    	 				and not exists (select * from bPRAB where PRCo = @co and Mth = @mth and Trans = h.Trans
    	   					and BatchTransType = 'D')
   			   WHILE @prlhtrans is not null
   				   BEGIN
   				    /* read transaction detail */
   				    select @employee=Employee, @eleavecode=LeaveCode, @postamt=Amt, @actdate=ActDate,
   						@type=Type, @postamt=Amt, @postdesc = Description, @postprgroup = PRGroup,
   	                    @postprenddate = PREndDate, @postpayseq = PaySeq
   	                from bPRLH where PRCo = @co and Mth = @mth and Trans = @prlhtrans
   	
   				    /* get next available sequence # for this batch */
   			 	    select @seq = isnull(max(BatchSeq),0)+1 from bPRAB
   					where Co = @co and Mth = @mth and BatchId = @batchid
   	
   			 	    /* add Transaction to PRAB */
   			 	    insert into bPRAB (Co, Mth, BatchId, BatchSeq, BatchTransType, Trans, Employee, LeaveCode,
   					ActDate, Type, Amt, Accum1Adj, Accum2Adj, AvailBalAdj, Description, PRGroup, PREndDate,
   					PaySeq, OldEmployee, OldLeaveCode, OldActDate, OldType, OldAmt, OldAccum1Adj, OldAccum2Adj,
   					OldAvailBalAdj, OldDesc, OldPRGroup, OldPREndDate, OldPaySeq)
   			 	    values (@co, @mth, @batchid, @seq, 'D', @prlhtrans, @employee, @eleavecode, @actdate, @type,
   					@postamt, 0, 0, 0, @postdesc, @postprgroup, @postprenddate, @postpayseq, @employee, @eleavecode,
   	             	@actdate, @type, @postamt, 0, 0, 0, @postdesc, @postprgroup, @postprenddate, @postpayseq)
   			 	    if @@rowcount <> 1
   						begin
   						select @errmsg = 'Unable to add entry to PR Leave Entry Batch!', @rcode = 1
   						goto bsperror
   						end
   			 	    else
   				 		select @PRABadded = 'Y'
   	
   			 	    SELECT @prlhtrans = min(Trans) from bPRLH where PRCo = @co and Mth = @mth and
   						PRGroup = @prgroup and PREndDate >= @begindate and PREndDate <= @enddate and 
   						Trans > @prlhtrans
   				   END
   			end
   		end
    
    	 /* validate pr group */
    	 if @prgroup is null
    		begin
    		 select @errmsg = 'Missing PR Group!', @rcode = 1
    		 goto bspexit
    		end
    	 if not exists (select * from PRGR where PRCo=@co and PRGroup=@prgroup)
    		begin
    		 select @errmsg = 'Invalid PR Group!', @rcode = 1
    		 goto bspexit
    		end
    
    	 /* initialize cursor to find rate based accruals/usage for posting */
    	 declare bcPRAU cursor for
    	 	select e.Employee, e.LeaveCode, a.EarnCode, a.Type, e.EligibleDate --issue 17690
    			from PREL e
    			join PRAU a on e.PRCo=a.PRCo and e.LeaveCode=a.LeaveCode
    			where e.PRCo=@co
    				and e.Employee in (select Employee from PREH where PRCo=@co and ActiveYN='Y')
    		union
    		select e.Employee, e.LeaveCode, l.EarnCode, l.Type, e.EligibleDate --issue 17690
    			from PREL e
    			join PRLB l on e.PRCo=l.PRCo and e.Employee=l.Employee and e.LeaveCode=l.LeaveCode
    			where e.PRCo=@co
    				and e.Employee in (select Employee from PREH where PRCo=@co and ActiveYN='Y')
   
    
    	 /* open cursor */
    	 open bcPRAU
    
    	 /* set open cursor flag to true */
    	 select @praucursor = 1
    
    	 /* loop through PRAU cursor */
    	 PRAU_loop:
    	 	fetch next from bcPRAU into @employee, @eleavecode, @earncode, @type, @eligibledate --issue 17690
    	 	if @@fetch_status <> 0
    	 		goto PRAU_loop_end
    
    	 	/* read basis, rate from PRAU or PRLB (if override) */
    	 	select @basis=Basis, @rate=Rate from PRLB
    	 		where PRCo=@co and Employee=@employee and LeaveCode=@eleavecode
    	 		and EarnCode=@earncode and Type=@type /*issue 18231*/
    	 	if @@rowcount = 0
    	 		select @basis=Basis, @rate=Rate from PRAU
    			where PRCo=@co and LeaveCode=@eleavecode and EarnCode=@earncode and Type=@type /*issue 18231*/
    
    	 	/* initialize cursor to find timecard details from which to calc accrual/usage */
    	 	declare bcPRTH cursor for
    	 		select PREndDate, PaySeq, PostDate
    				from bPRTH
    				where PRCo = @co and PRGroup = @prgroup
    				and PREndDate >= @begindate and PREndDate <= @enddate
    				and Employee = @employee and EarnCode = @earncode
    				and PostDate >= @eligibledate --issue 17690
    				and exists (select * from bPRPC c where c.PRCo = PRCo
    					and c.PRGroup = PRGroup and c.PREndDate = PREndDate
    					and c.LeaveProcess='N')
    			group by PRCo, PRGroup, PREndDate, Employee, PaySeq, PostDate
    			union
    			select PREndDate, PaySeq, PREndDate
    				from bPRTA a
    				where PRCo = @co and PRGroup = @prgroup
    				and PREndDate >= @begindate and PREndDate <= @enddate
    				and Employee = @employee and EarnCode = @earncode
    				and exists (select * from bPRPC c where c.PRCo = a.PRCo
    					and c.PRGroup = a.PRGroup and c.PREndDate = a.PREndDate
    					and c.LeaveProcess = 'N' and c.BeginDate>=@eligibledate)
    			group by PRCo, PRGroup, PREndDate, Employee, PaySeq
    
    	 	/* open cursor */
    	 	open bcPRTH
    
     		 /* set open cursor flag to true */
    	 	select @prthcursor = 1
    
    	 	/* loop through PRTH cursor */
    	 	PRTH_loop:
    	 		fetch next from bcPRTH into @prenddate, @payseq, @actdate
    	 		if @@fetch_status <> 0
    	 			goto PRTH_loop_end
    
    			/* get hours and amount */
    	 		select @prthhours = sum(Hours), @prthamt = sum(Amt)
    				from bPRTH
    				where PRCo = @co and PRGroup = @prgroup
    				and PREndDate = @prenddate and Employee = @employee
    				and PaySeq = @payseq and PostDate = @actdate
    				and EarnCode = @earncode
    			group by PRCo, PRGroup, PREndDate, Employee, PaySeq, PostDate
    
    			select @prtaamt = sum(Amt)
    				from bPRTA
    				where PRCo = @co and PRGroup = @prgroup
    				and PREndDate = @prenddate and Employee = @employee
    				and PaySeq = @payseq and EarnCode = @earncode
    			group by PRCo, PRGroup, PREndDate, Employee, PaySeq
    
    	 		/* compute amount to post */
    			select @amt = 0
    			if @basis = 'H' select @amt = @rate * isnull(@prthhours,0)
    			if @basis = 'A' select @amt = @rate * (isnull(@prthamt,0) + isnull(@prtaamt,0))
    
    	 		/* compute employee leave balance amounts */
    	 	 	exec @rcode = bspPRLeaveAccumsCalc @co, @mth, @batchid, @employee, @eleavecode, @actdate,
    	 			@type, @amt, @postamt output, @errmsg output
    	 		if @rcode<>0 goto bsperror
    
    	 		if @postamt <> 0
    	 			begin
    	 			 /* get next available sequence # for this batch */
    				 select @seq = isnull(max(BatchSeq),0)+1 from bPRAB
    					where Co = @co and Mth = @mth and BatchId = @batchid
    
    		 		 /* add Transaction to PRAB */
    		 		 insert into bPRAB (Co, Mth, BatchId, BatchSeq, BatchTransType, Trans, Employee, LeaveCode,
    					ActDate, Type, Amt, Accum1Adj, Accum2Adj, AvailBalAdj, Description, PRGroup, PREndDate,
    					PaySeq, OldEmployee, OldLeaveCode, OldActDate, OldType, OldAmt, OldAccum1Adj, OldAccum2Adj,
    					OldAvailBalAdj, OldDesc, OldPRGroup, OldPREndDate, OldPaySeq)
    				 values (@co, @mth, @batchid, @seq, 'A', null, @employee, @eleavecode, @actdate, @type,
    					@postamt, 0, 0, 0, @desc2, @prgroup, @prenddate, @payseq,
    					null, null, null, null, null, null, null, null, null, null, null, null)
    				 if @@rowcount <> 1
    					begin
    					 select @errmsg = 'Unable to add entry to PR Leave Entry Batch!', @rcode = 1
    					 goto bsperror
    					end
    		 		 else
    		 			select @PRABadded = 'Y'
    				end
    
    	 		goto PRTH_loop
    
    	 	PRTH_loop_end:
   
    	  	close bcPRTH
    	  	deallocate bcPRTH
    	  	select @prthcursor=0
    
    	 	goto PRAU_loop
    
    	 PRAU_loop_end:		/* no more rate based accruals/usage to process */
    	 COMMIT TRANSACTION
    
    	 /* flag periods as having been processed */
    	 update bPRPC
    	 set LeaveProcess='Y'
    	 where PRCo=@co and PRGroup=@prgroup and PREndDate>=@begindate and PREndDate<=@enddate
    	end
    	goto bspexit
    
    bsperror:
    
    	rollback transaction
    
    bspexit:
    	if @opencursor=1
    	  begin
    	   close bcPREL
    	   deallocate bcPREL
    	   select @opencursor=0
    	  end
    	if @praucursor=1
    	  begin
    	   close bcPRAU
    	   deallocate bcPRAU
    
    	   select @praucursor=0
    	  end
    	if @prthcursor=1
    	  begin
    	   close bcPRTH
    	   deallocate bcPRTH
    	   select @prthcursor=0
    	  end
    
    	if @rcode=0 and @PRABadded = 'N' select @errmsg = 'Nothing to update.', @rcode = 5
    
    
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAutoLeavePosting] TO [public]
GO
