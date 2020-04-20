SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspINABPostGL]
   /******************************************************************************************************
   * CREATED BY:   GR 1/28/00
   * Modified: GG 03/02/00 - cleanup
   *			GR 04/12/00 - Corrected GLDT update
   *			RM 09/07/01 - Added Source 'IN Count'
   *			GC 04/08/04 - #23061 - Added ISNULLs to build GL Description
   *			GP 05/06/09 - Modified @matldesc bItemDesc
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
   
   declare @rcode int,  @glco bCompany, @jrnl bJrnl, @gladjinterfacelvl tinyint, @gladjsummarydesc varchar(60), @gladjdetaildesc varchar(60),
           @glref bGLRef, @opencursorINAG int, @loc bLoc, @material bMatl, @matldesc bItemDesc, @intrans int, @amount bDollar, @glacct bGLAcct,
           @actdate bDate, @gltrans int, @oldnew int, @desccontrol varchar(60), @desc varchar(60), @findidx int, @found varchar(30),
           @matlgroup bGroup, @transdesc bDesc, @batchseq int,@source varchar(10)
   
   select @rcode = 0
   select @opencursorINAG=0
   
   select @source = Source from bHQBC where Co = @co and Mth = @mth and BatchId = @batchid
   
   -- get IN company info
   select @jrnl = Jrnl, @gladjinterfacelvl = GLAdjInterfaceLvl, @gladjsummarydesc = GLAdjSummaryDesc,
       @gladjdetaildesc = GLAdjDetailDesc
   from bINCO
   where INCo = @co
   if @@rowcount = 0
       begin
       select @errmsg = 'Missing IN Company!', @rcode = 1
       goto bspexit
       end
   
   -- No update to GL
   if isnull(@gladjinterfacelvl, 0) = 0
       begin
       delete bINAG where INCo = @co and Mth = @mth and BatchId = @batchid
       goto bspexit
    	end
   
   -- set GL Reference using Batch Id - right justified 10 chars
   select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)
   
   -- Summary update to GL - one entry per GLCo/GLAcct/Trans unless GL Acct flagged for detail
   if @gladjinterfacelvl = 2
       begin
       -- use summary level cursor on IN AG Distributions
       declare INAG_cursor cursor for
       select g.GLCo, g.GLAcct, (convert(numeric(12,2), sum(g.Amt)))
    	from bINAG g
       join bGLAC c on c.GLCo = g.GLCo and c.GLAcct = g.GLAcct
       where g.INCo = @co and g.Mth = @mth and g.BatchId = @batchid and c.InterfaceDetail = 'N'
    	group by g.GLCo, g.GLAcct
   
       open INAG_cursor
       select @opencursorINAG = 1
   
       gl_summary_posting_loop:                            --loop through all the records
           fetch next from INAG_cursor into @glco, @glacct, @amount
   
           if @@fetch_status = -1 goto gl_summary_posting_end
           if @@fetch_status <> 0 goto gl_summary_posting_loop
   
           begin transaction
           -- get next available transaction # for GLDT
           exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
           if @gltrans = 0 goto gl_summary_posting_error
   
           -- add GL Transaction
           insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
               ActDate, DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
      	    values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, @source,
    	 	    @dateposted, @dateposted, @gladjsummarydesc, @batchid, @amount, 0, 'N', null, 'N')
   
           -- delete IN AG distributions just posted
           delete bINAG
           where INCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco
               and GLAcct = @glacct
           if @@rowcount = 0 goto gl_summary_posting_error
   
           commit transaction
   
           goto gl_summary_posting_loop
   
       gl_summary_posting_error:	-- error occured within transaction - rollback any updates and continue
           rollback transaction
           goto gl_summary_posting_loop
   
       gl_summary_posting_end:	    -- no more rows to process
           close INAG_cursor
           deallocate INAG_cursor
           select @opencursorINAG = 0
       end
   
   -- Detail update for everything remaining in INAG Distributions
   declare INAG_cursor cursor for
   select GLCo, GLAcct, Loc, Material, Description, INTrans, Amt, OldNew, ActDate, BatchSeq
   from bINAG
   where INCo = @co and Mth = @mth and BatchId = @batchid
   
   -- open cursor
   open INAG_cursor
   select @opencursorINAG = 1
   
   gl_detail_posting_loop:
       fetch next from INAG_cursor into @glco, @glacct, @loc, @material, @transdesc, @intrans, @amount, @oldnew, @actdate, @batchseq
   
       if @@fetch_status = -1 goto gl_detail_posting_end
       if @@fetch_status <> 0 goto gl_detail_posting_loop
   
       begin transaction
   
         -- parse out the transaction description
           select @desccontrol = isnull(rtrim(@gladjdetaildesc),'')
           select @desc = ''
   
           --get the material description from HQMT
           select @matlgroup=MatlGroup from bHQCO where HQCo=@co
           select @matldesc=Description from bHQMT where MatlGroup=@matlgroup and Material=@material
   
           while (@desccontrol <> '')
               begin
               select @findidx = charindex('/',@desccontrol)
               if @findidx = 0
                   select @found = @desccontrol, @desccontrol = ''
               else
                   select @found = substring(@desccontrol,1,@findidx-1), @desccontrol = substring(@desccontrol,@findidx+1,60)
   
               if @found = 'Location'  select @desc = isnull(@desc,'') + '/' + isnull(@loc,'')
               if @found = 'Trans#'  select @desc = isnull(@desc,'') + '/' + isnull(convert(varchar(15), @intrans),'')
           	if @found = 'Matl#' select @desc = isnull(@desc,'') + '/' +  isnull(@material,'')
           	if @found = 'Matl Desc'	   select @desc = isnull(@desc,'') + '/' +  isnull(@matldesc,'')
               if @found = 'Trans Desc' select @desc = isnull(@desc,'') + '/' + isnull(@transdesc,'')
               end
   
           -- remove leading '/'
           if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))
   
       -- get next available transaction # for GLDT
     	exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
    	if @gltrans = 0 goto gl_detail_posting_error
   
       -- add GL Transaction
       insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate, DatePosted,
           Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
    	values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, @source, @actdate, @dateposted,
           @desc, @batchid, @amount, 0, 'N', null, 'N')
   
       -- delete AP GL Distributions just posted
    	delete from bINAG
       where INCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
    	  and GLCo = @glco and GLAcct = @glacct and OldNew=@oldnew
    	if @@rowcount = 0 goto gl_detail_posting_error
   
       commit transaction
   
       goto gl_detail_posting_loop
   
   gl_detail_posting_error:	-- error occured within transaction - rollback any updates and continue
       rollback transaction
       goto gl_detail_posting_loop
   
   gl_detail_posting_end:	-- no more rows to process
       close INAG_cursor
       deallocate INAG_cursor
       select @opencursorINAG= 0
   
   bspexit:
       if @opencursorINAG = 1
           begin
    		close INAG_cursor
    		deallocate INAG_cursor
    		end
   --   if @rcode<>0 select @errmsg
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINABPostGL] TO [public]
GO
