SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRABPost]    Script Date: 01/12/2009 12:22:50 ******/

    CREATE                procedure [dbo].[bspPRABPost]
    /***********************************************************
     * CREATED BY: EN 1/15/98
     * MODIFIED By : EN 2/3/99
     *               EN 1/20/00 - moved bPREL update from PRLH triggers because need PRAB info to update bPREL properly when do leave reset
     *               EN 2/18/00 - modified to adjust bPREL properly; using Cap1Amt, Cap2Amt and AvailBalAmt for reset entries and Amt for all others
     *               EN 9/19/00 - added code for attachments
     *               bc 05/29/01 - included PRCo = @co to all the update statements to PREL
     *               MV 06/19/01 - Issue 12769 BatchUserMemoUpdate
     *               TV/RM 02/22/02 Attachment fix
     *               EN 4/3/02 - Issue 15788 Adjust for renamed bPRAB fields and to update adjustment amounts into adjust fields added to bPRLH.
     *              CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
     *				GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
     *				  EN 5/2/02 - issue 15775 Update bPREL fields properly for type 'R' transactions
     *				  EN 6/3/02 - issue 15788 Fixed to properly update PREL reset dates and values when delete reset trans
     *				  EN 8/5/02 - issue 17217 Changed to update reset date if adjust amount is not null rather than <>0
     *				  EN 10/7/02 - issue 18877 change double quotes to single
     *					EN 2/11/04 - issue 18616 re-index attachments
     *				EN 4/12/04 - issue 18616 fix problem with index stats not getting updated
	 *				mh 4/23/08 - Issue 127292 - Passing in @source to bspBatchUserMemoUpdate
	 *				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
	 *				mh 05/14/09 - Issue 133439/127603
     *
     * USAGE:
     * Posts a validated batch of PRAB entries
     * deletes successfully posted bPRAB rows
     *
     * INPUT PARAMETERS
     *   PRCo        PR Co
     *   Month       Month of batch
     *   BatchId     Batch ID to validate
     *   PostingDate Posting date to write out if successful
     *   Source	 'PR Leave'
     *
     * OUTPUT PARAMETERS
     *   @errmsg     if something went wrong
     * RETURN VALUE
     *   0   success
     *   1   fail
     *****************************************************/
   
    	(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null,
    	 @source bSource, @errmsg varchar(60) output)
    as
    set nocount on
    declare @rcode int, @opencursor tinyint
   
    /*Header declares*/
    declare @seq int, @transtype char(1), @trans bTrans, @employee bEmployee, @leavecode bLeaveCode,
    	@actdate bDate, @type varchar(1),
    	@amt bHrs, @description bDesc, @prgroup bGroup, @prenddate bDate, @payseq tinyint,
    	@tablename char(20), @accum1adj bHrs, @accum2adj bHrs, @availbaladj bHrs,
        @oldemployee bEmployee, @oldleavecode bLeaveCode, @oldactdate bDate,
        @oldtype varchar(1), @oldamt bHrs, @oldaccum1adj bHrs, @oldaccum2adj bHrs, @oldavailbaladj bHrs,
        @cap1freq bFreq, @cap1max bHrs, @cap2freq bFreq, @cap2max bHrs, @availbalfreq bFreq,
    	@availbalmax bHrs, @cap1date bDate, @cap2date bDate, @availbaldate bDate,
        @keyfield varchar(128), @updatekeyfield varchar(128), @deletekeyfield varchar(128),
       @guid uniqueIdentifier, @Notes varchar(256)
   
    declare @status tinyint, @lastseq int
   
   
    select @rcode = 0, @lastseq=0
   
    /* set open cursor flags to false */
    select @opencursor = 0
   
   
    /* check for date posted */
    if @dateposted is null
       begin
        select @errmsg = 'Missing posting date!', @rcode = 1
        goto bspexit
       end
   
    /* validate HQ Batch */
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'PRAB', @errmsg output, @status output
    if @rcode <> 0 goto bspexit
   
    if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
       begin
        select @errmsg = 'Invalid Batch status -  must be ''valid - OK to post'' or ''posting in progress''!', @rcode = 1
        goto bspexit
       end
   
    /* set HQ Batch status to 4 (posting in progress) */
    update bHQBC
    	set Status = 4, DatePosted = @dateposted
    	where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
       begin
        select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
        goto bspexit
       end
   
   
    /* declare cursor on PR Leave Accrual Batch for validation */
    declare bcPRAB cursor for
    select BatchSeq, BatchTransType, Trans, Employee, LeaveCode, ActDate,
       	Type, Amt, Accum1Adj, Accum2Adj, AvailBalAdj, Description, PRGroup, PREndDate, PaySeq,
           OldEmployee, OldLeaveCode, OldActDate, OldType, OldAmt, OldAccum1Adj, OldAccum2Adj, OldAvailBalAdj,
   
           UniqueAttchID
   from bPRAB where Co = @co and Mth = @mth and BatchId = @batchid
   
    /* open cursor */
   
    open bcPRAB
   
    /* set open cursor flag to true */
    select @opencursor = 1
   
    /* loop through all rows in PRAB and update their info.*/
    pr_posting_loop:
        /* get row from PRAB */
   fetch next from bcPRAB into @seq, @transtype, @trans, @employee, @leavecode, @actdate, @type, @amt, @accum1adj, @accum2adj,
                               @availbaladj, @description, @prgroup, @prenddate, @payseq, @oldemployee, @oldleavecode,
                               @oldactdate, @oldtype, @oldamt, @oldaccum1adj, @oldaccum2adj, @oldavailbaladj, @guid
   
   if @@fetch_status <> 0 goto pr_posting_end
   
        if @seq = @lastseq
           begin
              select @errmsg = 'Duplicate Sequence, error with cursor!', @rcode=1
              goto bspexit
           end
   
        select @lastseq=@seq
   
   --     /* get Employee Leave info needed to find accumulator and avail bal amounts */
   --     exec @rcode = bspPRELStatsGet @co, @employee, @leavecode,
   --      	@cap1max output, @cap2max output, @availbalmax output,
   --         @cap1freq output, @cap2freq output, @availbalfreq output,
   --         @cap1date output, @cap2date output, @availbaldate output, @errmsg output
   --     if @rcode<>0
   --     	begin
   --     	 select @errmsg = 'Error getting Employee Leave Stats.', @rcode = 1
   --     	 goto bspexit
   --     	end
   
        BEGIN TRANSACTION
   
        if @transtype = 'A'	/* add new leave history transaction */
            begin
             /* get next available transaction # for PRLH */
             select @tablename = 'bPRLH'
             exec @trans = bspHQTCNextTrans @tablename, @co, @mth, @errmsg output
             if @trans = 0
                begin
             	select @errmsg = 'Error getting next transaction #', @rcode=1
             	goto pr_posting_error
                end
   
             /* insert entry */
             insert bPRLH (PRCo, Mth, Trans, Employee, LeaveCode, ActDate, PostDate, Type, Amt,
              		 Description, PRGroup, PREndDate, PaySeq, BatchId, InUseBatchId, UniqueAttchID,
   				 Accum1Adj, Accum2Adj, AvailBalAdj)
             values (@co, @mth, @trans, @employee, @leavecode, @actdate, @dateposted, @type, @amt,
              	     @description, @prgroup, @prenddate, @payseq, @batchid, null, @guid,
   				 @accum1adj, @accum2adj, @availbaladj)
             if @@rowcount = 0 goto pr_posting_error
   
               --update Trans# in the batch record for BatchUserMemoUpdate
               update bPRAB set Trans = @trans
               where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   
             /* update bPREL */
        	  if @type = 'A'
            	begin
        		update bPREL
        		set Cap1Accum = Cap1Accum + (CASE WHEN Cap1Date is null THEN @amt WHEN @actdate > Cap1Date THEN @amt ELSE 0 END),
        		    Cap2Accum = Cap2Accum + (CASE WHEN Cap2Date is null THEN @amt WHEN @actdate > Cap2Date THEN @amt ELSE 0 END),
        		    AvailBal = AvailBal + (CASE WHEN AvailBalDate is null THEN @amt WHEN @actdate > AvailBalDate THEN @amt ELSE 0 END)
        		where PRCo = @co and Employee = @employee and LeaveCode = @leavecode
        	    end
        	  if @type = 'U'
        		update bPREL
        		set AvailBal = AvailBal - (CASE WHEN AvailBalDate is null THEN @amt WHEN @actdate > AvailBalDate THEN @amt ELSE 0 END)
        		where PRCo = @co and Employee = @employee and LeaveCode = @leavecode
        	  if @type = 'R'
               begin
   			if @accum1adj is not null or @accum2adj is not null or @availbaladj is not null --issue 17217
   	     		update bPREL
   	     		set Cap1Accum = Cap1Accum + (CASE WHEN Cap1Date is null THEN isnull(@accum1adj,0) WHEN @actdate > Cap1Date THEN isnull(@accum1adj,0) ELSE 0 END),
   	     		   Cap2Accum = Cap2Accum + (CASE WHEN Cap2Date is null THEN isnull(@accum2adj,0) WHEN @actdate > Cap2Date THEN isnull(@accum2adj,0) ELSE 0 END),
   	     		   AvailBal = AvailBal + (CASE WHEN AvailBalDate is null THEN isnull(@availbaladj,0) WHEN @actdate > AvailBalDate THEN isnull(@availbaladj,0) ELSE 0 END)
   	     		where PRCo = @co and Employee = @employee and LeaveCode = @leavecode
               if @accum1adj is not null --issue 17217
                  update bPREL set Cap1Date = @actdate where PRCo = @co and Employee = @employee and LeaveCode = @leavecode
               if @accum2adj is not null --issue 17217
                  update bPREL set Cap2Date = @actdate where PRCo = @co and Employee = @employee and LeaveCode = @leavecode
               if @availbaladj is not null --issue 17217
                  update bPREL set AvailBalDate = @actdate where PRCo = @co and Employee = @employee and LeaveCode = @leavecode
        	    end
