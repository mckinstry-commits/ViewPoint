SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspGLJBInitialize]
/************************************************************************
* CREATED: ??
* MODIFIED: 04/22/99 GG     (SQL 7.0)
*			MV 01/31/03 - #20246 dbl quote cleanup.
*			DC  7/08/03  - 21384  Does not allow out of balance entry to Memo Accounts
*			MV 08/01/03 - #22015 5.8 beta critical - fix quotes on 'Frequency'
*			DC 11/26/03 - 23061 - Check for ISNull when concatenating fields to create descriptions
*			GG 12/29/03 - #23245 - use actual amounts when posted to 'total', use table variable for totals
*			ES 03/18/04 - #24058 - Do not initialize if account is inactive.
*			DANF 03/15/05 - #27294 - Remove scrollable cursor.
*			GG 09/15/06 - #27644 - added return message
*			GG 03/28/08 - #30071 - interco journal entries
*			GP 04/22/09 - #131863 - Remove 'not null' from @totals table variable.
*			TRL 02/10/10 -#138145 Add to fix rounding issue
*			MH 03/11/11 - #142446 - Correction to issue 138145
*			EN 8/11/2011  TK-07615 #144401 Removed references to InterCo from the WITH statement used to make rounding error adjustments
*
* Used by the GL Auto Journal Entry program to initialize entries into a GLJB batch.
*
* Checks batch info in bHQBC,
* Adds entry to next available Seq# in bGLJB
*
* pass in Co, Mth, BatchId, Journal, Actual Date, and optionally a Frequency list.
* If you pass in null for Frequency list then it will initialize all Frequencies.
*
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
(@glco bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
    	@jrnl bJrnl = null, @actdate bDate = null, @glfreqlist varchar(250) = null,
    	 @errmsg varchar(255) = null output)
   as
   set nocount on
   
   declare @cursoropen tinyint, @rcode int, @source bSource, @tablename char(20), @inuseby bVPUserName,
   	@status tinyint, @fyemo bMonth, @beginmth bMonth, @alloctype tinyint, @sourcetype char(1),
   	@sourceacct bGLAcct, @sourcetotal tinyint, @sourcebasis char(1), @percent bPct, @ratiotype1 char(1),
   	@ratioacct1 bGLAcct, @ratiototal1 tinyint, @ratiobasis1 char(1), @ratiotype2 char(1),
   	@ratioacct2 bGLAcct, @ratiototal2 tinyint, @ratiobasis2 char(1), @amount bDollar, @drcr char(1),
   	@posttotype char(1), @posttoglacct bGLAcct, @posttototal tinyint, @glref bGLRef, @transdesc bTransDesc,
   	@amt bDollar, @sourceamt bDollar, @beginbal bDollar, @ratioamt1 bDollar, @ratioamt2 bDollar, @batchseq int,
   	@entryid smallint, @seq tinyint, @cnt int, @posttoglco bCompany, @xcompjrnlyn bYN
   
declare @totals table (TotalNo int null, TotalAmt float null)  -- #23245 use table variable in place of temp table

/*initialize return code and open cursor flag */ 
select @rcode = 0, @cursoropen = 0, @cnt = 0
   
--  validate HQ Batch
exec @rcode = bspHQBatchProcessVal @glco, @mth, @batchid, 'GL Auto', 'GLJB', @errmsg output, @status output
if @rcode <> 0 goto bspexit
if @status <> 0 
begin
   select @errmsg = 'Invalid Batch status - must be ''open''!', @rcode = 1
   goto bspexit
end
       
-- get Interco Jrnl Posting option
select @xcompjrnlyn = XCompJrnlEntryYN from dbo.GLCO (nolock) where GLCo = @glco
if @@rowcount = 0
begin
   	select @errmsg = 'Invalid GL Company#!', @rcode = 1
   	goto bspexit
end

/* get beginning month for current fiscal year */
select @fyemo = min(FYEMO) from dbo.GLFY with(nolock) where GLCo = @glco and FYEMO >= @mth
if @fyemo is null
begin
   	select @errmsg = 'Missing Fiscal Year!', @rcode = 1
   	goto bspexit
