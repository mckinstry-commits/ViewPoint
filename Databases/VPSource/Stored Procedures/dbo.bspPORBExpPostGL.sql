SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPORBExpPostGL    Script Date: 8/28/99 9:35:59 AM ******/
   CREATE      procedure [dbo].[bspPORBExpPostGL]
    /***********************************************************
    * CREATED BY:  DANF 04/21/01
    * MODIFIED By  DANF 08/31/01 - Issue 14506 - Check for no PO Company
    *              DANF 10/12/01 - Added is null check on APTrans
    *				DANF 05/01/02 - Added Interface levels from PORH For Initializing.
    *				GG 10/23/02 - #19107 - fix GL update
    *				DANF 02/21/03 - 20294 Added PO and POItem to update of GL Description.
    *				GF 08/11/2003 - issue #22116 - performance improvements
    * 				DANF 09/08/2003 - 22303 - Add Transaction to GL Description.
    * 				DANF 09/08/2003 - 22304 - Correct GL Description for accounts flagged for detail.
    *				DANF 09/25/03 - issue 21985 - Corrected Backingout or turning Reciept expenses.
    *				DC 6/29/10 - #135813 - expand subcontract number
    *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *				GF 08/22/2011 TK-07879 PO ITEM LINE
    *
    *
    * USAGE:
    *   Called by the main PO Receipt Entry Posting procedure (bspPORBPost)
    *   to update GL distributions for a batch of PO Receipt transactions.
    *
    * INPUT PARAMETERS
    *   @co             PO Co#
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
   (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(255) output)
   as
   set nocount on
    
declare @rcode int,  @opencursorPORG tinyint, @expjrnl bJrnl, @glexpinterfacelvl tinyint,
		@glexpsummarydesc varchar(60), @glexptransdesc varchar(60), @gljobdetaildesc varchar(60),
		@glinvdetaildesc varchar(60), @glequipdetaildesc varchar(60), @glexpdetaildesc varchar(60),
		@glref bGLRef,  @gltrans bTrans, @polinetype tinyint, @amount bDollar, @findidx tinyint,
		@found varchar(20), @seq int, @desc varchar(60), @desccontrol varchar(60), @jcco bCompany,
		@job bJob, --@sl VARCHAR(30), --bSL, @slitem bItem, DC #135813
		@po varchar(30), @poitem bItem, @phase bPhase, @jcctype bJCCType,
		@material bMatl, @oldnew tinyint, @glco bCompany, @glacct bGLAcct, @apline smallint,
		@aptrans bTrans, @transdesc bDesc,  @vendorgroup bGroup, @vendr bVendor, @sortname varchar(15),
		@invdate bDate, @apref bAPReference, @linetype tinyint, -- @linedesc bItemDesc, --bDesc, DC #135813
		@emco bCompany, @equipment bEquip, @costcode bCostCode, @emctype bEMCType, @inco bCompany, @loc bLoc,
		@totalcost bDollar, @recdate bDate, @potrans bTrans, @source bSource, @receiver# varchar(20), 
		@oldglexpinterfacelvl tinyint, @oldglexpsummarydesc varchar(60), @oldglexptransdesc varchar(60),
		@InvDesc varchar(60), @ItemTypeCheck tinyint, @SMCo bCompany, @batchseq int, @WorkOrder int, @WorkCompleted int,
		@gldetldesc varchar(60),
		----TK-07879
		@POItemLine INT
    
    select @rcode = 0, @opencursorPORG = 0
    
    -- get PO company info
    select @glexpinterfacelvl = GLRecExpInterfacelvl, 
           @glexpsummarydesc = GLRecExpSummaryDesc, 
           @glexptransdesc = GLRecExpDetailDesc
    from bPOCO with (nolock) where POCo = @co
    if @@rowcount = 0
        begin
        --- Not every one will have PO /// select @errmsg = 'Missing PO Company!', @rcode = 1
        goto bspexit
        end
    
    --   Over Ride Interface levels if Initializing Expenses from Receipts.
       select @source=Source
       from bHQBC with (nolock)
       where Co = @co and Mth = @mth and BatchId = @batchid
    
       if isnull(@source,'') = 'PO InitRec'
         begin
		 -- get PORH info
		 select @glexpinterfacelvl = GLRecExpInterfacelvl,
				  @glexpsummarydesc = GLRecExpSummaryDesc, 
				  @glexptransdesc = GLRecExpDetailDesc,
   				  @oldglexpinterfacelvl = OldGLRecExpInterfacelvl,
				  @oldglexpsummarydesc = OldGLRecExpSummaryDesc, 
				  @oldglexptransdesc = OldGLRecExpDetailDesc
		 from bPORH with (nolock)
		 where Co = @co and Mth = @mth and BatchId = @batchid
		if @@rowcount = 0
			begin
			select @errmsg = ' Missing Receipt Header for Interface levels!', @rcode = 1
			goto bspexit
			end
   
		   -- if turning off receipt expenses swith interface level to on for backing out receipt expenses
   		if @oldglexpinterfacelvl > 1 and @glexpinterfacelvl = 0 
   			begin
   			select 	@glexpinterfacelvl = @oldglexpinterfacelvl, 
   					@glexpsummarydesc = @oldglexpsummarydesc,
   					@glexptransdesc = @oldglexptransdesc
   			end   
		end
   
   -- get AP company info
   select @expjrnl = ExpJrnl, @gljobdetaildesc = GLJobDetailDesc, @glinvdetaildesc = GLInvDetailDesc,
   	   @glequipdetaildesc = GLEquipDetailDesc, @glexpdetaildesc = GLExpDetailDesc
   from bAPCO with (nolock) where APCo = @co
   if @@rowcount = 0
        begin
        select @errmsg = 'Missing AP Company!', @rcode = 1
        goto bspexit
        end
    
   -- No update to GL
   if @glexpinterfacelvl = 0
   		begin
   		delete bPORG where POCo = @co and Mth = @mth and BatchId = @batchid
   		goto bspexit
     	end
    
   -- set GL Reference using Batch Id - right justified 10 chars */
   select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)
       
   -- Summary update to GL - one entry per GL Co/GLAcct, unless GL Account flagged for detail
   if @glexpinterfacelvl = 1
   		begin
   		-- use summary level cursor on PO GL Distributions
   		declare bcPOG cursor LOCAL FAST_FORWARD
   		for select g.GLCo, g.GLAcct,(convert(numeric(12,2),sum(g.TotalCost)))
     		from bPORG g join bGLAC c with (nolock) on c.GLCo=g.GLCo and c.GLAcct=g.GLAcct
   		where g.POCo = @co and g.Mth = @mth and g.BatchId = @batchid and c.InterfaceDetail = 'N'
     	group by g.GLCo, g.GLAcct
    
   		-- open cursor
   		open bcPOG
   		select @opencursorPORG = 1
	    
   		gl_summary_posting_loop:
   		fetch next from bcPOG into @glco, @glacct, @amount
	    
   		if @@fetch_status = -1 goto gl_summary_posting_end
   		if @@fetch_status <> 0 goto gl_summary_posting_loop
	    
   		begin transaction
   		-- get next available transaction # for GL Detail
   		exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
   		if @gltrans = 0 goto gl_summary_posting_error
	    
   		-- add GL Detail
   		insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
					ActDate, DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
   		values(@glco, @mth, @gltrans, @glacct, @expjrnl, @glref, @co, 'PO Receipt',
     	 			@dateposted, @dateposted, @glexpsummarydesc, @batchid, @amount, 0, 'N', null, 'N')
   		if @@rowcount = 0 goto gl_summary_posting_error
	    
   		-- delete AP GL Distributions just posted
   		delete bPORG where POCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @glacct
	    
   		commit transaction
	    
   		goto gl_summary_posting_loop
	    
   		gl_summary_posting_error:	-- error occured within transaction - rollback any updates and continue
				rollback transaction
				goto gl_summary_posting_loop
	    
   		gl_summary_posting_end:	    -- no more rows in summary cursor
				close bcPOG
				deallocate bcPOG
				select @opencursorPORG = 0
	   
		end
    
   -- Transaction level update - one entry per GLCo/GLAcct/Trans unless GL Acct flagged for detail
   if @glexpinterfacelvl = 2
   		begin
   		-- use a transaction level cursor on AP GL Distributions
   		declare bcPOG cursor LOCAL FAST_FORWARD
   		for select g.GLCo, g.GLAcct, g.Description, g.VendorGroup, g.Vendor, g.SortName,
				g.RecDate, g.POTrans,(convert(numeric(12,2), sum(g.TotalCost))), g.PO, g.POItem,
				g.Receiver#, g.BatchSeq,
				----TK-07879
				g.POItemLine
     	from bPORG g join bGLAC c with (nolock) on c.GLCo=g.GLCo and c.GLAcct=g.GLAcct
   		where g.POCo = @co and g.Mth = @mth and g.BatchId = @batchid and c.InterfaceDetail = 'N'
     	group by g.GLCo, g.GLAcct, g.POTrans, g.Description, g.VendorGroup, g.Vendor, g.SortName,
     		g.RecDate, g.PO, g.POItem, g.Receiver#, g.BatchSeq,
     		----TK-07879
     		g.POItemLine
    
   	-- open cursor
   	open bcPOG
   	select @opencursorPORG = 1
    
   	gl_transaction_posting_loop:
   	fetch next from bcPOG into @glco, @glacct, @InvDesc, @vendorgroup, @vendr, @sortname,
                @recdate, @potrans, @amount, @po, @poitem, @receiver#, @batchseq,
                ----TK-07879
                @POItemLine
    
   	if @@fetch_status = -1 goto gl_transaction_posting_end
   	if @@fetch_status <> 0 goto gl_transaction_posting_loop
    
   	begin transaction
   	-- get next available transaction # for GLDT
   	exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
   	if @gltrans = 0 goto gl_transaction_posting_error
    
   	-- parse out the transaction description
   	select @desccontrol = isnull(rtrim(@glexptransdesc),'')
   	select @desc = ''
   	while (@desccontrol <> '')
   		begin
   		select @findidx = charindex('/',@desccontrol)
   		if @findidx = 0
   			select @found = @desccontrol, @desccontrol = ''
   		else
   			select @found = substring(@desccontrol,1,@findidx-1), @desccontrol = substring(@desccontrol,@findidx+1,60)
   
               if @found = 'InvDesc'  select @desc = @desc + '/' + @InvDesc
               if @found = 'Vendor#'  select @desc = @desc + '/' + convert(varchar(10), isnull(@vendr,''))
            	if @found = 'SortName' select @desc = @desc + '/' +  isnull(@sortname,'')
            	--if @found = 'APRef'	   select @desc = @desc + '/' +  @apref
            	if @found = 'Receiver#'  select @desc = @desc + '/' +  isnull(@receiver#,'')
            	if @found = 'ReceiptDate'  select @desc = @desc + '/' +  convert(varchar(15), @recdate, 107)
            	if @found = 'InvDate'  select @desc = @desc + '/' +  convert(varchar(15), @recdate, 107)
            	if @found = 'PO#'  select @desc = @desc + '/' +  isnull(@po,'')
            	if @found = 'POItem'  select @desc = @desc + '/' +  convert(varchar(3), isnull(@poitem,''))
            	----TK-07879
            	if @found = 'POItemLine' select @desc = @desc + '/' +  dbo.vfToString(@POItemLine)
            	if @found = 'Trans#' select @desc = @desc + '/' +  dbo.vfToString(@potrans)
   			end
   			
   		-- remove leading '/'
   		if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))
   		
   		-- add GL Transaction
   		insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
                ActDate, DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
   		values(@glco, @mth, @gltrans, @glacct, @expjrnl, @glref, @co, 'PO Receipt',
     	 	    @dateposted, @dateposted, @desc, @batchid, @amount, 0, 'N', null, 'N')
   		if @@rowcount = 0 goto gl_summary_posting_error
    
   		-- delete AP GL distributions just posted
   		delete bPORG where POCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco
   		and GLAcct = @glacct and isnull(POTrans,'') = isnull(@potrans,'')
    
   		commit transaction
    
   		goto gl_transaction_posting_loop
    
   	gl_transaction_posting_error:	-- error occured within transaction - rollback any updates and continue
            rollback transaction
            goto gl_transaction_posting_loop
    
   	gl_transaction_posting_end:	    -- no more rows to process
            close bcPOG
            deallocate bcPOG
            select @opencursorPORG = 0
   
   end
    
   -- Detail update for everything remaining in PO GL Distributions
   declare bcPOG cursor LOCAL fAST_FORWARD
   for select GLCo, GLAcct, BatchSeq, APLine, POTrans,  Description,	-- #19107 - add APLine to cursor
         VendorGroup, Vendor, SortName, RecDate, POItemType, Description,
         JCCo, Job, Phase, JCCType, EMCo, Equip, CostCode, EMCType,
         INCo, Loc, Material, TotalCost, OldNew, PO, POItem, Receiver#,
         ----TK-07879
         POItemLine
   from bPORG
   where POCo = @co and Mth = @mth and BatchId = @batchid
    
   -- open cursor
   open bcPOG
   select @opencursorPORG = 1
    
   gl_detail_posting_loop:
   fetch next from bcPOG into @glco, @glacct, @seq, @apline, @potrans, @InvDesc,	-- #19107 - add APLine to cursor
				@vendorgroup, @vendr, @sortname, @recdate, @polinetype, @InvDesc,
				@jcco, @job, @phase, @jcctype, @emco, @equipment,  @costcode, @emctype,
				@inco, @loc, @material, @totalcost, @oldnew, @po, @poitem, @receiver#,
				----TK-07879
				@POItemLine
    
   if @@fetch_status = -1 goto gl_detail_posting_end
   if @@fetch_status <> 0 goto gl_detail_posting_loop
    
   begin transaction
   -- get the proper description type for the line type
   select @linetype = @polinetype
    
   select @desccontrol = CASE @linetype
            WHEN 1 THEN rtrim(@gljobdetaildesc)      -- job
          	WHEN 2 THEN rtrim(@glinvdetaildesc)      -- inventory
          	WHEN 3 THEN rtrim(@glexptransdesc)      -- expense
          	WHEN 4 THEN rtrim(@glequipdetaildesc)    -- equipment
          	WHEN 5 THEN rtrim(@glequipdetaildesc)    -- work order - equipment
          	WHEN 7 THEN rtrim(@gljobdetaildesc)      -- subcontract - job
          	ELSE rtrim(@glexpdetaildesc)
          	END
    
   -- parse out the description
   if @desccontrol is null select  @desccontrol = isnull(rtrim(@glexpdetaildesc),'')
   if @desccontrol is null select @desccontrol='Trans#'
   select @desc = ''
   while (@desccontrol <> '')
   	begin
   	select @findidx = charindex('/',@desccontrol)
   	if @findidx = 0
   		select @found = @desccontrol, @desccontrol = ''
   	else
   		select @found=substring(@desccontrol,1,@findidx-1), @desccontrol = substring(@desccontrol,@findidx+1,60)
    
   	if @found = 'InvDesc' select @desc = @desc + '/' + @InvDesc
   	if @found = 'Vendor#' select @desc = @desc + '/' + convert(varchar(10), @vendr)
   	if @found = 'SortName' select @desc = @desc + '/' +  @sortname
   	if @found = 'RecDate' select @desc = @desc + '/' +  convert(varchar(15), @recdate, 107)
   	if @found = 'Trans#' select @desc = @desc + '/' +  convert(varchar(15), isnull(@potrans,''))
            --if @found = 'Line' select @desc = @desc + '/' +  convert(varchar(5), @apline)
            --if @found = 'LineDesc' select @desc = @desc + '/' +  @linedesc
   	if @found = 'Matl' select @desc = @desc + '/' +  @material
   	if @found = 'JCCo' select @desc = @desc + '/' +  convert(varchar(3), @jcco)
   	if @found = 'Job' select @desc = @desc + '/' +  @job
   	if @found = 'Phase' select @desc = @desc + '/' +  @phase
   	if @found = 'JCCT' select @desc = @desc + '/' +  convert(varchar(3), @jcctype)
   	if @found = 'INCo' select @desc = @desc + '/' +  convert(varchar(3), @inco)
   	if @found = 'Loc' select @desc = @desc + '/' +  @loc
   	if @found = 'EMCo' select @desc = @desc + '/' +  convert(varchar(3), @emco)
   	if @found = 'Equip' select @desc = @desc + '/' +   @equipment
   	if @found = 'CostCode' select @desc = @desc + '/' +   @costcode
   	if @found = 'EMCT' select @desc = @desc + '/' +  convert(varchar(3), @emctype)
    if @found = 'PO#'  select @desc = @desc + '/' +  isnull(@po,'')
    if @found = 'POItem'  select @desc = @desc + '/' +  convert(varchar(3), isnull(@poitem,''))
    ----TK-07879
    if @found = 'POItemLine'  select @desc = @desc + '/' +  convert(varchar(6), isnull(@POItemLine,''))
    if @found = 'Receiver#'  select @desc = @desc + '/' +  isnull(@receiver#,'')
    if @found = 'ReceiptDate'  select @desc = @desc + '/' +  convert(varchar(15), @recdate, 107)
   	end
    
   	-- remove leading '/'
   	if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))
    
   	-- get next available transaction # for GLDT
      	exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
     	if @gltrans = 0 goto gl_detail_posting_error
    
   	-- add GL Transaction
   	insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate, DatePosted,
   		Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
   	values(@glco, @mth, @gltrans, @glacct, @expjrnl, @glref, @co, 'PO Receipt', @dateposted, @dateposted,
   		@desc, @batchid, @totalcost, 0, 'N', null, 'N')
   	if @@rowcount = 0 goto gl_detail_posting_error
    
   	-- delete PO GL Distributions just posted
   	delete from bPORG where POCo = @co and Mth = @mth and BatchId = @batchid
   	and GLCo = @glco and GLAcct = @glacct and BatchSeq = @seq and APLine = @apline and OldNew = @oldnew  -- #19107 - add APLine 
     	if @@rowcount = 0 goto gl_detail_posting_error
    
   	commit transaction
    
   	goto gl_detail_posting_loop
    
   	gl_detail_posting_error:	-- error occured within transaction - rollback any updates and continue
   		rollback transaction
   		goto gl_detail_posting_loop
    
   gl_detail_posting_end:	-- no more rows to process
   	close bcPOG
   	deallocate bcPOG
   	select @opencursorPORG= 0
    
   
   bspexit:
   	if @opencursorPORG = 1
   		begin
     	close bcPOG
     	deallocate bcPOG
     	end
   
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPORBExpPostGL] TO [public]
GO
