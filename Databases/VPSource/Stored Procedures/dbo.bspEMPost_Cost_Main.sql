SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************/
CREATE      procedure [dbo].[bspEMPost_Cost_Main]
/***********************************************************
* CREATED BY: JM 2/12/99
* MODIFIED By : JM 5/24/99 - Added call to bspEMPost_Cost_EMMRInserts
*               ae 9/7/99 - Added EMAlloc
*                ae 2/1/00 -- Made EMAlloc a EMAdj batch type Alloc!
*             JM 2/22/00 - Changed case statement that selects GLJrn, DetlDesc,
*             GLSumDesc and GLLvl based on Source to add qualification for
*             EMTransType for EMAdj Source; eliminated EMFuel Source. Also
*             deleted case statement that set @checktable based on Source EMFuel
*             and set TableName param for bspHQBatchProcessVal for all batches
*             to 'EMBF'.
*             danf 04/06/00 Added source EMTime
*             danf 06/26/00 Added exec foir stored procedure to update IN detail.
*	JM 8/27/01 - Ref Issue 14064. Moved deletion of batch record out of
*	bspEMPost_Cost_DetailInserts to bottom of BatchSeq loop.
*	JM 11/7/01 - Issue 15197 - Modified to eliminate loop on EMBF.Seq;
*	eliminated differentiation of GL info based on EMTransType in EMAdj
*	source batches.
*   CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*   DANF 10/09/02 - 18873 correct source from EMDepn to EMDepr.
*	 TV 02/11/04 - 23061 added isnulls
*			GF 01/25/2008 - issue #126860 remove reference to 'EMBZGrid'
*			GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*
*
*
* USAGE:
* 	Posts a validated batch of bEMBF entries, deletes
*	successfully posted bEMBF rows, clears bEMGL, bEMIN and
*	bHQCC when complete.
*
* INPUT PARAMETERS
*   	EMCo        	EM Co
*   	Month       	Month of batch
*   	BatchId     	Batch ID to validate
*      Source		    Batch Source - 'EMAdj', 'EMParts', 'EMDepr', 'EMFuel', 'EMAlloc'
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
    @source bSource,
    @errmsg varchar(255) output)
    as
    set nocount on
    declare @batchseq smallint,
    	@checktable varchar(20),
    	@gldetldesc varchar(60),
    	@gljrnl bJrnl,
    	@gllvl tinyint,
    	@glsumdesc varchar(30),
    	@hqbctablename varchar(20),
    	@OldAsset varchar(20),
    	@OldEquipment bEquip,
    	@rcode int,
    	@status tinyint,
    	@TotalDiff bDollar,
        @Notes varchar(256)
    
    select @rcode = 0
    
    /* Check for input params. */
    if @co is null
    	begin
    	select @errmsg = 'Missing Company!', @rcode = 1
    	goto bspexit
    	end
    if @mth is null
    	begin
    	select @errmsg = 'Missing Mth!', @rcode = 1
    	goto bspexit
    	end
    if @batchid is null
    	begin
    	select @errmsg = 'Missing BatchId!', @rcode = 1
    	goto bspexit
    	end
    if @dateposted is null
    	begin
    	select @errmsg = 'Missing posting date!', @rcode = 1
    	goto bspexit
    	end
    if @source is null
    	begin
    	select @errmsg = 'Missing Source!', @rcode = 1
    	goto bspexit
    	end
    