--Issue 133439/127603   
--               update bHQAT
--               set TableName = 'PRLH' --issue 18616 4/12/04 was 'PREL'
--               where UniqueAttchID = @guid
      
             end
   
        if @transtype = 'C'	/* update existing leave history transaction */
             begin
              update bPRLH
              set  Employee=@employee, LeaveCode=@leavecode, ActDate=@actdate, Type=@type, Amt=@amt,
                   Description=@description, UniqueAttchID = @guid
              where PRCo=@co and Mth=@mth and Trans=@trans
   
              if @@rowcount = 0 goto pr_posting_error
   
              /* update bPREL */
              /* back out old amounts */
        	  if @oldtype = 'A'
                begin
        		 update bPREL
        		 set Cap1Accum = Cap1Accum - (CASE WHEN Cap1Date is null THEN @oldamt WHEN @oldactdate > Cap1Date THEN @oldamt ELSE 0 END),
        		    Cap2Accum = Cap2Accum - (CASE WHEN Cap2Date is null THEN @oldamt WHEN @oldactdate > Cap2Date THEN @oldamt ELSE 0 END),
        		    AvailBal = AvailBal - (CASE WHEN AvailBalDate is null THEN @oldamt WHEN @oldactdate > AvailBalDate THEN @oldamt ELSE 0 END)
        		 where PRCo = @co and Employee = @oldemployee and LeaveCode = @oldleavecode
        	    end
        	  if @oldtype = 'U'
        		update bPREL
        		set AvailBal = AvailBal + (CASE WHEN AvailBalDate is null THEN @oldamt WHEN @oldactdate > AvailBalDate THEN @oldamt ELSE 0 END)
        		where PRCo = @co and Employee = @oldemployee and LeaveCode = @oldleavecode
   
             /* add in new amounts */
        	  if @type = 'A'
                begin
        		 update bPREL
        		 set Cap1Accum = Cap1Accum + (CASE WHEN Cap1Date is null THEN @amt WHEN @actdate > Cap1Date THEN @amt ELSE 0 END),
        		    Cap2Accum = Cap2Accum + (CASE WHEN Cap2Date is null THEN @amt WHEN @actdate > Cap2Date THEN @amt ELSE 0 END),
        		    AvailBal = AvailBal + (CASE WHEN AvailBalDate is null THEN @amt WHEN @actdate > AvailBalDate THEN @amt ELSE 0 END)
        		 where PRCo = @co and Employee = @employee and LeaveCode = @leavecode
        	    end
        	  if @type = 'U'
        		update bPREL
        		set AvailBal = AvailBal - (CASE WHEN AvailBalDate is null THEN @amt WHEN @actdate > AvailBalDate THEN @amt ELSE 0 END)
        		where PRCo = @co and Employee = @employee and LeaveCode = @leavecode
