SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************/
   CREATE   procedure [dbo].[bspMSPostGL]
   /***********************************************************
    * Created:  GG 10/30/00
    * Modified: GG 05/30/01 - Added @@rowcount check after bGLDT inserts
    *			GF 08/01/2003 - issue #21933 - speed improvements
    *			GF 12/03/2003 - issue #23139 - added GLTrans to MSGL for rowset update.
    *			GF 06/14/2004 - #24827 - not using correct GLCo when getting next trans from bHQTC.
    *			TJL 03/17/08 - Issue #125508, Adjust Customer value in GL Description for 10 characters
    *
    *
    * Called from the bspMSTBPost and bspMSHBPost procedures to post
    * GL distributions tracked in bMSGL for both Ticket and Hauler Time
    * Sheet batches.
    *
    * Sign on values in 'old' entries has already been reversed.
    *
    * GL Interface Levels:
    *	0      No update
    *	1      Summarize entries by GLCo#/GL Account
    *   2      Full detail
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
    
    declare @rcode int, @openMSGL tinyint, @jrnl bJrnl, @glticlvl tinyint, @glticsummarydesc varchar(60),
        	@glticdetaildesc varchar(60), @glref bGLRef,  @gltrans bTrans, @amount bDollar, @findidx tinyint,
        	@found varchar(20), @seq int, @desc varchar(60), @desccontrol varchar(60), @jcco bCompany,
        	@job bJob, @material bMatl, @oldnew tinyint, @glco bCompany, @glacct bGLAcct, @msg varchar(255),
        	@mstrans bTrans, @vendor bVendor, @inco bCompany, @toloc bLoc, @ticket bTic, @saledate bDate,
        	@fromloc bLoc, @matlgroup bGroup, @saletype char(1), @custgroup bGroup, @customer bCustomer,
        	@custjob varchar(20), @haulline smallint, @msgl_count bTrans, @msgl_trans bTrans, 
   	@openMSGLTrans tinyint
    
    select @rcode = 0, @openMSGL = 0, @openMSGLTrans = 0
    
    -- get MS company info
    select @jrnl = Jrnl, @glticlvl = GLTicLvl, @glticsummarydesc = GLTicSummaryDesc,
           @glticdetaildesc = GLTicDetailDesc
    from bMSCO with (nolock) where MSCo = @co
    if @@rowcount = 0
        begin
        select @errmsg = 'Missing MS Company!', @rcode = 1
        goto bspexit
        end
    if @glticlvl not in (0,1,2)
        begin
        select @errmsg = 'Invalid GL Ticket Interface level assigned in MS Company.', @rcode = 1
        goto bspexit
        end
    
    -- Post General Ledger distributions 
    
    -- No update to GL
    if @glticlvl = 0
        begin
        delete bMSGL where MSCo = @co and Mth = @mth and BatchId = @batchid
        goto bspexit
     	end
    
    -- set GL Reference using Batch Id - right justified 10 chars */
    select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)
    
    -- Summary update to GL - one entry per GLCo#/GLAcct, unless GL Account flagged for detail
    if @glticlvl = 1
        begin
        -- use summary level cursor on AP GL Distributions
        declare bcMSGL cursor LOCAL FAST_FORWARD for
        select g.GLCo, g.GLAcct,(convert(numeric(12,2),sum(g.Amount)))
     	from bMSGL g
        join bGLAC c with (nolock) on c.GLCo = g.GLCo and c.GLAcct = g.GLAcct
        where g.MSCo = @co and g.Mth = @mth and g.BatchId = @batchid
            and c.InterfaceDetail = 'N'
     	group by g.GLCo, g.GLAcct
    
        -- open cursor
        open bcMSGL
        select @openMSGL = 1
    
        MSGL_summary_loop:
            fetch next from bcMSGL into @glco, @glacct, @amount
    
            if @@fetch_status = -1 goto MSGL_summary_end
            if @@fetch_status <> 0 goto MSGL_summary_loop
    
            begin transaction
    
            if @amount <> 0
                begin
                -- get next available transaction # for GL Detail
                exec @gltrans = dbo.bspHQTCNextTrans 'bGLDT', @glco, @mth, @msg output
                if @gltrans = 0
                    begin
       	            select @errmsg = 'Unable to update GL Detail.  ' + isnull(@msg,''), @rcode = 1
                    goto MSGL_posting_error
           	        end
    
                -- add GL Detail
                insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
                    ActDate, DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
       	        values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, 'MS Tickets',
     	 	        @dateposted, @dateposted, @glticsummarydesc, @batchid, @amount, 0, 'N', null, 'N')
                if @@rowcount = 0
    				begin
                    select @errmsg = 'Unable to add GL Detail entry', @rcode = 1
                	goto MSGL_posting_error
                	end
    	    	end
    
            -- delete MSGL Distributions just posted
            delete bMSGL
            where MSCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @glacct
    
            commit transaction
    
            goto MSGL_summary_loop
    
         MSGL_summary_end:	    -- no more rows in summary cursor
            close bcMSGL
            deallocate bcMSGL
            set @openMSGL = 0
        end
    
    
    
   -- Detail update for everything remaining in MS GL Distributions
   -- delete MSGL distributions where Amount equal zero. Not sent to GLDT.
   delete bMSGL where MSCo = @co and Mth = @mth and BatchId = @batchid and Amount = 0
   
   
   -- need cursor on bMSGL for each distinct GLCo
   declare bcMSGLTrans cursor LOCAL FAST_FORWARD for select distinct(GLCo)
   from bMSGL where MSCo = @co and Mth = @mth and BatchId = @batchid
   group by GLCo
   
   --open cursor
   open bcMSGLTrans
   select @openMSGLTrans = 1
   
   MSGLTrans_loop:
   fetch next from bcMSGLTrans into @glco
   if @@fetch_status = -1 goto MSGLTrans_end
   if @@fetch_status <> 0 goto MSGLTrans_loop
   
   -- get count of bMSGL rows that need a GLTrans
   select @msgl_count = count(*) from bMSGL 
   where MSCo=@co and Mth=@mth and BatchId=@batchid and GLTrans is null and GLCo=@glco
   -- only update HQTC and MSGL if there are MSGL rows that need updating
   if isnull(@msgl_count,0) <> 0
    	begin
      	-- get next available Transaction # for GLDT
      	exec @gltrans = dbo.bspHQTCNextTransWithCount 'bGLDT', @glco, @mth, @msgl_count, @msg output
      	if @gltrans = 0
      		begin
    		select @errmsg = 'Unable to update GL Detail.  ' + isnull(@msg,''), @rcode = 1
      		goto bspexit
      		end
      
    	-- set @msjc_trans to last transaction from bHQTC as starting point for update
    	set @msgl_trans = @gltrans - @msgl_count
      	
    	-- update bMSGL and set GLTrans
    	update bMSGL set @msgl_trans = @msgl_trans + 1, GLTrans = @msgl_trans
    	where MSCo=@co and Mth=@mth and BatchId=@batchid and GLTrans is null and GLCo=@glco
    	-- compare count from update with MSGL rows that need to be updated
    	if @@rowcount <> @msgl_count
    		begin
    		select @errmsg = 'Error has occurred updating GLTrans in MSGL distribution table!', @rcode = 1
    		goto bspexit
    		end
    	end
   
   goto MSGLTrans_loop
   
   MSGLTrans_end:
   	if @openMSGLTrans = 1
   		begin
   		close bcMSGLTrans
   		deallocate bcMSGLTrans
   		set @openMSGLTrans = 0
   		end
   
   
   
    -- use detail level cursor on MS GL Distributions
    declare bcMSGL cursor LOCAL FAST_FORWARD for
    select GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate, FromLoc, MatlGroup,
        Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount, GLTrans
    from bMSGL 
    where MSCo = @co and Mth = @mth and BatchId = @batchid
    
    -- open cursor
    open bcMSGL
    select @openMSGL = 1
    
    MSGL_detail_loop:
        fetch next from bcMSGL into @glco, @glacct, @seq, @haulline, @oldnew, @mstrans, @ticket, @saledate,
            @fromloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob, @jcco,
            @job, @inco, @toloc, @amount, @gltrans
    
        if @@fetch_status = -1 goto MSGL_detail_end
        if @@fetch_status <> 0 goto MSGL_detail_loop
    
        -- parse out the description
        select @desccontrol = rtrim(@glticdetaildesc)
        if @desccontrol is null select @desccontrol = 'Trans#'
        select @desc = ''
    
        while (@desccontrol <> '')
            begin
            select @findidx = charindex('/',@desccontrol)
            if @findidx = 0
                select @found = @desccontrol, @desccontrol = ''
            else
                select @found = substring(@desccontrol,1,@findidx-1), @desccontrol = substring(@desccontrol,@findidx+1,60)
    
            if @found = 'Trans#' select @desc = @desc + '/' + convert(varchar(10),@mstrans)
         	if @found = 'Ticket' select @desc = @desc + '/' + isnull(@ticket,'')
            if @found = 'Location' select @desc = @desc + '/' +  isnull(@fromloc,'')
            if @found = 'Material' select @desc = @desc + '/' +  isnull(@material,'')
            if @found = 'Purchaser'
                begin
                select @desc = @desc + '/' +  @saletype
                if @saletype = 'C' select @desc = @desc + '/' + convert(varchar(10),@customer) + '/' + isnull(@custjob,'')
    
                if @saletype = 'J' select @desc = @desc + '/' + convert(varchar(3),@jcco) + '/' + isnull(@job,'')
                if @saletype = 'I' select @desc = @desc + '/' + convert(varchar(3),@inco) + '/' + isnull(@toloc,'')
                end
            end
    
         -- remove leading '/'
         if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))
    
         begin transaction
    
    --      if @amount <> 0
    --         begin
    --         -- get next available transaction # for GLDT
    --   	    exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
    --  	    if @gltrans = 0
    --             begin
    --    	        select @errmsg = 'Unable to update GL Detail.  ' + @msg, @rcode = 1
    --             goto MSGL_posting_error
    --        	    end
    
            -- add GL Transaction
            insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate, DatePosted,
                Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
     	    values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, 'MS Tickets', @saledate, @dateposted,
                @desc, @batchid, @amount, 0, 'N', null, 'N')
    		if @@rowcount = 0
    			begin
                select @errmsg = 'Unable to add GL Detail entry', @rcode = 1
                goto MSGL_posting_error
                end
    --         end
    
        -- delete MS GL Distributions just posted
     	delete from bMSGL
        where MSCo = @co and Mth = @mth and BatchId = @batchid
            and GLCo = @glco and GLAcct = @glacct and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
     	if @@rowcount <> 1
            begin
            select @errmsg = 'Unable to delete GL distribution entry', @rcode = 1
            goto MSGL_posting_error
            end
    
        commit transaction
    
        goto MSGL_detail_loop
    
    MSGL_posting_error:	-- error occured within transaction - rollback any updates and exit
        rollback transaction
        goto bspexit
    
    
    MSGL_detail_end:	-- no more rows to process
        close bcMSGL
        deallocate bcMSGL
        set @openMSGL = 0
    
    
    bspexit:
        if @openMSGL = 1
            begin
     		close bcMSGL
     		deallocate bcMSGL
    		set @openMSGL = 0
     		end
    
   	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSPostGL] TO [public]
GO
