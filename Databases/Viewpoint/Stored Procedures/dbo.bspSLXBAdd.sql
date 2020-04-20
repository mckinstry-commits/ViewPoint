SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLXBAdd    Script Date: 8/28/99 9:35:47 AM ******/
    CREATE       proc [dbo].[bspSLXBAdd]        
    /***********************************************************
     * CREATED BY: kf 5/27/97
     * MODIFIED By : kb 6/19/98
     * MODIFIED By : ae 6/6/99
     *				:MV 07/01/04 - #24931 - improve error msgs returned.
     *				DANF 03/15/05 - #27294 - Remove scrollable cursor.
     *				DC 10/10/06 - 6.x Recode SLClose - Previously this sp would return 5 if
     *					"'One or more SLs have remaining units or costs and were not added to the SL Close Batch.'"
     *					with 6.x we use VCSReturnCode 7 to = SuccessConditional.  I thought it would make more sense
     *					to change this sp to return 7 instead of 5.
	 *				DC 5/14/07 - #27685 Should not include any SL where SLHD.Status = 2 or 3. 
	*				DC 1/16/08 - #123724  Closing out of batch after validating leaves entry in SLXA
	*				DC 7/30/08 - #128435  Add SL Taxes to grid
	*				TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
	*				DC 6/29/10 - #135813 - expand subcontract number
     *
     * USAGE:
     * creates SLXB entries
     * an error is returned if any goes wrong.
     *
     *  INPUT PARAMETERS
     *
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
    (@co bCompany, @mth bMonth, @batchid bBatchID, @getjcco bCompany, @getjob bJob,
    	@beginSL VARCHAR(30), --bSL, DC #135813
    	@endSL VARCHAR(30), --bSL, DC #135813
    	@addordelete char(1), @remflag bYN, @closedate bDate,
    	@msg varchar(200) output)
    as
    set nocount on
    
    declare @rcode int, @id int, @seq int, @opencursor tinyint, @vendor bVendor, @jcco bCompany, @job bJob,
    	@SL VARCHAR(30), @vendorgroup bGroup, @curcost bDollar, @description bItemDesc, --bDesc,  DC #135813
    	@invcost bDollar,
    	@remcost bDollar, @status tinyint,
		@curtax bDollar, @invtax bDollar  --DC #128438

    if @endSL is null select @endSL='~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'  --DC #135813
    if @beginSL is null select @beginSL=''
    
    if @addordelete='D'
    	begin
    		delete from bSLXB where Co=@co and Mth=@mth and BatchId=@batchid
			delete from bSLXA where SLCo=@co and Mth=@mth and BatchId=@batchid  --123724
    	goto bspexit
    	end
    
    if @addordelete='R'
    	begin
    		delete from bSLXB where Co=@co and Mth=@mth and BatchId=@batchid and SL>=@beginSL and SL<=@endSL
			delete from bSLXA where SLCo=@co and Mth=@mth and BatchId=@batchid and SL>=@beginSL and SL<=@endSL --123724
    	goto bspexit
    	end
    /* set open cursor flag to false */
    select @opencursor = 0
    
    select @rcode = 0
    select @remcost=0
    select @rcode=1
    declare bcSLXB cursor local fast_forward for select SLHD.SL, SLHD.VendorGroup, SLHD.Vendor,SLHD.Description,
    	SLHD.JCCo, SLHD.Job , isnull(convert(numeric(12,2),sum(SLIT.CurCost)),0),
    	isnull(convert(numeric(12,2),sum(SLIT.InvCost)),0), SLHD.Status, 
		isnull(convert(numeric(12,2),sum(SLIT.CurTax)),0), isnull(convert(numeric(12,2),sum(SLIT.InvTax)),0)  --DC #128435
		from SLHD WITH (NOLOCK)
    	left join SLIT on SLIT.SLCo=SLHD.SLCo and SLIT.SL=SLHD.SL
    	where SLHD.JCCo in (select distinct Case when @getjcco is null then SLHD.JCCo else @getjcco end from SLHD) and
    	SLHD.Job in (select distinct Case when @getjob is null then SLHD.Job else @getjob end from SLHD) and
    	SLHD.SL>=@beginSL and SLHD.SL<=@endSL and SLHD.SLCo=@co and SLHD.Status not in(2,3) and SLHD.InUseBatchId is null and
    	SLHD.InUseMth is null and SLHD.MthClosed is null
    	group by SLHD.SL, SLHD.VendorGroup, SLHD.Vendor, SLHD.SL, SLHD.Description, SLHD.JCCo, SLHD.Job, SLHD.Status
    
    /* open cursor */
    open bcSLXB
    
    /* set open cursor flag to true */
    select @opencursor = 1
    
    /* get first row */
    fetch next from bcSLXB into @SL, @vendorgroup, @vendor, @description, @jcco, @job, @curcost, @invcost, @status, 
		@curtax, @invtax  --DC #128435
    
    /* loop through all rows */
    
    while (@@fetch_status = 0)
    	begin
    	if @rcode = 1 select @rcode=0
    	--#24931
    	if @remflag='N' and @curcost-@invcost<>0 and @status=0
    		begin	
    		select @msg='One or more SLs have remaining units or costs and were not added to the SL Close Batch.', @rcode=7
    		goto GetNext
    		end
    -- 	if @remflag='N' and @curcost-@invcost<>0 and @status=0 goto GetNext
    
    	select @seq = isnull(max(BatchSeq),0)+1 from bSLXB where Co = @co and Mth = @mth and
    		BatchId = @batchid
    
    	insert bSLXB (Co,Mth,BatchId,BatchSeq,SL,VendorGroup,Vendor,Description,JCCo,Job,RemainCost,CloseDate)
    	values(@co,@mth,@batchid,@seq,@SL,@vendorgroup,@vendor,@description,@jcco,@job,
			(@curcost-@invcost)+(isnull(@curtax,0)-isnull(@invtax,0)), --DC #128435
			@closedate)
    
    	GetNext:
    	fetch next from bcSLXB into @SL, @vendorgroup, @vendor, @description, @jcco, @job, @curcost, @invcost, @status,
			@curtax, @invtax  --DC #128435
    
    	end
    
    bspexit:
    	if @opencursor = 1
    		begin
    		close bcSLXB
    
    		deallocate bcSLXB
    		end
    
    	if @rcode=1 select @msg='SLs may be in use or closed. Unable to add to SL Close Batch.'	--#24931
    
    	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspSLXBAdd] TO [public]
GO
