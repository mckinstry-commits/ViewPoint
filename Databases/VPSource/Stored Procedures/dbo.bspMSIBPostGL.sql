SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
   CREATE  procedure [dbo].[bspMSIBPostGL]
   /***********************************************************
     * Created: GG 12/04/00
     * Modified:GG 05/30/01 - added @@rowcount check after bGLDT insert
     *			GF 07/29/2003 - issue #21933 - speed improvements
     *			GF 12/03/2003 - issue #23139 - added GLTrans to MSIG for rowset update.
    *			GF 06/14/2004 - #24827 - not using correct GLCo when getting next trans from bHQTC.
    *			GF 08/15/2012 TK-17067 expand GL Description Column to 90 characters
     *
     *
     * Called from the bspMSIBPost procedure to post GL distributions
     * tracked in bMSIG for Invoice batches.
     *
     * Sign on values in 'old' entries has already been reversed.
     *
     * GL Interface Levels:
     *	0      No update
     *	1      Summarize entries by GLCo#/GL Account
     *  2      Full detail
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
    (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(255) output)
    as
    set nocount on
    
    declare @rcode int,  @openMSIG tinyint, @jrnl bJrnl, @glinvlvl tinyint, @glinvsummarydesc varchar(60),
			----TK-17067
        	@glinvdetaildesc varchar(60),
        	@glref bGLRef,  @gltrans bTrans, @amount bDollar, @findidx tinyint,
        	@found varchar(20), @seq int, @desc varchar(60), @desccontrol varchar(60), @glco bCompany,
        	@glacct bGLAcct, @msg varchar(255), @msinv varchar(10), @custgroup bGroup, @customer bCustomer,
        	@custjob varchar(20), @custpo varchar(20), @description bDesc, @invdate bDate, @sortname bSortName,
    		@msgl_count bTrans, @msgl_trans bTrans, @openMSIGTrans tinyint
    
    select @rcode = 0, @openMSIG = 0, @openMSIGTrans = 0
    
    -- get MS company info
    select @jrnl = Jrnl, @glinvlvl = GLInvLvl, @glinvsummarydesc = GLInvSummaryDesc,
           @glinvdetaildesc = GLInvDetailDesc
    from bMSCO with (nolock) where MSCo = @co
    if @@rowcount = 0
        begin
        select @errmsg = 'Missing MS Company!', @rcode = 1
        goto bspexit
        end
    if @glinvlvl not in (0,1,2)
        begin
        select @errmsg = 'Invalid GL Invoice Interface level assigned in MS Company.', @rcode = 1
        goto bspexit
        end
    
    -- Post General Ledger distributions 
    
    -- No update to GL
    if @glinvlvl = 0
        begin
        delete bMSIG where MSCo = @co and Mth = @mth and BatchId = @batchid
        goto bspexit
      	end
    
    -- set GL Reference using Batch Id - right justified 10 chars */
    select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)
    
    -- Summary update to GL - one entry per GLCo#/GLAcct, unless GL Account flagged for detail
    if @glinvlvl = 1
        begin
        -- use summary level cursor on GL Distributions
        declare bcMSIG cursor LOCAL FAST_FORWARD for
        select g.GLCo, g.GLAcct,(convert(numeric(12,2),sum(g.Amount)))
      	from bMSIG g with (nolock) 
        join bGLAC c with (nolock) on c.GLCo = g.GLCo and c.GLAcct = g.GLAcct
        where g.MSCo = @co and g.Mth = @mth and g.BatchId = @batchid
             and c.InterfaceDetail = 'N'
      	group by g.GLCo, g.GLAcct
    
        -- open cursor
        open bcMSIG
        select @openMSIG = 1
    
        MSIG_summary_loop:
            fetch next from bcMSIG into @glco, @glacct, @amount
    
            if @@fetch_status = -1 goto MSIG_summary_end
            if @@fetch_status <> 0 goto MSIG_summary_loop
    
            begin transaction
    
            if @amount <> 0
                begin
                -- get next available transaction # for GL Detail
                exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @msg output
                if @gltrans = 0
                    begin
        	        select @errmsg = 'Unable to update GL Detail.  ' + isnull(@msg,'')
                    goto MSIG_posting_error
            	end
    
                -- add GL Detail
                insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
                    ActDate, DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
        	    values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, 'MS Invoice',
      	 			@dateposted, @dateposted, @glinvsummarydesc, @batchid, @amount, 0, 'N', null, 'N')
                if @@rowcount = 0
    				begin
                    select @errmsg = 'Unable to add GL Detail entry', @rcode = 1
                	goto MSIG_posting_error
                	end
    	    	end
    
             -- delete MSIG Distributions just posted
             delete bMSIG
             where MSCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @glacct
    
             commit transaction
    
             goto MSIG_summary_loop
    
          MSIG_summary_end:	    -- no more rows in summary cursor
             close bcMSIG
             deallocate bcMSIG
             select @openMSIG = 0
         end
    
   
    -- Detail update for everything remaining in MS Invoice GL Distributions
    -- delete MSIG distributions where Amount equal zero. Not sent to GLDT.
    delete bMSIG where MSCo = @co and Mth = @mth and BatchId = @batchid and Amount = 0
   
   
   -- need cursor on bMSIG for each distinct GLCo
   declare bcMSIGTrans cursor LOCAL FAST_FORWARD for select distinct(GLCo)
   from bMSIG where MSCo = @co and Mth = @mth and BatchId = @batchid
   group by GLCo
   
   --open cursor
   open bcMSIGTrans
   select @openMSIGTrans = 1
   
   MSIGTrans_loop:
   fetch next from bcMSIGTrans into @glco
   if @@fetch_status = -1 goto MSIGTrans_end
   if @@fetch_status <> 0 goto MSIGTrans_loop
   
   -- get count of bMSIG rows that need a GLTrans
   select @msgl_count = count(*) from bMSIG
   where MSCo=@co and Mth=@mth and BatchId=@batchid and GLTrans is null and GLCo=@glco
   -- only update HQTC and MSIG if there are MSIG rows that need updating
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
      	
    	-- update bMSIG and set GLTrans
    	update bMSIG set @msgl_trans = @msgl_trans + 1, GLTrans = @msgl_trans
    	where MSCo=@co and Mth=@mth and BatchId=@batchid and GLTrans is null and GLCo=@glco
    	-- compare count from update with MSGL rows that need to be updated
    	if @@rowcount <> @msgl_count
    		begin
    		select @errmsg = 'Error has occurred updating GLTrans in MSIG distribution table!', @rcode = 1
    		goto bspexit
    		end
    	end
   
   goto MSIGTrans_loop
   
   MSIGTrans_end:
   	if @openMSIGTrans = 1
   		begin
   		close bcMSIGTrans
   		deallocate bcMSIGTrans
   		set @openMSIGTrans = 0
   		end
   
   
   
   
    
    -- use detail level cursor on MS GL Distributions
    declare bcMSIG cursor LOCAL FAST_FORWARD for
    select GLCo, GLAcct, BatchSeq, MSInv, CustGroup, Customer, CustJob, CustPO,
           Description, InvDate, Amount, GLTrans
    from bMSIG
    where MSCo = @co and Mth = @mth and BatchId = @batchid
    
    -- open cursor
    open bcMSIG
    select @openMSIG = 1
    
    MSIG_detail_loop:
        fetch next from bcMSIG into @glco, @glacct, @seq, @msinv, @custgroup, @customer, @custjob,
            @custpo, @description, @invdate, @amount, @gltrans
    
        if @@fetch_status = -1 goto MSIG_detail_end
        if @@fetch_status <> 0 goto MSIG_detail_loop
    
        -- get Customer Sort Name
        select @sortname = 'Missing'
        select @sortname = SortName
        from bARCM with (nolock) where CustGroup = @custgroup and Customer = @customer
    
        -- parse out the description
        select @desccontrol = rtrim(@glinvdetaildesc)
        if @desccontrol is null select @desccontrol = 'Invoice#'
        select @desc = ''
    
        while (@desccontrol <> '')
            begin
            select @findidx = charindex('/',@desccontrol)
            if @findidx = 0
                 select @found = @desccontrol, @desccontrol = ''
            else
                 select @found = substring(@desccontrol,1,@findidx-1), @desccontrol = substring(@desccontrol,@findidx+1,60)
    
            -- hardcoded fields selected in MS Company
            if @found = 'Invoice#' select @desc = @desc + '/' + convert(varchar(10),isnull(@msinv,''))
          	if @found = 'Customer#' select @desc = @desc + '/' + convert(varchar(6),isnull(@customer,''))
            if @found = 'SortName' select @desc = @desc + '/' +  isnull(@sortname,'')
            if @found = 'CustJob' select @desc = @desc + '/' +  isnull(@custjob,'')
            if @found = 'CustPO' select @desc = @desc + '/' +  isnull(@custpo,'')
            if @found = 'Description' select @desc = @desc + '/' +  isnull(@description,'')
            if @found = 'InvDate' select @desc = @desc + '/' +  convert(varchar(8),@invdate,1)
            end
    
          -- remove leading '/'
          if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))
    
          begin transaction
    
    --       if @amount <> 0
    --          begin
    --          -- get next available transaction # for GLDT
    --    	    exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
    --   	    if @gltrans = 0
    --              begin
    --     	     select @errmsg = 'Unable to update GL Detail.  ' + @msg, @rcode = 1
    --              goto MSIG_posting_error
    --         	 end
    
             -- add GL Transaction
             insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate, DatePosted,
                 Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
      	     values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, 'MS Invoice', @invdate, @dateposted,
                 @desc, @batchid, @amount, 0, 'N', null, 'N')
    	 	 if @@rowcount = 0
    			begin
                select @errmsg = 'Unable to add GL Detail entry', @rcode = 1
                goto MSIG_posting_error
                end
    --          end
    
    	-- delete MS Invoice GL Distributions just posted
    	delete from bMSIG
        where MSCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @glacct and BatchSeq = @seq
      	if @@rowcount <> 1
             begin
             select @errmsg = 'Unable to delete GL distribution entry'
             goto MSIG_posting_error
             end
    
         commit transaction
    
         goto MSIG_detail_loop
    
    MSIG_posting_error:	-- error occured within transaction - rollback any updates and exit
         rollback transaction
         select @rcode = 1
         goto bspexit
    
    MSIG_detail_end:	-- no more rows to process
         close bcMSIG
         deallocate bcMSIG
         set @openMSIG = 0
    
    bspexit:
    	if @openMSIG = 1
            begin
      		close bcMSIG
      		deallocate bcMSIG
    		set @openMSIG = 0
      		end
    
    	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSIBPostGL] TO [public]
GO