--Issue 133439/127603   
--               update bHQAT
--               set TableName = 'PRLH' --issue 18616 4/12/04 was 'PREL'
--               where UniqueAttchID = @guid
   
             end
   
        if @transtype = 'D'	/* delete existing leave history transaction */
             begin
              delete from bPRLH where PRCo=@co and Mth=@mth and Trans=@trans
   
              if @@rowcount = 0 goto pr_posting_error
   
              /* update bPREL */
        	  if @type = 'A'
                begin
        		 update bPREL
        		 set Cap1Accum = Cap1Accum - (CASE WHEN Cap1Date is null THEN @amt WHEN @actdate > Cap1Date THEN @amt ELSE 0 END),
        		    Cap2Accum = Cap2Accum - (CASE WHEN Cap2Date is null THEN @amt WHEN @actdate > Cap2Date THEN @amt ELSE 0 END),
   
        		    AvailBal = AvailBal - (CASE WHEN AvailBalDate is null THEN @amt WHEN @actdate > AvailBalDate THEN @amt ELSE 0 END)
        		 where PRCo = @co and Employee = @employee and LeaveCode = @leavecode
                end
        	  if @type = 'U'
        		update bPREL
        		set AvailBal = AvailBal + (CASE WHEN AvailBalDate is null THEN @amt WHEN @actdate > AvailBalDate THEN @amt ELSE 0 END)
        		where PRCo = @co and Employee = @employee and LeaveCode = @leavecode
   		  --issue 15788 Reset bPREL values
        	  if @type = 'R'
               begin
   			if @accum1adj is not null or @accum2adj is not null or @availbaladj is not null --issue 17217
   	     		update bPREL
   	     		set Cap1Accum = Cap1Accum - (CASE WHEN Cap1Date is null THEN isnull(@accum1adj,0) WHEN @actdate >= Cap1Date THEN isnull(@accum1adj,0) ELSE 0 END),
   	     		   Cap2Accum = Cap2Accum - (CASE WHEN Cap2Date is null THEN isnull(@accum2adj,0) WHEN @actdate >= Cap2Date THEN isnull(@accum2adj,0) ELSE 0 END),
   	     		   AvailBal = AvailBal - (CASE WHEN AvailBalDate is null THEN isnull(@availbaladj,0) WHEN @actdate >= AvailBalDate THEN isnull(@availbaladj,0) ELSE 0 END)
   	     		where PRCo = @co and Employee = @employee and LeaveCode = @leavecode
   
   			--issue 15788 Attempt to reset the reset date(s)
               if @accum1adj is not null --issue 17217
                  update bPREL 
   			   set Cap1Date = (select max(ActDate) from bPRLH where PRCo=@co and Type='R' and Employee=@employee 
   					and LeaveCode=@leavecode and ActDate<@actdate and Accum1Adj<>0)
   			   where PRCo = @co and Employee = @employee and LeaveCode = @leavecode and Cap1Date = @actdate
               if @accum2adj is not null --issue 17217
                  update bPREL 
   			   set Cap2Date = (select max(ActDate) from bPRLH where PRCo=@co and Type='R' and Employee=@employee 
   					and LeaveCode=@leavecode and ActDate<@actdate and Accum2Adj<>0) 
   			   where PRCo = @co and Employee = @employee and LeaveCode = @leavecode and Cap2Date = @actdate
               if @availbaladj is not null --issue 17217
                  update bPREL 
   			   set AvailBalDate = (select max(ActDate) from bPRLH where PRCo=@co and Type='R' and Employee=@employee 
   					and LeaveCode=@leavecode and ActDate<@actdate and AvailBalAdj<>0) 
   		   	   where PRCo = @co and Employee = @employee and LeaveCode = @leavecode and AvailBalDate = @actdate
        	    end
