SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPHBPostGL    Script Date: 8/28/99 9:35:59 AM ******/
    CREATE    procedure [dbo].[bspAPHBPostGL]
    /***********************************************************
    * CREATED BY: GG 12/08/98
    * MODIFIED By : GG 01/26/99
    *               GG 10/07/99 Fix for null GL Description Contol
    *               JE  02./24/00 Fix if missing GL Detail Desc
    *               GG 11/27/00 - changed datatype from bAPRef to bAPReference
    *				GG 01/03/02 - #15778 - use InvDate as ActDate in bGLDT when posting by Trans or Line\
    *               kb 10/28/2 - issue #18878 - fix double quotes
    *				GF 08/11/2003 - issue #22112 - performance improvements
    *				 MV 11/07/03 - #22955 wrapped @transdesc, @linedesc in 'isnull'
    *				ES 3/11/04 - #23061 isnull wrap
    *				GP 6/28/10 - #135813 change bSL to varchar(30)
    *				GF 08/04/2011 - TK-07143 expand PO
    * USAGE:
    *   Called by the main AP Entry Posting procedure (bspAPHBPost)
    *   to update GL distributions for a batch of AP transactions.
    *
    * INPUT PARAMETERS
    *   @co             AP Co#
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
    
    declare @rcode int,  @opencursorAPGL tinyint, @expjrnl bJrnl, @glexpinterfacelvl tinyint,
     	@glexpsummarydesc varchar(60), @glexptransdesc varchar(60), @gljobdetaildesc varchar(60),
     	@glinvdetaildesc varchar(60), @glequipdetaildesc varchar(60), @glexpdetaildesc varchar(60),
        @glref bGLRef,  @gltrans bTrans, @polinetype tinyint, @amount bDollar, @findidx tinyint,
        @found varchar(20), @seq int, @desc varchar(60), @desccontrol varchar(60), @jcco bCompany,
        @job bJob, @sl varchar(30), @slitem bItem, @po VARCHAR(30), @poitem bItem, @phase bPhase, @jcctype bJCCType,
        @material bMatl, @oldnew tinyint, @glco bCompany, @glacct bGLAcct, @apline smallint,
        @aptrans bTrans, @transdesc bDesc,  @vendorgroup bGroup, @vendr bVendor, @sortname varchar(15),
        @invdate bDate, @apref bAPReference, @linetype tinyint, @linedesc bDesc, @emco bCompany,
        @equipment bEquip, @costcode bCostCode, @emctype bEMCType, @inco bCompany, @loc bLoc, @totalcost bDollar
    
    select @rcode = 0, @opencursorAPGL = 0
    
    -- get AP company info
    select @expjrnl = ExpJrnl, @glexpinterfacelvl = GLExpInterfaceLvl, @glexpsummarydesc = GLExpSummaryDesc,
    	   @gljobdetaildesc = GLJobDetailDesc, @glinvdetaildesc = GLInvDetailDesc,
    	   @glequipdetaildesc = GLEquipDetailDesc, @glexpdetaildesc = GLExpDetailDesc, @glexptransdesc = GLExpTransDesc
    from bAPCO with (nolock) where APCo = @co
    if @@rowcount = 0
        begin
        select @errmsg = 'Missing AP Company!', @rcode = 1
        goto bspexit
        end
    
    -- No update to GL
    if @glexpinterfacelvl = 0
        begin
        delete bAPGL where APCo = @co and Mth = @mth and BatchId = @batchid
        goto bspexit
     	end
    
    -- set GL Reference using Batch Id - right justified 10 chars */
    select @glref = space(10-datalength(isnull(convert(varchar(10),@batchid), ''))) 
   		+ isnull(convert(varchar(10),@batchid), '')  --#23061
    
    -- Summary update to GL - one entry per GL Co/GLAcct, unless GL Account flagged for detail
    if @glexpinterfacelvl = 1
        begin
        -- use summary level cursor on AP GL Distributions
        declare bcAPGL cursor LOCAL FAST_FORWARD
    	for select g.GLCo, g.GLAcct,(convert(numeric(12,2),sum(g.TotalCost)))
     	from bAPGL g join bGLAC c with (nolock) on c.GLCo=g.GLCo and c.GLAcct=g.GLAcct
        where g.APCo = @co and g.Mth = @mth and g.BatchId = @batchid and c.InterfaceDetail = 'N'
     	group by g.GLCo, g.GLAcct
    
        -- open cursor
        open bcAPGL
        select @opencursorAPGL = 1
    
        gl_summary_posting_loop:
    	fetch next from bcAPGL into @glco, @glacct, @amount
   
    
    	if @@fetch_status = -1 goto gl_summary_posting_end
    	if @@fetch_status <> 0 goto gl_summary_posting_loop
    
    	begin transaction
    	-- get next available transaction # for GL Detail
    	exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
    
    	if @gltrans = 0 goto gl_summary_posting_error
    
    	-- add GL Detail
    	insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
                ActDate, DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
    	values(@glco, @mth, @gltrans, @glacct, @expjrnl, @glref, @co, 'AP Entry',
     	 	    @dateposted, @dateposted, @glexpsummarydesc, @batchid, @amount, 0, 'N', null, 'N')
    	if @@rowcount = 0 goto gl_summary_posting_error
    
    	-- delete AP GL Distributions just posted
    	delete bAPGL where APCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @glacct
    
    	commit transaction
    
    	goto gl_summary_posting_loop
    
        gl_summary_posting_error:	-- error occured within transaction - rollback any updates and continue
    		rollback transaction
            goto gl_summary_posting_loop
    
        gl_summary_posting_end:	    -- no more rows in summary cursor
            close bcAPGL
            deallocate bcAPGL
            select @opencursorAPGL = 0
    
    end
    
    
    -- Transaction level update - one entry per GLCo/GLAcct/Trans unless GL Acct flagged for detail
    if @glexpinterfacelvl = 2
        begin
        -- use a transaction level cursor on AP GL Distributions
        declare bcAPGL cursor LOCAL FAST_FORWARD
    	for select g.GLCo, g.GLAcct, g.TransDesc, g.VendorGroup, g.Vendor, g.SortName, g.APRef,
    			   g.InvDate, g.APTrans,(convert(numeric(12,2), sum(g.TotalCost)))
     	from bAPGL g join bGLAC c with (nolock) on c.GLCo=g.GLCo and c.GLAcct=g.GLAcct
        where g.APCo = @co and g.Mth = @mth and g.BatchId = @batchid and c.InterfaceDetail = 'N'
     	group by g.GLCo, g.GLAcct, g.APTrans, g.TransDesc, g.VendorGroup, g.Vendor, g.SortName, g.APRef, g.InvDate
    
        -- open cursor
        open bcAPGL
        select @opencursorAPGL = 1
    
        gl_transaction_posting_loop:
    	fetch next from bcAPGL into @glco, @glacct, @transdesc, @vendorgroup, @vendr, @sortname,
    			@apref, @invdate, @aptrans, @amount
    
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
    
    		if @found = 'InvDesc'  select @desc = isnull(@desc, '') + '/' + isnull(rtrim(@transdesc),'')
    		if @found = 'Vendor#'  select @desc = isnull(@desc, '') + '/' + isnull(convert(varchar(10), @vendr),'')  --#23061
    		if @found = 'SortName' select @desc = isnull(@desc, '') + '/' +  isnull(rtrim(@sortname),'')
    		if @found = 'APRef'    select @desc = isnull(@desc, '') + '/' +  isnull(@apref,'')
    		if @found = 'InvDate'  select @desc = isnull(@desc, '') + '/' +  isnull(convert(varchar(15), @invdate, 107), '')
    		if @found = 'Trans#'   select @desc = isnull(@desc, '') + '/' +  isnull(convert(varchar(15), @aptrans), '')
    		end
    
    	-- remove leading '/'
    	if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))
    
    	-- add GL Transaction
    	insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
                ActDate, DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
    	values(@glco, @mth, @gltrans, @glacct, @expjrnl, @glref, @co, 'AP Entry',
     	 	    @invdate, @dateposted, @desc, @batchid, @amount, 0, 'N', null, 'N')
    	if @@rowcount = 0 goto gl_summary_posting_error
    
    	-- delete AP GL distributions just posted
    	delete bAPGL where APCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco
    	and GLAcct = @glacct and APTrans = @aptrans
    
    	commit transaction
    
    	goto gl_transaction_posting_loop
    
    	gl_transaction_posting_error:	-- error occured within transaction - rollback any updates and continue
    		rollback transaction
            goto gl_transaction_posting_loop
    
        gl_transaction_posting_end:	    -- no more rows to process
            close bcAPGL
            deallocate bcAPGL
            select @opencursorAPGL = 0
    
    end
    
    -- Detail update for everything remaining in AP GL Distributions
    declare bcAPGL cursor LOCAL FAST_FORWARD
    for select GLCo, GLAcct, BatchSeq, APLine, APTrans,  TransDesc, VendorGroup, Vendor,
    		SortName, InvDate, APRef, LineType, POLineType, LineDesc, JCCo, Job, Phase, 
    		JCCType, EMCo, Equip, CostCode, EMCType, INCo, Loc, Material, TotalCost, OldNew
    from bAPGL
    where APCo = @co and Mth = @mth and BatchId = @batchid
    
    -- open cursor
    open bcAPGL
    select @opencursorAPGL = 1
    
    gl_detail_posting_loop:
    fetch next from bcAPGL into @glco, @glacct, @seq, @apline, @aptrans, @transdesc, @vendorgroup, @vendr,
    		@sortname, @invdate, @apref, @linetype, @polinetype, @linedesc, @jcco, @job, @phase, 
    		@jcctype, @emco, @equipment, @costcode, @emctype, @inco, @loc, @material, @totalcost, @oldnew
    
    if @@fetch_status = -1 goto gl_detail_posting_end
    if @@fetch_status <> 0 goto gl_detail_posting_loop
    
    begin transaction
    -- get the proper description type for the line type
    if @linetype = 6  select @linetype = @polinetype
    
    select @desccontrol = CASE @linetype
            WHEN 1 THEN rtrim(@gljobdetaildesc)     -- job
          	WHEN 2 THEN rtrim(@glinvdetaildesc)      -- inventory
          	WHEN 3 THEN rtrim(@glexpdetaildesc)      -- expense
          	WHEN 4 THEN rtrim(@glequipdetaildesc)    -- equipment
          	WHEN 5 THEN rtrim(@glequipdetaildesc)    -- work order - equipment
          	WHEN 7 THEN rtrim(@gljobdetaildesc)      -- subcontract - job
          	ELSE rtrim(@glexpdetaildesc)
          	END
    
    -- parse out the description
    if @desccontrol is null select  @desccontrol = isnull(rtrim(@glexptransdesc),'')
    if @desccontrol is null select @desccontrol='Trans#'
    select @desc = ''
    while (@desccontrol <> '')
    	begin
    	select @findidx = charindex('/',@desccontrol)
    	if @findidx = 0
    		select @found = @desccontrol, @desccontrol = ''
    	else
    		select @found=substring(@desccontrol,1,@findidx-1), @desccontrol = substring(@desccontrol,@findidx+1,60)
    
    	if @found = 'InvDesc' select @desc = isnull(@desc, '') + '/' + isnull(@transdesc,'')
    	if @found = 'Vendor#' select @desc = isnull(@desc, '') + '/' + isnull(convert(varchar(10), @vendr), '')  --#23061
    	if @found = 'SortName' select @desc = isnull(@desc, '') + '/' +  isnull(@sortname,'')
            if @found = 'APRef' select @desc = isnull(@desc, '') + '/' +  isnull(@apref, '')
            if @found = 'InvDate' select @desc = isnull(@desc, '') + '/' +  isnull(convert(varchar(15), @invdate, 107), '')
            if @found = 'Trans#' select @desc = isnull(@desc, '') + '/' +  isnull(convert(varchar(15), @aptrans), '')
            if @found = 'Line' select @desc = isnull(@desc, '') + '/' +  isnull(convert(varchar(5), @apline), '')
            if @found = 'LineDesc' select @desc = isnull(@desc, '') + '/' +  isnull(@linedesc,'')
            if @found = 'Matl' select @desc = isnull(@desc, '') + '/' +  isnull(@material, '')
            if @found = 'JCCo' select @desc = isnull(@desc, '') + '/' +  isnull(convert(varchar(3), @jcco), '')
            if @found = 'Job' select @desc = isnull(@desc, '') + '/' +  isnull(@job, '')
            if @found = 'Phase' select @desc = isnull(@desc, '') + '/' +  isnull(@phase, '')
            if @found = 'JCCT' select @desc = isnull(@desc, '') + '/' +  isnull(convert(varchar(3), @jcctype), '')
            if @found = 'INCo' select @desc = isnull(@desc, '') + '/' +  isnull(convert(varchar(3), @inco), '')
            if @found = 'Loc' select @desc = isnull(@desc, '') + '/' +  isnull(@loc, '')
            if @found = 'EMCo' select @desc = isnull(@desc, '') + '/' +  isnull(convert(varchar(3), @emco), '')
            if @found = 'Equip' select @desc = isnull(@desc, '') + '/' +   isnull(@equipment, '')
            if @found = 'CostCode' select @desc = isnull(@desc, '') + '/' +   isnull(@costcode, '')
            if @found = 'EMCT' select @desc = isnull(@desc, '') + '/' +  isnull(convert(varchar(3), @emctype), '')
    	end
    
    -- remove leading '/'
    if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))
    
    -- get next available transaction # for GLDT
    exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
    if @gltrans = 0 goto gl_detail_posting_error
    
    -- add GL Transaction
    insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate, DatePosted,
            Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
    values(@glco, @mth, @gltrans, @glacct, @expjrnl, @glref, @co, 'AP Entry', @invdate, @dateposted,
            @desc, @batchid, @totalcost, 0, 'N', null, 'N')
    if @@rowcount = 0 goto gl_detail_posting_error
    
    -- delete AP GL Distributions just posted
    delete from bAPGL where APCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco 
    and GLAcct = @glacct and BatchSeq = @seq and APLine = @apline and OldNew = @oldnew
    if @@rowcount = 0 goto gl_detail_posting_error
    
    commit transaction
    
    goto gl_detail_posting_loop
    
    gl_detail_posting_error:	-- error occured within transaction - rollback any updates and continue
    	rollback transaction
        goto gl_detail_posting_loop
    
    gl_detail_posting_end:	-- no more rows to process
        close bcAPGL
        deallocate bcAPGL
        select @opencursorAPGL= 0
    
    
    
    
    bspexit:
    	if @opencursorAPGL = 1
    		begin
     		close bcAPGL
     		deallocate bcAPGL
     		end
    
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPHBPostGL] TO [public]
GO
