SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspINTBPostGL]
   /******************************************************************************************************
   * CREATED BY:   GR 02/24/00
   * Modified:	RM 10/15/01 - Fixed GL Posting
   *				DC 12/22/03 - 23061 - Check for ISNull when concatenating fields to create descriptions
   *				GC 04/08/04 - 23061 - Added more checks for ISNULLs when concatenating fields to create GL Desc.
   *				GC 04/08/04 - 23061 - Removed MISSING: @matldesc in the ISNULL check and changed to ''
   *				GG 1/12/05 - #24324 - corrected GL detail trans description
   *
   * USAGE:
   *   Called by the main IN Adjustments Posting procedure (bspINABPost)
   *   to update GL distributions for a batch of IN Adjustments.
   *
   * INPUT PARAMETERS
   *   @co             IN Co#
   *   @mth            Batch Month
   *   @batchid        Batch ID
   *   @dateposted     Posting date - recorded with each GL transaction
   *
   * OUTPUT PARAMETERS
   *   @errmsg         error message if something went wrong
   *
   * RETURN VALUE
   *   0               success
   *   1               fail
   **********************************************************************************************************/
      	(@co bCompany, @mth bMonth, @batchid bBatchID,
      	@dateposted bDate = null, @errmsg varchar(255) output)
   as
     
   set nocount on
     
   declare @rcode int,  @glco bCompany, @jrnl bJrnl, @gltrnsfrinterfacelvl tinyint, @gltrnsfrsummarydesc varchar(60),
   	@gltrnsfrdetaildesc varchar(60), @glref bGLRef, @opencursorINTG int, @loc bLoc, @material bMatl, @matldesc bDesc,
   	@intrans int, @amount bDollar, @glacct bGLAcct, @actdate bDate, @gltrans int, @oldnew int,
   	@desccontrol varchar(60), @desc varchar(60), @findidx int, @found varchar(30),@batchseq int, @transdesc bDesc
     
   select @rcode = 0, @opencursorINTG = 0
     
   -- get IN company info
   select @jrnl = Jrnl, @gltrnsfrinterfacelvl = GLTrnsfrInterfaceLvl, @gltrnsfrsummarydesc = GLTrnsfrSummaryDesc,
   	@gltrnsfrdetaildesc = GLTrnsfrDetailDesc
   from dbo.bINCO with (nolock)
   where INCo = @co
   if @@rowcount = 0
   	begin
       select @errmsg = 'Missing IN Company!', @rcode = 1
       goto bspexit
       end
     
   -- No GL update, clear GL distrubutions and exit
   if isnull(@gltrnsfrinterfacelvl, 0) = 0
   	begin
       delete dbo.bINTG where INCo = @co and Mth = @mth and BatchId = @batchid
       goto bspexit
      	end
     
   -- set GL Reference using Batch Id - right justified 10 chars
   select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)
     
   -- Summary update to GL - one entry per GLCo/GLAcct/Trans unless GL Acct flagged for detail
   if @gltrnsfrinterfacelvl = 2
   	begin
       -- use summary level cursor on IN TG Distributions
       declare INTG_cursor cursor for
       select g.GLCo, g.GLAcct, (convert(numeric(12,2), sum(g.Cost))),g.BatchSeq,g.Loc
      	from dbo.bINTG g
   	join dbo.bGLAC c on c.GLCo = g.GLCo and c.GLAcct = g.GLAcct
       where g.INCo = @co and g.Mth = @mth and g.BatchId = @batchid and c.InterfaceDetail = 'N'
      	group by g.GLCo, g.GLAcct, g.BatchSeq, g.Loc
     
       open INTG_cursor
       select @opencursorINTG = 1
     
   	gl_summary_posting_loop:                            --loop through all the records
   		fetch next from INTG_cursor into @glco, @glacct, @amount, @batchseq, @loc
           if @@fetch_status <> 0 goto gl_summary_posting_end
     
           begin transaction
           -- get next available transaction # for GLDT
           exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
           if @gltrans = 0 goto gl_summary_posting_error
     
           -- add GL Transaction
           insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
           	ActDate, DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
        	values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, 'IN Trnsfr',
      	 	    @dateposted, @dateposted, @gltrnsfrsummarydesc, @batchid, @amount, 0, 'N', null, 'N')
           if @@rowcount = 0 goto gl_summary_posting_error
     
   
           -- delete IN GL distributions just posted
           delete bINTG
           where INCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco
           	and GLAcct = @glacct and BatchSeq = @batchseq and Loc = @loc
     
           commit transaction
     
           goto gl_summary_posting_loop
     
         gl_summary_posting_error:	-- error occured within transaction - rollback any updates and continue
             rollback transaction
             goto gl_summary_posting_loop
     
         gl_summary_posting_end:	    -- no more rows to process
             close INTG_cursor
             deallocate INTG_cursor
             select @opencursorINTG = 0
         end
     
   -- Detail update for everything remaining in INAG Distributions
   declare INTG_cursor cursor for
   select g.GLCo, g.GLAcct, g.Loc, g.Material, g.Description, g.Cost, g.ActDate, g.BatchSeq, m.Description
   from dbo.bINTG g
   join dbo.bHQMT m on m.MatlGroup = g.MatlGroup and m.Material = g.Material	-- #24324 added join to pull Matl description
   where g.INCo = @co and g.Mth = @mth and g.BatchId = @batchid
     
   -- open cursor
   open INTG_cursor
   select @opencursorINTG = 1
     
   gl_detail_posting_loop:
   	fetch next from INTG_cursor into @glco, @glacct, @loc, @material, @transdesc, @amount,
   		@actdate, @batchseq, @matldesc
       if @@fetch_status <> 0 goto gl_detail_posting_end
   
       -- parse out the transaction description
       select @desccontrol = isnull(rtrim(@gltrnsfrdetaildesc),'')
       select @desc = ''
       while (@desccontrol <> '')
       	begin
           select @findidx = charindex('/',@desccontrol)
           if @findidx = 0
           	select @found = @desccontrol, @desccontrol = ''
           else
               select @found = substring(@desccontrol,1,@findidx-1), @desccontrol = substring(@desccontrol,@findidx+1,60)
     
   		-- #24324 - corrected GL transaction detail description items
           if @found = 'Location'  select @desc = isnull(@desc,'') + '/' + isnull(@loc,'')
           if @found = 'Matl#' select @desc = isnull(@desc,'') + '/' +  isnull(@material,'')
           if @found = 'Matl Desc' select @desc = isnull(@desc,'') + '/' +  isnull(@matldesc,'')
   		if @found = 'Trans Desc' select @desc = isnull(@desc,'') + '/' +  isnull(@transdesc,'')
           end
     
       -- remove leading '/'
       if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))
     
   	begin transaction
       -- get next available transaction # for GLDT
   	exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
      	if @gltrans = 0 goto gl_detail_posting_error
     
       -- add GL Transaction
       insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate, DatePosted,
       	Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
      	values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, 'IN Trnsfr', @actdate, @dateposted,
           @desc, @batchid, @amount, 0, 'N', null, 'N')
      	if @@rowcount = 0 goto gl_detail_posting_error
     
        -- delete IN GL Distribution just posted
      	delete from bINTG
       where INCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @glacct
   		and BatchSeq = @batchseq and Loc = @loc
      	if @@rowcount = 0 goto gl_detail_posting_error
     
       commit transaction
     
       goto gl_detail_posting_loop
     
   gl_detail_posting_error:	-- error occured within transaction - rollback any updates and continue
   	rollback transaction
       goto gl_detail_posting_loop
     
   gl_detail_posting_end:	-- no more rows to process
       close INTG_cursor
       deallocate INTG_cursor
       select @opencursorINTG= 0
     
   bspexit:
       if @opencursorINTG = 1
       	begin
      		close INTG_cursor
      		deallocate INTG_cursor
      		end
   
     --  if @rcode<>0 select @errmsg
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINTBPostGL] TO [public]
GO
