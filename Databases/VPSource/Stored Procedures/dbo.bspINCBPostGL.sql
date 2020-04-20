SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspINCBPostGL]
   /***********************************************************
   * Created: GG 12/15/02
   * Modified: RM 12/23/02 Cleanup Double Quotes
   *			GC 04/08/04 #23061 - Adding ISNULLs to build GL Description
   *			TRL 07/30/07 - added with (nolock) and dbo. to views
   *			GP 05/06/09 - Modified @matldesc bItemDesc
   *			GP 12/24/09 - Issue 137182 changed @description to bItemDesc
   * Usage:
   *   Called by bspINCBPost to update GL distributions for a batch of 
   *	validated IN/MO Confirmations.
   *
   * Inputs:
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
   *****************************************************/
    	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
    	@dateposted bDate = null, @errmsg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @opencursorINCG tinyint, @jrnl bJrnl, @glmointerfacelvl tinyint, @glsummarydesc varchar(60),
   	@gldetaildesc varchar(60), @glref bGLRef, @gltrans bTrans,  @glco bCompany, @glacct bGLAcct,
    	@seq int, @oldnew tinyint, @intrans bTrans, @mo bMO, @moitem bItem, @loc bLoc, @matlgroup bGroup,
   	@material bMatl, @description bItemDesc, @confirmdate bDate, @amt bDollar, @findidx tinyint,
       @found varchar(20), @desc varchar(60), @desccontrol varchar(60), @matldesc bItemDesc
       
   select @rcode = 0
   
   -- get IN company info
   select @jrnl = Jrnl, @glmointerfacelvl = GLMOInterfaceLvl, @glsummarydesc = GLMOSummaryDesc,
       @gldetaildesc = GLMODetailDesc
   from dbo.INCO where INCo = @co
   if @@rowcount = 0
       begin
       select @errmsg = 'Missing IN Company!', @rcode = 1
       goto bspexit
       end
   
   -- No update to GL
   if @glmointerfacelvl = 0
       begin
       delete dbo.INCG where INCo = @co and Mth = @mth and BatchId = @batchid
       goto bspexit
    	end
   
   -- set GL Reference using Batch Id - right justified 10 chars */
   select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)
   
   -- Summary update to GL - one entry per GL Co/GLAcct, unless GL Account flagged for detail
   if @glmointerfacelvl = 2
       begin
       -- use summary level cursor on GL Distributions
       declare bcINCG cursor for
       select g.GLCo, g.GLAcct,(convert(numeric(12,2),sum(g.Amt)))
    	from dbo.INCG g with (nolock)
   	join dbo.GLAC c with(nolock) on g.GLCo = c.GLCo and g.GLAcct = c.GLAcct
       where g.INCo = @co and g.Mth = @mth and g.BatchId = @batchid
           and c.InterfaceDetail = 'N'
    	group by g.GLCo, g.GLAcct
   
       -- open cursor
       open bcINCG
       select @opencursorINCG = 1
   
       gl_summary_posting_loop:
           fetch next from bcINCG into @glco, @glacct, @amt
   
           if @@fetch_status = -1 goto gl_summary_posting_end
           if @@fetch_status <> 0 goto gl_summary_posting_loop
   
           begin transaction
           -- get next available transaction # for GL Detail
           exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
           if @gltrans = 0 goto gl_summary_posting_error
   
           -- add GL Detail
           insert dbo.GLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
               ActDate, DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
      	    values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, 'MO Confirm',
    	 	    @dateposted, @dateposted, @glsummarydesc, @batchid, @amt, 0, 'N', null, 'N')
   
           -- delete GL Distributions just posted
           delete dbo.INCG
           where INCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @glacct
   
           commit transaction
   
           goto gl_summary_posting_loop
   
       gl_summary_posting_error:	-- error occured within transaction - rollback any updates and exit
           rollback transaction
 
           goto bspexit
   
       gl_summary_posting_end:	    -- no more rows in summary cursor
           close bcINCG
           deallocate bcINCG
           select @opencursorINCG = 0
       end
   
   -- Detail update for everything remaining in GL Distributions
   declare bcINCG cursor for
   select GLCo, GLAcct, BatchSeq, OldNew, INTrans, MO, MOItem, Loc, MatlGroup, Material,
   	Description, ConfirmDate, Amt
   from dbo.INCG with (nolock) 
   where INCo = @co and Mth = @mth and BatchId = @batchid
   
   -- open cursor
   open bcINCG
   select @opencursorINCG = 1
   
   gl_detail_posting_loop:
       fetch next from bcINCG into @glco, @glacct, @seq, @oldnew, @intrans, @mo, @moitem,
   		@loc, @matlgroup, @material, @description, @confirmdate, @amt
   
       if @@fetch_status = -1 goto gl_detail_posting_end
       if @@fetch_status <> 0 goto gl_detail_posting_loop
   
   	-- get Material description
   	select @matldesc = null
   	select @matldesc = Description
   	from dbo.HQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
   
       begin transaction
   
       -- parse out the description
   	select @desccontrol = isnull(rtrim(@gldetaildesc),'')
       if @desccontrol is null select @desccontrol = 'Trans#'
       select @desc = ''
       while (@desccontrol <> '')
           begin
           select @findidx = charindex('/',@desccontrol)
           if @findidx = 0
               select @found = @desccontrol, @desccontrol = ''
           else
               select @found=substring(@desccontrol,1,@findidx-1), @desccontrol = substring(@desccontrol,@findidx+1,60)
   
   		-- hardcoded items must match selection options in IN Company
   		if @found = 'MO' select @desc = isnull(@desc,'') + '/' +  isnull(@mo,'')
   		if @found = 'MO Item' select @desc = isnull(@desc,'') + '/' +  isnull(convert(varchar(10),@moitem),'')
    		if @found = 'Location' select @desc = isnull(@desc,'') + '/' + isnull(@loc,'')
   		if @found = 'Matl#' select @desc = isnull(@desc,'') + '/' +  isnull(@material,'')
   		if @found = 'Matl Desc' select @desc = isnull(@desc,'') + '/' +  isnull(@matldesc,' ')
   		if @found = 'Trans#' select @desc = isnull(@desc,'') + '/' +  isnull(convert(varchar(15),@intrans),'')
   		if @found = 'Trans Desc' select @desc = isnull(@desc,'') + '/' +  isnull(@description,' ')
           end
   
        -- remove leading '/'
        if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))
   
       -- get next available transaction # for GLDT
     	exec @gltrans = dbo.bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
    	if @gltrans = 0 goto gl_detail_posting_error
   
       -- add GL Transaction
       insert dbo.GLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate, DatePosted,
           Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
    	values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, 'MO Confirm', @confirmdate, @dateposted,
           @desc, @batchid, @amt, 0, 'N', null, 'N')
   
       -- delete AP GL Distributions just posted
    	delete from dbo.INCG
       where INCo = @co and Mth = @mth and BatchId = @batchid
    	  and GLCo = @glco and GLAcct = @glacct and BatchSeq = @seq and OldNew = @oldnew
    	if @@rowcount = 0 goto gl_detail_posting_error
   
       commit transaction
   
       goto gl_detail_posting_loop
   
   gl_detail_posting_error:	-- error occured within transaction - rollback any updates and continue
       rollback transaction
       goto gl_detail_posting_loop
   
   gl_detail_posting_end:	-- no more rows to process
       close bcINCG
       deallocate bcINCG
       select @opencursorINCG= 0
   
   bspexit:
       if @opencursorINCG = 1
           begin
    		close bcINCG
    		deallocate bcINCG
    		end
   
   --	if @rcode <> 0 select @errmsg
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINCBPostGL] TO [public]
GO
