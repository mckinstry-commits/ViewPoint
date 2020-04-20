SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE            procedure [dbo].[bspEMPost_Cost_DetailGLUpdate]
     /***********************************************************
      * CREATED BY: JM 2/12/99
      * MODIFIED By : 4/14/99 - Broken out of main posting procedure as a
      *		sub-procedure.
      *          GG 10/07/99 Fix null GL Description Control
      *          DANF 05/02/00 Do Not added GL detail with zero amounts
      *			 TV 02/11/04 - 23061 added isnulls
      *			 TV 2/18/04 - 21061 Added EM Trans
      *			 TV 3/1/04 - 21061 Added Convert(EMTrans,Varchar(10))
      *			 TV 3/1/04 - 21061 Added Search of EMCD when EMtrans is null form EMGL
      *			 TV 11/24/04 26305 - EM Cost Adjustment batch GL posting taking over an hour for 10,000 records
     *				TRL 02/04/2010 Issue 137916  change @description to 60 characters 
     * 
      * USAGE:
      *	Called by bspEMPost_Cost_Main to write Detail GL Descriptions
      *	to GLDT where applicable.
      *
      * INPUT PARAMETERS
      *   	EMCo        	EM Co
      *   	Month       	Month of batch
      *   	BatchId     	Batch ID to validate
      *	Source		Batch Source - 'EMAdj', 'EMParts', 'EMDepr'
      *	GLJrnl		GL Journal
      *	GLDetailDesc Detail GL Description
      *   	PostingDate 	Posting date to write out if successful
      *
      * OUTPUT PARAMETERS
      *   	@errmsg     	If something went wrong
      *
      * RETURN VALUE
      *   	0   		Success
      *   	1   		fail
      *****************************************************/
     (@co bCompany,
     @mth bMonth,
     @batchid bBatchID,
     @dateposted bDate = null,
     @source bSource = null,
     @gljrnl bJrnl = null,
     @gldetldesc varchar(60) = null,
     @errmsg varchar(255) output)
     
     as
     
     set nocount on
     
     declare @actualdate bDate,
     	@amount bDollar,
     	@asset varchar(20),
     	@batchseq int,
     	@costcode bCostCode,
     	@desc varchar(60),
     	@desccontrol varchar(60),
     	@description bTransDesc,
     	@emcosttype bEMCType,
     	@equipment bEquip,
     	@findidx int,
     	@found varchar(30),
     	@glacct bGLAcct,
     	@glco bCompany,
     	@glref bGLRef,
     	@gltrans bTrans,
     	@inlocation bLoc,
     	@material bMatl,
     	@oldnew tinyint,
     	@rcode int,
     	@transdesc bItemDesc/*137916*/,
     	@woitem bItem,
     	@workorder bWO, 
        @emtrans bTrans
     
     select @rcode = 0
     
     /* Set GL Reference using BatchId - right justified 10 chars. */
     select @glref = space(10-datalength(convert(varchar(10),@batchid))) +
     	convert(varchar(10),@batchid)
     
     /* Spin through each GLCo. */
     select @glco=min(GLCo)
     from bEMGL
     where EMCo = @co and Mth = @mth and BatchId = @batchid
    
     while @glco is not null
     	begin
     	/* Spin through each acct. */
     	select @glacct=min(GLAcct)
     	from bEMGL
     	where EMCo = @co and Mth = @mth and BatchId = @batchid and GLCo=@glco
     
     	while @glacct is not null
     		begin
     		/* Spin through each BatchSeq. */
     		select @batchseq=min(BatchSeq)
     		from bEMGL
     		where EMCo = @co and Mth = @mth	and BatchId = @batchid
     			and GLCo=@glco and GLAcct=@glacct
     
     		while @batchseq is not null
     			begin
     			/* Spin through each OldNew. */
     
     			select @oldnew=min(OldNew)
     			from bEMGL
     			where EMCo = @co and Mth = @mth and BatchId = @batchid
     				and GLCo=@glco and GLAcct=@glacct and BatchSeq=@batchseq
     			while @oldnew is not null
     				begin
     				/* Read record. */
     				select  @equipment = Equipment,
     					@actualdate = ActualDate,
     					@transdesc = TransDesc,
     					@source = Source,
     					@costcode = CostCode,
     					@emcosttype = EMCostType,
     					@inlocation = INLocation,
     					@material = Material,
     					@workorder = WorkOrder,
     					@woitem = WOItem,
     					@amount = Amount,
                        @emtrans = EMTrans
     				from bEMGL
     				where EMCo = @co and Mth = @mth and BatchId = @batchid
     					and GLCo=@glco and GLAcct=@glacct and BatchSeq=@batchseq
     					and @oldnew=OldNew
   			
   				--if this is an add transaction, EMGL does not have the EMtrans yet.
   				--TV 3/1/04 - 21061 Added Search of EMCD when EMtrans is null form EMGL
   				--TV 11/24/04 26305 - EM Cost Adjustment batch GL posting taking over an hour for 10,000 records
   				/*if isnull(@emtrans,'') = ''
   					begin
   					select @emtrans = EMTrans
   					from bEMCD where EMCo = @co and Mth = @mth and BatchId = @batchid 
     					end */
   
   
     				BEGIN TRANSACTION
     
     				if @source = 'EMDepr' /* Hard code the description string -
     					no user choice in VB EMCo form. */
     					begin
     					select @desc = isnull(@asset,'') + '/' + isnull(@equipment,'')
     					end
     				else
     					begin
     					/* Parse out the description. */
     					select @desccontrol = isnull(rtrim(@gldetldesc),'')
     					select @desc = ''
     					while (@desccontrol <> '')
     						begin
   
     						select @findidx = charindex('/',@desccontrol)
     
     						if @findidx = 0
     							begin
     							select @found = @desccontrol
     							select @desccontrol = ''
     							end
     						else
    
     							begin
     							select @found=substring(@desccontrol,1,@findidx-1)
     							select @desccontrol = substring(@desccontrol,@findidx+1,60)
     							end
     						if @found = 'Co'
     							select @desc = isnull(@desc,'') + '/' + isnull(convert(varchar(3),@co),'')
     						if @found = 'Equip'
     							select @desc = isnull(@desc,'') + '/' + isnull(@equipment,'')
     						if @found = 'CostCode'
     							select @desc = isnull(@desc,'') + '/' + isnull(@costcode,'')
     						if @found = 'CostType'
     							select @desc = isnull(@desc,'') + '/' + isnull(convert(varchar(3),@emcosttype),'')
     						if @found = 'AdjDesc'
     							select @desc = isnull(@desc,'') + '/' + isnull(@transdesc,'')
     						if @found = 'PartCode'
     							select @desc = isnull(@desc,'') + '/' + isnull(@material,'')
     						if @found = 'PartDesc'
     							select @desc = isnull(@desc,'') + '/' + isnull(@transdesc,'')
     						if @found = 'WO'
     							select @desc = isnull(@desc,'') + '/' + isnull(@workorder,'')
     						if @found = 'WOItem'
     							select @desc = isnull(@desc,'') + '/' + isnull(convert(varchar(5),@woitem),'')
     						if @found = 'INLoc'
     							select @desc = isnull(@desc,'') + '/' + isnull(@inlocation,'')
                            if @found = 'EMTrans'--TV 2/18/04 - 21061 Added EM Trans
     							select @desc = isnull(@desc,'') + '/' + isnull(convert(Varchar(10),@emtrans),'')
     						end
     				end
     
     				/* Get next available transaction # for GLDT. */
     				exec @gltrans = dbo.bspHQTCNextTrans 'bGLDT', @glco, @mth, @errmsg output
     				if @gltrans = 0 /* Rollback any updates and get next OldNew. */
     		          			begin
     		           			ROLLBACK TRANSACTION
     		           			goto get_next_oldnew
     		           			end
     				else
     					begin
     				             If @amount <>0
                         					begin
     						insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef,
     							SourceCo, Source,ActDate, DatePosted, Description,
     							BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
     						values(@glco, @mth, @gltrans, @glacct, @gljrnl, @glref,
     							@co, @source, @actualdate, @dateposted, @desc, @batchid,
     							@amount, 0,'N', null, 'N')
     						if @@rowcount = 0 /* Rollback any updates and get next OldNew. */
     			          				begin
     			           				ROLLBACK TRANSACTION
     			           				goto get_next_oldnew
     			           				end
     						else
     							begin
     							/* Delete from batch if posted and commit transaction. */
     							delete from bEMGL
     							where EMCo = @co and Mth = @mth	and BatchId = @batchid
     								and GLCo=@glco and GLAcct=@glacct
     								and BatchSeq=@batchseq and @oldnew=OldNew
     							COMMIT TRANSACTION
     							end
                          					end
     	                     			else
                             					begin
                 		    				/* Delete from batch if posted and commit transaction. */
     						delete from bEMGL
     						where EMCo = @co and Mth = @mth and BatchId = @batchid
     							and GLCo=@glco and GLAcct=@glacct
     							and BatchSeq=@batchseq and @oldnew=OldNew
     						COMMIT TRANSACTION
     						end
     					end
     
     get_next_oldnew:
     				select @oldnew=min(OldNew)
     				from bEMGL
     				where EMCo = @co and Mth = @mth and BatchId = @batchid and GLCo=@glco
     					and GLAcct=@glacct and BatchSeq=@batchseq and OldNew>@oldnew
     				end /* OldNews */
     
     			select @batchseq=min(BatchSeq)
     
     			from bEMGL
     			where EMCo = @co and Mth = @mth and BatchId = @batchid and GLCo=@glco
     				and GLAcct=@glacct and BatchSeq>@batchseq
     			end /* BatchSeqs */
     
     		select @glacct=min(GLAcct)
     		from bEMGL
     		where EMCo = @co and Mth = @mth	and BatchId = @batchid and GLCo=@glco and GLAcct>@glacct
     		end /* GLAccts */
     
     	select @glco=min(GLCo)
     	from bEMGL
     	where EMCo = @co and Mth = @mth	and BatchId = @batchid and GLCo>@glco
     	end /* GLCos */
     
     bspexit:
     	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMPost_Cost_DetailGLUpdate]'
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMPost_Cost_DetailGLUpdate] TO [public]
GO
