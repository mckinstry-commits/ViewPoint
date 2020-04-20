SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************/
   CREATE  procedure [dbo].[bspMSMHPostGL]
   /***********************************************************
    * Created By:	GF 03/01/2005
    * Modified By:
    *
    * Called from the bspMSMHPost procedure to post GL distributions
    * tracked in bMSMG for Material Vendor Worksheet Invoice batches.
    *
    *
    * GL Interface Levels: (uses GL Expense GL Interface Level from bAPCO)
    *	0       No update
    *	1       Summarize entries by GLCo#/GL Account
    *  2 or 3  Transaction or Line level interfaced at Invoice level - Full detail by Line not available
    *
    * INPUT PARAMETERS
    *   @co             MS Co#
    *   @mth            Batch Month
    *   @batchid        Batch ID
    *   @dateposted     Posting date
    *
    * OUTPUT PARAMETERS
    *   @errmsg         error message if something went wrong
    *
    * RETURN VALUE
    *   0               success
    *   1               fail
    *****************************************************/
   (@co bCompany, @mth bMonth, @batchid bBatchID,
    @dateposted bDate = null, @errmsg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @apco bCompany, @expjrnl bJrnl, @glexpinterfacelvl tinyint, @glexpsummarydesc varchar(60),
       @glexptransdesc varchar(60), @glexpdetaildesc varchar(60), @glref bGLRef, @openMSMG_cursor tinyint,
       @glco bCompany, @glacct bGLAcct, @amount bDollar, @gltrans bTrans, @vendorgroup bGroup, @vendor bVendor,
       @apref bAPReference, @invdesc bDesc, @invdate bDate, @aptrans bTrans, @sortname bSortName,
       @findidx tinyint, @found varchar(20), @seq int, @desc varchar(60), @desccontrol varchar(60)
   
   select @rcode = 0, @openMSMG_cursor = 0
   
   -- get MS Company info
   select @apco = APCo from bMSCO with (Nolock) where MSCo = @co
   if @@rowcount = 0
       begin
       select @errmsg = 'Invalid MS Company!', @rcode = 1
       goto bspexit
       end
   -- get AP Company info
   select @expjrnl = ExpJrnl, @glexpinterfacelvl = GLExpInterfaceLvl, @glexpsummarydesc = GLExpSummaryDesc,
       @glexpdetaildesc = GLExpDetailDesc, @glexptransdesc = GLExpTransDesc
   from bAPCO with (Nolock) where APCo = @apco
   if @@rowcount = 0
       begin
       select @errmsg = 'Missing AP Company!', @rcode = 1
       goto bspexit
       end
   
   -- No update to GL
   if @glexpinterfacelvl = 0
       begin
       delete bMSWG where MSCo = @co and Mth = @mth and BatchId = @batchid
       goto bspexit
    	end
   
   -- set GL Reference using Batch Id - right justified 10 chars */
   select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)
   
   -- Summary update to GL - one entry per GL Co/GLAcct, unless GL Account flagged for detail
   if @glexpinterfacelvl = 1
       begin
       -- use summary level cursor on AP GL Distributions
       declare bcMSMG cursor LOCAL FAST_FORWARD
   	for select g.GLCo, g.GLAcct, (convert(numeric(12,2),sum(g.Amount)))
    	from bMSMG g
       join bGLAC c with (Nolock) on c.GLCo = g.GLCo and c.GLAcct = g.GLAcct
       where g.MSCo = @co and g.Mth = @mth and g.BatchId = @batchid
           and c.InterfaceDetail = 'N'
    	group by g.GLCo, g.GLAcct
   
       -- open cursor
       open bcMSMG
       select @openMSMG_cursor = 1
   
       gl_summary_posting_loop:
           fetch next from bcMSMG into @glco, @glacct, @amount
   
           if @@fetch_status = -1 goto gl_summary_posting_end
           if @@fetch_status <> 0 goto gl_summary_posting_loop
   
           begin transaction
   
           if @amount <> 0
               begin
               -- get next available transaction # for GL Detail
               exec @gltrans = dbo.bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
               if @gltrans = 0 goto gl_summary_posting_error
   
               -- add GL Detail
               insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
                   ActDate, DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
      	        values(@glco, @mth, @gltrans, @glacct, @expjrnl, @glref, @co, 'AP Entry',
    	 	        @dateposted, @dateposted, @glexpsummarydesc, @batchid, @amount, 0, 'N', null, 'N')
               end
   
           -- delete MS GL Distributions just posted
           delete bMSMG
           where MSCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @glacct
   
           commit transaction
   
           goto gl_summary_posting_loop
   
       gl_summary_posting_error:	-- error occured within transaction - rollback any updates and continue
           rollback transaction
           goto gl_summary_posting_loop
   
       gl_summary_posting_end:	    -- no more rows in summary cursor
           close bcMSMG
           deallocate bcMSMG
           select @openMSMG_cursor = 0
       end
   
   
   
   -- Transaction level is the most detailed level available for this update
   -- use a transaction level cursor on MS GL Distributions
   declare bcMSMG cursor LOCAL FAST_FORWARD 
   for select GLCo, GLAcct, VendorGroup, MatlVendor, APRef, InvDescription, InvDate,
       APTrans,(convert(numeric(12,2), sum(Amount)))
   from bMSMG
   where MSCo = @co and Mth = @mth and BatchId = @batchid
   group by GLCo, GLAcct, VendorGroup, MatlVendor, APRef, InvDescription, InvDate, APTrans
   
   -- open cursor
   open bcMSMG
   select @openMSMG_cursor = 1
   
   gl_transaction_posting_loop:
       fetch next from bcMSMG into @glco, @glacct, @vendorgroup, @vendor, @apref, @invdesc, @invdate, @aptrans, @amount
   
       if @@fetch_status = -1 goto bspexit
       if @@fetch_status <> 0 goto gl_transaction_posting_loop
   
       -- get Vendor Sort Name
       select @sortname = null
       select @sortname = SortName from bAPVM with (Nolock) where VendorGroup = @vendorgroup and Vendor = @vendor
   
       -- parse out the transaction description - use description control based on interface level
       select @desccontrol = isnull(rtrim(@glexpdetaildesc),'')    -- default to expense detail description
       if @glexpinterfacelvl = 2 select @desccontrol = isnull(rtrim(@glexptransdesc),'')   -- use trans desctiption
   
       if @desccontrol is null select @desccontrol='Trans#'    -- make sure we have at least one item in desc control
   
       select @desc = ''
       while (@desccontrol <> '')
           begin
           select @findidx = charindex('/',@desccontrol)
           if @findidx = 0
               select @found = @desccontrol, @desccontrol = ''
           else
               select @found = substring(@desccontrol,1,@findidx-1), @desccontrol = substring(@desccontrol,@findidx+1,60)
   
           if @found = 'InvDesc'  select @desc = @desc + '/' + isnull(@invdesc,'')
           if @found = 'Vendor#'  select @desc = @desc + '/' + convert(varchar(10), @vendor)
           if @found = 'SortName' select @desc = @desc + '/' +  isnull(@sortname,'')
           if @found = 'APRef'	   select @desc = @desc + '/' +  isnull(@apref,'')
           if @found = 'InvDate'  select @desc = @desc + '/' +  convert(varchar(15), @invdate, 107)
           if @found = 'Trans#'   select @desc = @desc + '/' +  convert(varchar(15), @aptrans)
           end
   
       -- remove leading '/'
       if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))
   
       begin transaction
   
       if @amount <> 0
           begin
           -- get next available transaction # for GLDT
           exec @gltrans = dbo.bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
           if @gltrans = 0 goto gl_transaction_posting_error
   
           -- add GL Transaction
           insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
               ActDate, DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
      	    values(@glco, @mth, @gltrans, @glacct, @expjrnl, @glref, @co, 'AP Entry',
    	 	    @dateposted, @dateposted, @desc, @batchid, @amount, 0, 'N', null, 'N')
           end
   
       -- delete MS GL distributions just posted
       delete bMSMG
       where MSCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco
           and GLAcct = @glacct and APTrans = @aptrans
   
       commit transaction
   
       goto gl_transaction_posting_loop
   
   gl_transaction_posting_error:	-- error occured within transaction - rollback any updates and continue
       rollback transaction
       goto gl_transaction_posting_loop
   
   
   
   
   bspexit:
       if @openMSMG_cursor = 1
           begin
     		close bcMSMG
     		deallocate bcMSMG
     		end
   
       if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSMHPostGL] TO [public]
GO