--Issue 133439/127603
--              delete from bHQAT where UniqueAttchID = @guid
   
             end
   
           /* call bspBatchUserMemoUpdate to update user memos in bPRLH before deleting the batch record */
           if @transtype <> 'D'
           begin
           exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, @source/*'PR EmployeeLeave'*/, @errmsg output
           if @rcode <> 0 goto pr_posting_error
           end
   
        /* delete current row from cursor */
        delete from bPRAB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq= @seq
   
        /* commit transaction */
        COMMIT TRANSACTION
   
   	 -- issue 18616 Refresh indexes for this header if attachments exist
   	 if @guid is not null exec bspHQRefreshIndexes null, null, @guid, null
   
        goto pr_posting_loop
   
   
    pr_posting_error:		/* error occured within transaction - rollback any updates and continue */
   
    ROLLBACK TRANSACTION
    goto pr_posting_loop
   
   
    pr_posting_end:			/* no more rows to process */
   
    if @opencursor=1
       begin
        close bcPRAB
        deallocate bcPRAB
        select @opencursor=0
       end
   
    /* make sure batch is empty */
    if exists(select * from bPRAB where Co = @co and Mth = @mth and BatchId = @batchid)
       begin
        select @errmsg = 'Not all Leave Accrual entries were posted - unable to close batch!', @rcode = 1
   
        goto bspexit
       end
   
   -- set interface levels note string
       select @Notes=Notes from bHQBC
       where Co = @co and Mth = @mth and BatchId = @batchid
       if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
       select @Notes=@Notes +
           'EM Cost Employee Interface set at: ' + convert(char(1), a.EMCostEmployee) + char(13) + char(10) +
           'EM Interface set at: ' + convert(char(1), a.EMInterface) + char(13) + char(10) +
           'GL Interface set at: ' + convert(char(1), a.GLInterface) + char(13) + char(10) +
           'JC Interface set at: ' + convert(char(1), a.JCInterface) + char(13) + char(10)
       from bPRCO a where PRCo=@co
   
    /* delete HQ Close Control entries */
    delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
    /* set HQ Batch status to 5 (posted) */
    update bHQBC
    	set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
    	where Co = @co and Mth = @mth and BatchId = @batchid
    	if @@rowcount = 0
    		begin
    		select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
   
    		goto bspexit
   
    		end
   
    bspexit:
    	if @opencursor=1
       	  begin
       	   close bcPRAB
       	   deallocate bcPRAB
               select @opencursor=0
       	  end
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRABPost] TO [public]
GO
