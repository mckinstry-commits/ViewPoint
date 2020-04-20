SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMBFPostGL    Script Date: 1/17/2002 1:22:18 PM ******/
    /****** Object:  Stored Procedure dbo.bspEMBFPostGL    Script Date: 8/28/99 9:36:11 AM ******/
    CREATE      procedure [dbo].[bspEMBFPostGL]
    /***********************************************************
    * CREATED BY: bc  03/18/99
    * MODIFIED By : GG 10/07/99 Fix for null GL Description Control
    *				TV 02/11/04 - 23061 added isnulls
    *				TV 2/18/04 - 21061 Added EM Trans
    *				TV 3/1/04 - 21061 Added Convert(EMTrans,Varchar(10))
   *				TRL 02/04/2010 Issue 137916  change @description to 60 characters  
					AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
  * 
    * USAGE:
    *   Called by the main EM Posting procedures
    *   to update GL distributions for a batch of EM transactions.
    *
    * INPUT PARAMETERS
    *   @co             	EM Co#
    *   @mth            	Batch Month
    *   @batchid       Batch ID
    *   @dateposted Posting date - recorded with each GL transaction
    *   @postgltype	'Usage','Parts','Adjust'  hard coded parameter from any bsp that calls EMBFPostGL
    *		used to determine which tab to reference in the company form.
    *   @source	batch source like 'EMRev' or 'EMParts'  etc.
    *
    * OUTPUT PARAMETERS
    *   @errmsg         error message if something went wrong
    *
    * RETURN VALUE
    *   0               success
    *   1               fail
    *****************************************************/
     	(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null,
    	 @postgltype char(10), @source varchar(10), @errmsg varchar(255) output)
    as
    
    set nocount on
    
    declare @rcode int, @opencursorEMGL tinyint, @jrnl bJrnl, @gllvl tinyint,
     	@glsumdesc varchar(60), @gldetldesc varchar(60),
        	@glref bGLRef,  @gltrans bTrans, @findidx tinyint,
        	@found varchar(20), @desc varchar(60), @desccontrol varchar(60),
    	/* emgl cursor declarations */
        	@emco bCompany, @glco bCompany, @glacct bGLAcct, @seq int, @oldnew tinyint, @emtrans bTrans,
        	@equipment bEquip, @actualdate bDate, @transdesc bItemDesc/*137916*/, @emtranstype varchar(10),
         	@jcco bCompany, @job bJob, @emgroup bGroup, @costcode bCostCode, @emctype bEMCType,
    	@revcode bRevCode, @revbdowncode varchar(10), @part bMatl, @inco bCompany, @inloc bLoc,
    	@workorder bWO, @woitem bItem, @amount bDollar
    
    
    select @rcode = 0, @opencursorEMGL = 0
    
    /* check source */
    if @postgltype not in ('Usage','Parts','Adjust')
    	begin
    	select @errmsg = 'Invalid interface tab!', @rcode = 1
    	goto bspexit
    	end
    
    if @postgltype = 'Usage'
    	begin
    	  select @jrnl = UseGLJrnl, @gllvl = UseGLLvl, @glsumdesc = UseGLSumDesc, @gldetldesc = UseGLDetlDesc
    	  from bEMCO
    	  where EMCo = @co
    	end
    
    if @postgltype = 'Parts'
    	begin
    	  select @jrnl = MatlGLJrnl, @gllvl = MatlGLLvl, @glsumdesc = MatlGLSumDesc, @gldetldesc = MatlGLDetlDesc
    	  from bEMCO
    
    	  where EMCo = @co
    	end
    
    if @postgltype = 'Adjust'
    	begin
    	  select @jrnl = AdjstGLJrnl, @gllvl = AdjstGLLvl, @glsumdesc = AdjstGLSumDesc, @gldetldesc = AdjstGLDetlDesc
    	  from bEMCO
    	  where EMCo = @co
    	end
    
    
    if @gllvl is null
    	begin
    	select @errmsg = 'GL Interface level may not be null', @rcode = 1
    	goto bspexit
    	end
    
    if @jrnl is null and @gllvl > 0
    	begin
    	select @errmsg = 'Journal may not be null', @rcode = 1
    	goto bspexit
    	end
    
    /* No update to GL */
    if @gllvl = 0
        begin
        delete bEMGL where EMCo = @co and Mth = @mth and BatchId = @batchid
        goto bspexit
     	end
    
    /* set GL Reference using Batch Id - right justified 10 chars */
    select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)
    
    /* Summary update to GL - one entry per GL Co/GLAcct, unless GL Account flagged for detail */
    if @gllvl = 1
        begin
        /* use summary level cursor on EM GL Distributions */
        --#142278
        DECLARE bcEMGL CURSOR FOR
			SELECT  g.GLCo,
					g.GLAcct,
					( CONVERT(numeric(12, 2), SUM(g.Amount)) )
			FROM    dbo.bEMGL g
					JOIN dbo.bGLAC c ON c.GLCo = g.GLCo
										AND c.GLAcct = g.GLAcct
			WHERE   g.EMCo = @co
					AND g.Mth = @mth
					AND g.BatchId = @batchid
					AND c.InterfaceDetail = 'N'
			GROUP BY g.GLCo,
					g.GLAcct
	    
        /* open cursor */
        open bcEMGL
        select @opencursorEMGL = 1
    
        gl_summary_posting_loop:
            fetch next from bcEMGL into @glco, @glacct, @amount
    
            if @@fetch_status = -1 goto gl_summary_posting_end
            if @@fetch_status <> 0 goto gl_summary_posting_loop
    
            begin transaction
            /* get next available transaction # for GL Detail */
            exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
            if @gltrans = 0 goto gl_summary_posting_error
    
            /* add GL Detail */
            insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
                ActDate, DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
       	    values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, @source,
     	 	    @dateposted, @dateposted, @glsumdesc, @batchid, @amount, 0, 'N', null, 'N')
            if @@rowcount = 0 goto gl_summary_posting_error
    
            /* delete EM GL Distributions just posted */
            delete bEMGL
            where EMCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @glacct
    
            commit transaction
    
            goto gl_summary_posting_loop
    
        gl_summary_posting_error:	/* error occured within transaction - rollback any updates and continue */
            rollback transaction
            goto gl_summary_posting_loop
    
        gl_summary_posting_end:	    /* no more rows in summary cursor */
            close bcEMGL
    
            deallocate bcEMGL
            select @opencursorEMGL = 0
        end
    
    /* Detail update for everything remaining in EM GL Distributions */
    declare bcEMGL cursor for
    select EMCo, GLCo, GLAcct, BatchSeq, OldNew, EMTrans, Equipment, ActualDate,
    	   TransDesc, EMTransType, JCCo, Job, CostCode, EMCostType, RevCode, INCo, INLocation, Material,
    	   WorkOrder, WOItem, Amount
    from bEMGL
    where EMCo = @co and Mth = @mth and BatchId = @batchid
    
    /* open cursor  */
    open bcEMGL
    select @opencursorEMGL = 1
    
    gl_detail_posting_loop:
        fetch next from bcEMGL into @emco, @glco, @glacct, @seq, @oldnew, @emtrans, @equipment, @actualdate,
    	@transdesc, @emtranstype, @jcco, @job, @costcode, @emctype, @revcode, @inco, @inloc, @part,
    	@workorder, @woitem, @amount
    
        if @@fetch_status = -1 goto gl_detail_posting_end
        if @@fetch_status <> 0 goto gl_detail_posting_loop
    
        begin transaction
    
        /* get the proper description type for the trans type */
        select @desccontrol = isnull(rtrim(@gldetldesc),'')
    
        /* parse out the description */
        select @desc = ''
        while (@desccontrol <> '')
            begin
            select @findidx = charindex('/',@desccontrol)
            if @findidx = 0
                select @found = @desccontrol, @desccontrol = ''
            else
                select @found=substring(@desccontrol,1,@findidx-1), @desccontrol = substring(@desccontrol,@findidx+1,60)
    
            if @found = 'Co' select @desc = @desc + '/' + isnull(convert(varchar(2),@emco),'') 
            if @found = 'Equip' select @desc = @desc + '/' + isnull(@equipment,'')
            if @found = 'Rev Code' select @desc = @desc + '/' + isnull(@revcode,'')
            if @found = 'Usg Type' select @desc = @desc + '/' + isnull(@emtranstype,'')
            if @found = 'Job' select @desc = @desc + '/' + isnull(@job,'')
            if @found = 'Date' select @desc = @desc + '/' +  isnull(convert(varchar(15), @dateposted, 107),'')
            if @found = 'CostCode' select @desc = @desc + '/' + isnull(@costcode,'')
            if @found = 'CostType' select @desc = @desc + '/' + isnull(convert(varchar(5),@emctype),'')
            if @found = 'AdjDesc' select @desc = @desc + '/' + isnull(@transdesc,'')
            if @found = 'PartCode' select @desc = @desc + '/' + isnull(@part,'')
            if @found = 'PartDesc' select @desc = @desc + '/' + isnull(@transdesc,'')
            if @found = 'WO' select @desc = @desc + '/' + isnull(@workorder,'')
            if @found = 'WOItem' select @desc = @desc + '/' + isnull(convert(varchar(10),@woitem),'')
            if @found = 'INCo' select @desc = @desc + '/' + isnull(convert(varchar(2),@inco),'')
            if @found = 'INLoc' select @desc = @desc + '/' + isnull(convert(varchar(10),@inloc),'')
            if @found = 'EMTrans' select @desc = @desc + '/' + isnull(convert(varchar(10),@emtrans),'') --TV 2/18/04 - 21061 Added EM Trans
            end
    
         /* remove leading '/' */
         if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))
    
        /* get next available transaction # for GLDT */
    
      	exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
     	if @gltrans = 0 goto gl_detail_posting_error
    
        /* add GL Transaction */
        insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate, DatePosted,
            Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
    
     	values(@glco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, @source, @actualdate, @dateposted,
            @desc, @batchid, @amount, 0, 'N', null, 'N')
     	if @@rowcount = 0 goto gl_detail_posting_error
    
        /* delete EM GL Distributions just posted */
     	delete from bEMGL
        where EMCo = @co and Mth = @mth and BatchId = @batchid
     	  and GLCo = @glco and GLAcct = @glacct and BatchSeq = @seq and OldNew = @oldnew
     	if @@rowcount = 0 goto gl_detail_posting_error
    
        commit transaction
    
        goto gl_detail_posting_loop
    
    gl_detail_posting_error:	/* error occured within transaction - rollback any updates and continue */
        rollback transaction
        goto gl_detail_posting_loop
    
    gl_detail_posting_end:	/* no more rows to process */
    
        close bcEMGL
        deallocate bcEMGL
        select @opencursorEMGL= 0
    
    bspexit:
        if @opencursorEMGL = 1
            begin
     		close bcEMGL
     		deallocate bcEMGL
     		end
    
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMBFPostGL] TO [public]
GO