/* Validate HQ Batch. Special validation because the EMAdj Source can have multiple TableNames in HQBC. */
select @checktable = TableName from bHQBC where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0 or @checktable <> 'EMBF' -- error
	begin
	select @errmsg = 'Invalid HQBC.TableName!' + isnull(@checktable,''), @rcode = 1
	goto bspexit
	end

    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, @checktable, @errmsg output, @status output
    if @rcode <> 0 goto bspexit
    if @status <> 3 and @status <> 4 /* valid - OK to post, or posting in progress. */
    	begin
    	select @errmsg = 'Invalid Batch Status must be Valid OK to post or Posting in progress!',
                  @rcode = 1
    	goto bspexit
    	end
    /* Set HQ Batch status to 4 (posting in progress). */
    update bHQBC set Status = 4, DatePosted = @dateposted where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
    	goto bspexit
    	end
    
    /* Get GL interface info from EMCO.
    NOTE: Per Issue 15197 and RH/CM/GG, treat all EMAdj batches as AdjGL without differentiation between Fuel EMTransType vs others (as in previous code.)
    Thus all Fuel entries posted thru EMAdj will be listed as bHQBC.TableName = 'EMBF' and will go to AdjGLJrnl. Fuel entries posted thru the Fuel Posting form */
    if @source = 'EMAdj' or @source = 'EMFuel'
    	begin
    	select @hqbctablename = TableName from bHQBC where Co = @co and Mth = @mth and BatchId = @batchid
    	--if posted thru EMCostAdj form (including all EMTransTypes, ie WO, Alloc, Equip, Depn, Parts and Fuel)
    	if @hqbctablename = 'EMBF' select @gljrnl = AdjstGLJrnl, @gldetldesc = AdjstGLDetlDesc, @glsumdesc = AdjstGLSumDesc, @gllvl = AdjstGLLvl from bEMCO where EMCo = @co
    	--error
    	if @hqbctablename <> 'EMBF'
    		begin
    		select @errmsg = 'Invalid TableName in bHQBC for EMAdj Source batch!', @rcode = 1
    		goto bspexit
    		end
    	end
    else
    	begin
    	select @gljrnl = case @source
             	when 'EMAlloc' then AdjstGLJrnl
    			when 'EMDepr' then AdjstGLJrnl
    			when 'EMTime' then AdjstGLJrnl
    			when 'EMParts' then MatlGLJrnl end,
    	@gldetldesc = case @source
           		when 'EMAlloc' then AdjstGLDetlDesc
    			when 'EMDepr' then AdjstGLDetlDesc
    			when 'EMTime' then AdjstGLDetlDesc
    			when 'EMParts' then MatlGLDetlDesc end,
    	@glsumdesc = case @source
          		when 'EMAlloc' then AdjstGLSumDesc
    			when 'EMDepr' then AdjstGLSumDesc
    			when 'EMTime' then AdjstGLSumDesc
    			when 'EMParts' then MatlGLSumDesc end,
    	@gllvl = case @source
        		when 'EMAlloc' then AdjstGLLvl
    			when 'EMDepr' then AdjstGLLvl
    			when 'EMTime' then AdjstGLLvl
    			when 'EMParts' then MatlGLLvl end
    	from bEMCO where EMCo = @co
    	if @@rowcount = 0
    		begin
    		select @errmsg = 'Missing EM Company - Could not read GL interfaces!', @rcode = 1
    		goto bspexit
    		end
    	end
    
    /* ***************************************** */
    /* Insert detail records in bEMMR and bEMCD. */
    /* ***************************************** */
    exec @rcode = bspEMPost_Cost_DetailInserts @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0
    	begin
    	select @errmsg = @errmsg, @rcode = 1
    	goto bspexit
    	end
    
    /* ***************************************** */
    /* Insert detail records in bINDT.           */
    /* ***************************************** */
    exec @rcode = bspEMPost_Cost_DetailInsert_IN @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0
    	begin
    	select @errmsg = @errmsg, @rcode = 1
    	goto bspexit
    	end
    
    /* *********************************** */
    /* Update GL using entries from bEMGL. */
    /* *********************************** */
    select @gllvl, @gljrnl, @gldetldesc
    -- No update.
    if @gllvl = 0 delete bEMGL where EMCo = @co and Mth = @mth and BatchId = @batchid









    -- Summary GL Update.
    if @gllvl = 1
		begin
    	exec @rcode = bspEMPost_Cost_SummaryGLUpdate @co, @mth, @batchid, @dateposted, @source, @gljrnl, @glsumdesc, @errmsg output
    	if @rcode <> 0
    		begin
    	    select @errmsg = @errmsg, @rcode = 1
    	    goto bspexit
    	   	end
    	end

    /* ****************************************************** */
    /* Detail update to GL for everything remaining in bEMGL. */
    /* ****************************************************** */
    if (select count(*) from bEMGL where EMCo = @co and Mth = @mth and BatchId = @batchid) > 0
    	begin
    	exec @rcode = bspEMPost_Cost_DetailGLUpdate @co, @mth, @batchid, @dateposted, @source, @gljrnl, @gldetldesc, @errmsg output
    	if @rcode <> 0
    		begin
    	    select @errmsg = @errmsg, @rcode = 1
    	    goto bspexit
    	   	end
    	 end
    
    /* ************** */
    /* Close routine. */
    /* ************** */
    /* Make sure Audit tables are empty. */
    if exists(select * from bEMGL where EMCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all updates to GL were posted from bEMGL - unable to close batch!', @rcode = 1
    	goto bspexit
    	end
    if exists(select * from bEMIN where EMCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all updates to GL were posted from bEMIN - unable to close batch!', @rcode = 1
    	goto bspexit
    	end
    if exists(select * from bEMBF where Co = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not records processed in bEMBF - unable to close batch!', @rcode = 1
    	goto bspexit
    	end
    
    -- set interface levels note string
        select @Notes=Notes from bHQBC
        where Co = @co and Mth = @mth and BatchId = @batchid
        if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
        select @Notes=@Notes +
            'GL Adjustments Interface Level set at: ' + isnull(convert(char(1), a.AdjstGLLvl),'') + char(13) + char(10) +
            'GL Usage Interface Level set at: ' + isnull(convert(char(1), a.UseGLLvl),'') + char(13) + char(10) +
            'GL Parts Interface Level set at: ' + isnull(convert(char(1), a.MatlGLLvl),'') + char(13) + char(10)
        from bEMCO a where EMCo=@co
    
    /* Delete HQ Close Control entries. */
    delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
    
    /* Set HQ Batch status to 5 (posted). */
    update bHQBC set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
    where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
    	goto bspexit
    	end
    bspexit:
    	if @rcode<>0 select @errmsg=isnull(@errmsg,'')
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMPost_Cost_Main] TO [public]
GO