end
   
select @beginmth = BeginMth from dbo.GLFY with(nolock) where GLCo = @glco and FYEMO = @fyemo
   
if @beginmth > @mth
begin
   	select @errmsg = 'This month not within a valid Fiscal Year!', @rcode = 1
   	goto bspexit
end
   
if @glfreqlist is null
	begin
		/* Create cursor on bGLAJ based on journal, last mth to post, all frequencies */
    		declare GLJB_insert cursor for select EntryId, Seq, AllocType, SourceType, SourceAcct,
   		SourceTotal, SourceBasis, Pct, RatioType1, RatioAcct1, RatioTotal1,
   		RatioBasis1, RatioType2, RatioAcct2, RatioTotal2, RatioBasis2, Amount,
   		DrCr, PostToType, PostToGLAcct, PostToTotal, GLRef, TransDesc, PostToGLCo
   		from dbo.GLAJ with(nolock)
   		where GLCo = @glco and @jrnl = Jrnl and (LastMthToPost >= @mth or LastMthToPost is null)
   		order by GLCo, Jrnl, EntryId, Seq
   	end
   else
      begin
      	/* Create cursor on bGLAJ based on journal, last mth to post, and frequency list */
   		declare GLJB_insert cursor local fast_forward for select EntryId, Seq, AllocType, SourceType, SourceAcct,
   		SourceTotal, SourceBasis, Pct, RatioType1, RatioAcct1, RatioTotal1,
   		RatioBasis1, RatioType2, RatioAcct2, RatioTotal2, RatioBasis2, Amount,
   		DrCr, PostToType, PostToGLAcct, PostToTotal, GLRef, TransDesc, PostToGLCo
   		from dbo.GLAJ with(nolock)
   		where GLCo = @glco and @jrnl = Jrnl and (LastMthToPost >= @mth or LastMthToPost is null)
                  	and charindex('''' + rtrim(Frequency) + '''',@glfreqlist) <> 0
                 	--and charindex('' + rtrim(Frequency) + '',@glfreqlist) <> 0
   		order by GLCo, Jrnl, EntryId, Seq
      end
   
   open GLJB_insert
   select @cursoropen = 1
   
   /* create temporary table to store totals */
   --create table #totals (TotalNo int, TotalAmt float)	-- converted to table variable #23245
   --if @@error <> 0
   --	begin
   --	select @errmsg = 'Unable to create temporary work table!', @rcode = 1
   --	goto bspexit
   --	end
   
   /* process Auto Journal entries */
   process_loop:
   	fetch next from GLJB_insert into @entryid, @seq, @alloctype, @sourcetype, @sourceacct,
   		@sourcetotal, @sourcebasis, @percent, @ratiotype1, @ratioacct1, @ratiototal1,
   		@ratiobasis1, @ratiotype2, @ratioacct2, @ratiototal2, @ratiobasis2, @amount,
   		@drcr, @posttotype, @posttoglacct, @posttototal, @glref, @transdesc, @posttoglco
   
   	--/Issue 138145 if @@fetch_status <> 0 goto bspexit
   	if @@fetch_status <> 0 goto RoundingCheck 
   
   	select @amt = 0, @sourceamt = 0, @ratioamt1 = 0, @ratioamt2 = 0
   
   	/* calculate source amount for Allocation types 1 and 2 */
     if @alloctype in (1,2)
   	begin
   		if @sourcetype = 'A'	/* source is GL Account */
   		begin
   			if @sourcebasis = 'M'	/* based on month-to-date activity */
   			begin
   				select @sourceamt = NetActivity from dbo.GLBL with(nolock) where GLCo = @glco and GLAcct = @sourceacct and Mth = @mth
   			end
   			if @sourcebasis = 'Y'	/* based on year-to-date balance */
   			begin
   				select @beginbal = 0
   
   				select @beginbal = BeginBal from dbo.GLYB with(nolock) 
   				where GLCo = @glco and FYEMO = @fyemo and GLAcct = @sourceacct 
   				
   				select @amt = isnull(sum(NetActivity),0) from dbo.GLBL with(nolock) 
   				where GLCo = @glco and GLAcct = @sourceacct and Mth >= @beginmth and Mth <= @mth
   				
   				select @sourceamt = @beginbal + @amt
   			end
   		end
   		if @sourcetype = 'T'	/* source is Total */
   		begin
   			select @sourceamt = TotalAmt from @totals where TotalNo = @sourcetotal
   		end
   
   	end
   
   	/* apply Percent if Allocation type 1 */
   	if @alloctype = 1
   	begin
   		select @amt = @sourceamt * @percent
   	end
   
   	/* calculate ratio is Allocation type 2 */
   	if @alloctype = 2
   	begin
   		/* calculate  ratio 1 */
   		if @ratiotype1 = 'A'	/* ratio type 1 source is GL Account */
   		begin
   			if @ratiobasis1 = 'M'	/* based on month-to-date activity */
    			begin
   				select @ratioamt1 = NetActivity from dbo.GLBL with(nolock)
   				where GLCo = @glco and GLAcct = @ratioacct1 and Mth = @mth
   			end
   			if @ratiobasis1 = 'Y'	/* based on year-to-date balance */
   			begin
   				select @beginbal = 0
   			
   				select @beginbal = BeginBal from dbo.GLYB with(nolock)
   				where GLCo = @glco and FYEMO = @fyemo and GLAcct = @ratioacct1
   				
   				select @amt = isnull(sum(NetActivity),0) from dbo.GLBL with(nolock)
   				where GLCo = @glco and GLAcct = @ratioacct1 and Mth >= @beginmth and Mth <= @mth
   				
   				select @ratioamt1 = @beginbal + @amt
   			end
   		end
      	if @ratiotype1 = 'T'	/* ratio type 1 source is Total */
   		begin
   			select @ratioamt1 = TotalAmt from @totals	where TotalNo = @ratiototal1
   		end
   
   		/* calculate ratio 2 */
   		if @ratiotype2 = 'A'	/* ratio type 2 source is GL Account */
   		begin
   			if @ratiobasis2 = 'M'	/* based on month-to-date activity */
    			begin
   				select @ratioamt2 = NetActivity from dbo.GLBL with(nolock)
   				where GLCo = @glco and GLAcct = @ratioacct2 and Mth = @mth
   			end
   			if @ratiobasis2 = 'Y'	/* based on year-to-date balance */
   			begin
   				select @beginbal = 0
   			
   				select @beginbal = BeginBal from bGLYB with(nolock)
   				where GLCo = @glco and FYEMO = @fyemo and GLAcct = @ratioacct2
   			
   				select @amt = isnull(sum(NetActivity),0) from dbo.GLBL with(nolock)
   				where GLCo = @glco and GLAcct = @ratioacct2  and Mth >= @beginmth and Mth <= @mth
   				
   				select @ratioamt2 = @beginbal + @amt
   			end
   		end
      	if @ratiotype2 = 'T'	/* ratio type 2 source is Total */
   		begin
   			select @ratioamt2 = TotalAmt from @totals where TotalNo = @ratiototal2
   		end
   
   		/* apply ratio to source amount */
   		if  @ratioamt2 <> 0
   		begin
   			select @amt = @sourceamt * abs(@ratioamt1/@ratioamt2)
   		end
   	end
   
   	/* Allocation type 3 - Fixed Amount */
   	if @alloctype = 3
   	begin
   		select @amt = @amount
   	end
   
    	/****** Process Post To info ******/
   
   	/* skip if zero calculated amount */
   	--if @amt = 0 goto process_loop  --DC #21384
   
   	-- adjust amount for DR or CR, exprect when posting to a Total (#23245) 
   	if @posttotype <> 'T'
   	begin
   		if @drcr = 'D' select @amt = abs(@amt)
   		if @drcr = 'C' select @amt = -1 * abs(@amt)
   	end
   
   	/* post to GL Account */
   	if @posttotype = 'A'
   	begin
   		-- skip interco entries if GL Company option is off
   		if @glco <> @posttoglco and @xcompjrnlyn = 'N' goto process_loop
   			   		
   		--ES 03/18/04 - Issue 24058 properly handle zero amounts and inactive accounts
   		if (select Active from dbo.GLAC with(nolock) where GLCo = @posttoglco and GLAcct = @posttoglacct) = 'N'
   			goto process_loop
   
   		if @amt = 0 and @alloctype <> 3 --this is not a fixed amount - do not post
   			goto process_loop
   			
   		/* get next available sequence # for this batch */
		select @batchseq = isnull(max(BatchSeq),0) + 1  from dbo.GLJB with(nolock)
   		where Co = @glco and Mth = @mth and BatchId = @batchid
   
		/* add entry to batch */
		insert dbo.GLJB(Co, Mth, BatchId, BatchSeq, Jrnl, EntryId, Seq, GLRef,
   			Description, GLAcct, Amount, ActDate, InterCo)
		values (@glco, @mth, @batchid, @batchseq, @jrnl, @entryid, @seq, @glref,
   	        @transdesc, @posttoglacct, @amt, @actdate, @posttoglco)

		select @cnt = @cnt + 1		-- accumulate # of entries added to batch #27644
       end
   
   	/* post to Total */
   	if @posttotype = 'T'
	begin
   		update @totals 
   		set TotalAmt = TotalAmt + @amt
   		where TotalNo = @posttototal
   		if @@rowcount = 0
   		begin
   			insert into @totals (TotalNo, TotalAmt)
   			values (@posttototal, @amt)
   		end
   	end
   
     goto process_loop
   
RoundingCheck:

--142446 - Modifed fix.  Including InterCo in the CTE and join. Check that the Journal/Entry combination has at 
--least 1 Debit and 1 Credit before fixing the rounding error.  If Journal/Entry is just debit or credit
--then it is assumed users will either have a second Journal/Entry coming in that will balance or they will
--be modifying the batch manually to bring it back in balance.

DECLARE @cr_count TINYINT, @dr_count TINYINT
SELECT @cr_count = 0, @dr_count = 0

IF exists (SELECT 1 from GLAJ WHERE GLCo = @glco and Jrnl = @jrnl and EntryId = @entryid and DrCr = 'C') 
BEGIN
	SELECT @cr_count = 1
END

IF exists (SELECT 1 from GLAJ WHERE GLCo = @glco and Jrnl = @jrnl and EntryId = @entryid and DrCr = 'D') 
BEGIN
	SELECT @dr_count = 1
END

IF @cr_count = @dr_count
BEGIN
	----Proposed fix
	/*Issue 138145* Start*/
	/*TK-07615 #144401 Removed references to InterCo so that adjustment is made to highest Seq regardless of posting company*/
	--Adjust Batch GL Co out of balance entries
	WITH Rounding_CTE1 (Co, Jrnl, GLRef, EntryId, Net, MaxSeq)
	as
	(SELECT Co, Jrnl, GLRef, EntryId, SUM(Amount), MAX(Seq) 
		  FROM dbo.GLJB
		  WHERE  Co = @glco and Mth = @mth and BatchId = @batchid
		  GROUP BY Co, Jrnl, GLRef, EntryId)
	UPDATE dbo.GLJB
	SET Amount = Amount - r.Net   -- adjust last seq of each entry with net amount to balance debits with credits
	FROM dbo.GLJB b
	JOIN Rounding_CTE1 r ON r.Co = b.Co AND r.Jrnl = b.Jrnl  
		  AND r.GLRef = b.GLRef AND r.EntryId = b.EntryId AND r.MaxSeq = b.Seq
	WHERE b.Co = @glco AND b.Mth = @mth AND b.BatchId = @batchid;
	 /*Issue 138145*/
END

bspexit:
	if @cursoropen = 1
	begin
          close GLJB_insert
		deallocate GLJB_insert
     end

	if @rcode = 0 select @errmsg = convert(varchar,@cnt) + ' Journal entries were added to your batch.'
     return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspGLJBInitialize] TO [public]
GO
