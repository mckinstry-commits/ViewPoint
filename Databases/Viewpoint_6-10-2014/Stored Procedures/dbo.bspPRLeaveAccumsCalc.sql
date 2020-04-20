SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRLeaveAccumsCalc    Script Date: 8/28/99 9:33:25 AM ******/
   
    CREATE procedure [dbo].[bspPRLeaveAccumsCalc]
    /***********************************************************
     * CREATED BY: EN 2/23/98
     * MODIFIED By : EN 6/17/99
     *               EN 2/17/00 - remove cap1amt, cap2amt and availbalamt from output params
     *               EN 4/23/02 - issue 15788 adjust for change to bspPRELAmtsGet which returns bucket and batch amts in separate params
     *
     * USAGE:
     * Calculate the correct amount to post
     * to bPRAB for a BatchTransType 'A' entry.
     *
     * INPUT PARAMETERS
     *   @co	Company
     *   @mth	Month
     *   @batchid	BatchId
     *   @employee	Employee number
     *   @leavecode	Leave Code
     *   @actdate	Activity date
     *   @type	(A)ccrual or (U)sage
     *   @amt	Accrual/usage amount
     *
     * OUTPUT PARAMETERS
     *   @postamt	Amount to post in PRAB
     *   @errmsg     if something went wrong
     * RETURN VALUE
     *   0   success
     *   1   fail
     *****************************************************/
   
    	(@co bCompany, @mth bMonth, @batchid bBatchID, @employee bEmployee, @leavecode bLeaveCode,
    	 @actdate bDate, @type varchar(1), @amt bHrs, @postamt bHrs output, @errmsg varchar(60) output)
    as
    set nocount on
    declare @rcode int, @curraccum1 bHrs, @curraccum2 bHrs, @curravailbal bHrs,
    	@cap1max bHrs, @cap2max bHrs, @availbalmax bHrs,
    	@cap1freq bFreq, @cap2freq bFreq, @availbalfreq bFreq,
    	@cap1date bDate, @cap2date bDate, @availbaldate bDate, @alimitreached char(1),
       @accum1 bHrs, @accum2 bHrs, @availbal bHrs
   
    select @rcode = 0
   
    /* init employee leave balance amounts */
    select @postamt=@amt, @alimitreached = 'N'
   
    /* get accumulator & available balance amounts */
    exec @rcode = bspPRELStatsGet @co, @employee, @leavecode, @cap1max output, @cap2max output,
    	@availbalmax output, @cap1freq output, @cap2freq output, @availbalfreq output,
    	@cap1date output, @cap2date output, @availbaldate output, @errmsg output
    if @rcode<>0 goto bspexit
    exec @rcode = bspPRELAmtsGet @co, @mth, @batchid, null, @employee, @leavecode,
       @cap1date, @cap2date, @availbaldate, @accum1 output, @accum2 output, @availbal output,
       @curraccum1 output, @curraccum2 output, @curravailbal output, @errmsg output
    if @rcode<>0 goto bspexit
   
    /* compute postamt */
    if @type = 'A'
    	begin
    	 if @cap1date is null or @actdate > @cap1date
    		begin
    		 if @cap1max <> 0 and @accum1 + @curraccum1 + @amt > @cap1max
               if @alimitreached = 'N' or (@alimitreached = 'Y' and @cap1max - (@accum1 + @curraccum1) < @postamt)
        		 	begin
        			 select @postamt = @cap1max - (@accum1 + @curraccum1), @alimitreached = 'Y'
        			 if @postamt < 0 select @postamt = 0
        			end
    		end
    	 if @cap2date is null or @actdate > @cap2date
   
    		begin
    		 if @cap2max <> 0 and @accum2 + @curraccum2 + @amt > @cap2max
    		 	if @alimitreached = 'N' or (@alimitreached = 'Y' and @cap2max - (@accum2 + @curraccum2) < @postamt)
    		 		begin
    				 select @postamt = @cap2max - (@accum2 + @curraccum2), @alimitreached = 'Y'
    				 if @postamt < 0 select @postamt = 0
    				end
    		end
   
   	 if @availbaldate is null or @actdate > @availbaldate
    		begin
    		 if @availbalmax <> 0 and @availbal + @curravailbal + @amt > @availbalmax
    		 	if @alimitreached = 'N' or (@alimitreached = 'Y' and @availbalmax - (@availbal + @curravailbal) < @postamt)
    		 		begin
    				 select @postamt = @availbalmax - (@availbal + @curravailbal)
    				 if @postamt < 0 select @postamt = 0
    				end
    		end
   	end
   
   
    bspexit:
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRLeaveAccumsCalc] TO [public]
GO
