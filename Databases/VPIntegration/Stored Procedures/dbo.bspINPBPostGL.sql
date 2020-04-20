SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspINPBPostGL]
   /******************************************************************************************************
   * CREATED BY:   GR 05/25/00
   * MODIFIED BY: 	RM 12/23/02 Cleanup Double Quotes
   *				GC 04/08/04 #23061 - Adding ISNULLs to create GL Description
   *				GG 1/12/05 - #24324 - corrected GL detail trans description
   *
   * USAGE:
   *   Called by the main IN Proudction Posting procedure (bspINPBPost)
   *   to update GL distributions for a batch of IN Production.
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
   
   declare @rcode int,  @glco bCompany, @jrnl bJrnl, @glprodinterfacelvl tinyint, @glprodsummarydesc varchar(60), @glproddetaildesc varchar(60),
           @glref bGLRef, @opencursorINPG int, @loc bLoc, @material bMatl, @matldesc bDesc, @amount bDollar, @glacct bGLAcct,
           @actdate bDate, @gltrans int, @desccontrol varchar(60), @desc varchar(60), @findidx int, @found varchar(30),
           @batchseq int, @prodseq int, @transdesc bDesc
   
   select @rcode = 0, @opencursorINPG=0
   
   -- get IN company info
   select @jrnl = Jrnl, @glprodinterfacelvl = GLProdInterfaceLvl, @glprodsummarydesc = GLProdSummaryDesc,
       @glproddetaildesc = GLProdDetailDesc
   from dbo.bINCO (nolock)
   where INCo = @co
   if @@rowcount = 0
       begin
       select @errmsg = 'Missing IN Company!', @rcode = 1
       goto bspexit
       end
   
   -- No GL update, clear GL distrubutions and exit
   if isnull(@glprodinterfacelvl, 0) = 0
       begin
       delete dbo.bINPG where INCo = @co and Mth = @mth and BatchId = @batchid
       goto bspexit
    	end
   
   -- set GL Reference using Batch Id - right justified 10 chars
   select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)
   
   -- Summary update to GL - one entry per GLCo/GLAcct/Trans unless GL Acct flagged for detail
   if @glprodinterfacelvl = 2
       begin
       -- use summary level cursor on IN PG Distributions
       declare INPG_cursor cursor for
       select g.GLCo, g.GLAcct, (convert(numeric(12,2), sum(g.Amount))), g.BatchSeq, g.ProdSeq
    	from dbo.bINPG g
   	join dbo.bGLAC c on c.GLCo = g.GLCo and c.GLAcct = g.GLAcct
       where g.INCo = @co and g.Mth = @mth and g.BatchId = @batchid and c.InterfaceDetail = 'N'
    	group by g.GLCo, g.GLAcct, g.BatchSeq, g.ProdSeq
   
       open INPG_cursor
       select @opencursorINPG = 1
   
       gl_summary_posting_loop:                            --loop through all the records
           fetch next from INPG_cursor into @glco, @glacct, @amount, @batchseq, @prodseq
           if @@fetch_status <> 0 goto gl_summary_posting_end
   
           begin transaction
           -- get next available transaction # for GLDT
           exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
           if @gltrans = 0 goto gl_summary_posting_error
   
           -- add GL Transaction
           insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
               ActDate, DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
      	    values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, 'IN Prod',
    	 	    @dateposted, @dateposted, @glprodsummarydesc, @batchid, @amount, 0, 'N', null, 'N')
           if @@rowcount = 0 goto gl_summary_posting_error
   
           -- delete IN GL distributions just posted
           delete bINPG
           where INCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco
               and GLAcct = @glacct and BatchSeq = @batchseq and ProdSeq = @prodseq
   
           commit transaction
   
           goto gl_summary_posting_loop
   
       gl_summary_posting_error:	-- error occured within transaction - rollback any updates and continue
           rollback transaction
           goto gl_summary_posting_loop
   
       gl_summary_posting_end:	    -- no more rows to process
           close INPG_cursor
           deallocate INPG_cursor
           select @opencursorINPG = 0
       end
   
   -- Detail update for everything remaining in INPG Distributions
   declare INPG_cursor cursor for
   select g.GLCo, g.GLAcct, g.BatchSeq, g.ProdSeq, g.Loc, g.Material, g.Description, g.Amount, m.Description
   from dbo.bINPG g
   join dbo.bHQMT m on m.MatlGroup = g.MatlGroup and m.Material = g.Material	-- #24324 added join to pull Matl description
   where g.INCo = @co and g.Mth = @mth and g.BatchId = @batchid
   
   -- open cursor
   open INPG_cursor
   select @opencursorINPG = 1
   
   gl_detail_posting_loop:
       fetch next from INPG_cursor into @glco, @glacct, @batchseq, @prodseq, @loc, @material, @transdesc, @amount, @matldesc
       if @@fetch_status <> 0 goto gl_detail_posting_end
       
       -- parse out the transaction description
       select @desccontrol = isnull(rtrim(@glproddetaildesc),'')
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
    	values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, 'IN Prod', @dateposted, @dateposted,
           @desc, @batchid, @amount, 0, 'N', null, 'N')
    	if @@rowcount = 0 goto gl_detail_posting_error
   
       -- delete IN GL Distributions just posted
    	delete from bINPG
       where INCo = @co and Mth = @mth and BatchId = @batchid
    	  and GLCo = @glco and GLAcct = @glacct and BatchSeq = @batchseq and ProdSeq = @prodseq
    	if @@rowcount = 0 goto gl_detail_posting_error
   
       commit transaction
   
       goto gl_detail_posting_loop
   
   gl_detail_posting_error:	-- error occured within transaction - rollback any updates and continue
       rollback transaction
       goto gl_detail_posting_loop
   
   gl_detail_posting_end:	-- no more rows to process
       close INPG_cursor
       deallocate INPG_cursor
       select @opencursorINPG= 0
   
   bspexit:
       if @opencursorINPG = 1
           begin
    		close INPG_cursor
    		deallocate INPG_cursor
    		end
   
       --if @rcode<>0 select @errmsg
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINPBPostGL] TO [public]
GO
