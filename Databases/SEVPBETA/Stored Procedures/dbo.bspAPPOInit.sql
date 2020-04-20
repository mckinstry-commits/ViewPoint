SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPOInit    Script Date: 8/28/99 9:36:02 AM ******/    
   CREATE proc [dbo].[bspAPPOInit]
    /***********************************************************
    * CREATED BY: sae 7/29/97
    * MODIFIED BY: GG 5/24/99
    *			TV 05/30/01 -Was not passing Post date to get Taxcode	added @postDate
    *           DANF 12/04/01 - Corrected in use by batch check
    *			SR 08/22/02 - issue 18277 - check PO compliance
    *			GG 09/20/02 - #18522 ANSI nulls
    *		    MV 10/08/02 = #18694 -suppress the tax message
    *			MV 12/18/02 - #19670 - pull in CompType and Component for Equip type.
    *			MV 02/11/03 - #20344 - check ExpDate against InvDate from batch header.
    *			DANF 03/04/03 - #20439 - Allow a po to be initialized more than once in the same batch.
    *			kb 4/24/3 - issue #19163
    *			MV 05/15/03 - #18763 - PayType from bPOIT, set POPayTypeYN flag
    *			kb 5/27/3 - issue #19163
    *			MV 12/23/03 - #23398 add parens to bPOIT select to correct logic
    *			MV 02/06/04 - #18769 - PayCategory from bPOIT
    *			MV 03/02/04 - #23061 - isnull wrap / performance enhancements
    *			MV 05/26/04 - #24682 - insert VendorGroup into bAPLB
    *			MV 08/20/04 - #17820 - Init POs in Unapproved
    *			MV 10/27/04 - #25714 - back out OldUnits, OldGrossAmt from batch units,amounts
    *			MV 01/14/05 - #26296 - save off po compliance msg and return it if po out of compliance
    *			MV 01/27/05 - #26482 - truncate 60 char POIT description to 30 char for insert to APLB
 	*			MV 01/25/06 - #120036 - return PO Comp msg if rcode <> 1 
	*			MV 10/11/06 - #122407 - return PO Item number in null GL Acct err message
    *			MV 02/16/07 - #123805 - corrected default GLAcct process
	*			MV 03/06/08 - #126640 - always return warning if PO glacct <> JOb glacct
	*			MV 09/11/08 - #129788 - taxbasis shld be 0 if there is no taxcode on the PO  
	*			DC 11/10/08 - #130833 - add the 'Supplier' field to the PO Entry form
	*			MV 12/03/08 - #131245 - use PO payterms to get disc rate
	*			MV 02/03/09 - #132114 - include bAPTL when getting next Line# for bAPLB insert
	*			MV 04/08/09 - #131822 - default APUI header ReviewerGroup to APUL lines
	*			ECV 05/25/11 - TK-05443 - Add SMPayType parameter to bspAPPayTypeGet
	*			MV 05/26/11 - #144000 - default ReviewerGroup based on POItem Type 
	*			TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
	*			MV 08/18/11 - TK-07738 - AP project to use POItemLine - replaced pseudo cursor with real cursor selecting on POItemLine
	*			MV 09/19/11 - TK-08578 - exclude where POItem is inuse.
	*			CJG 6/19/12 - TK-15750 - Add SM data to POItem (bAPLB)
	*
	* USAGE:
    * Called by AP Invoice Entry program to initialize a new batch entry
    * based on a selected Purchase Order.
    *
    * INPUTS:
    *    @co         AP Company
    *    @month      Batch month - expense month
    *    @batchid    BatchID
    *    @seq        Sequence # within batch to add new entries to
    *    @po         Purchase order to pull items from.
    *
    * OUTPUT:
    *    @msg        Error message
    *
    * RETURN:
    *    0           Success
    *    1           Failure
    *
    *******************************************************************/
	(@co bCompany = 0, @month bMonth, @batchid integer, @seq integer,
	@po varchar(30), @posteddate bDate = null, @userid bVPUserName, @complied bYN output,
	@msg varchar(255) output)
   	 
     as
    
     set nocount on
    
     declare @rcode int, @numrows int, @poco bCompany, @aplinetype tinyint, @apline int, @poitem bItem,
     @itemtype tinyint, @recyn bYN, @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType,
     @emco bCompany, @wo bWO, @woitem bItem, @equip bEquip, @emgroup bGroup, @costcode bCostCode, @emctype bEMCType,
     @hqsource bSource, @inco bCompany, @loc bLoc, @matlgroup bGroup, @material bMatl, @glco bCompany, @glacct bGLAcct,
     @description bDesc /*@linedesc*/, @um bUM, @units bUnits, @unitcost bUnitCost, @ecm bECM, @paytype tinyint, @grossamt bDollar,
     @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @taxrate bRate, @recvdunits bUnits, @recvdcost bDollar,
     @invunits bUnits, @invcost bDollar, @bounits bUnits, @bocost bDollar, @curunitcost bUnitCost, @discrate bRate,
     @inusemth bMonth, @inusebatchid int, @jobpaytype tinyint, @smpaytype tinyint, @exppaytype tinyint, @inuseby bVPUserName,@jobstatus tinyint,
     @apvendorgroup bGroup, @apvendor bVendor, @povendor bVendor, @ecmfactor int, @vendpayterms bPayTerms, @status tinyint,
     @comptype as varchar(10), @component as bEquip, @invdate bDate, @batchunits bUnits, @batchgross bDollar,@taxbasis bDollar,
     @poglacct bGLAcct, @popaytype tinyint, @popaytypeyn bYN, @GLCostOveride bYN, @paycategory int,@apcopaycategory int,
     @usingpaycategory bYN, @popaycategory int, @source varchar(1), @uiunits bUnits, @uigross bDollar, @pocompmsg varchar(255),
     @supplier bVendor /*--DC #130833*/,@popayterms bPayTerms, @aptlline int, @apuireviewergroup varchar(10),@ReviewerGroup varchar(10),
     @Dept bDept, @POItemLine INT, @OpenPOItemLine INT,
     @smco bCompany, @smworkorder INT, @smscope INT, @smphasegroup bGroup, @smphase bPhase, @smjccosttype bJCCType
         
     select @rcode = 0, @source = case @batchid when 0 then 'U' else 'E' end, @OpenPOItemLine = 0
    
     -- validate PO
     select @status = Status, @inusemth = InUseMth, @inusebatchid = InUseBatchId,@popayterms=PayTerms
     from bPOHD WITH (NOLOCK)
     where POCo = @co and PO = @po
     if @@rowcount = 0
         begin
         select @msg = 'Invalid Purchase Order.', @rcode = 1
         goto bspexit
         end
     if @status <> 0
         begin
         select @msg = 'Purchase Order must be open.', @rcode = 1
         goto bspexit
         end
    -- No longer locking/checking POHD InUse - AP project to use PO Item Line TK-07738
	--if @source = 'E'
	--	begin
 --    	if (@inusemth is not null or @inusebatchid is not null) and
 --         (@inusebatchid<>@batchid or @inusemth<>@month)
	--		begin
	--		select @hqsource = Source
	--		from bHQBC WITH (NOLOCK)
	--		where Co = @co and Mth = @inusemth and BatchId = @inusebatchid
	--		select @msg = 'Purchase Order already in use by Mth: ' +
 --      		      isnull(convert(varchar(2),datepart(month, @inusemth)), '') + '/' +
 --      		      isnull(substring(convert(varchar(4),datepart(year, @inusemth)),3,4), '') +
 --      			' Batch: ' + isnull(convert(varchar(6),@inusebatchid), '') + ' - ' + 
 --   			' Source: ' + isnull(@hqsource,''), @rcode = 1  --#23061
	--		goto bspexit
	--		end
	--	end
    
     -- get Vendor from Batch Seq Header or UI Seq Header
   if @source = 'E'
   	begin
   	  select @apvendorgroup = VendorGroup, @apvendor = Vendor, @invdate=InvDate
   	  from bAPHB WITH (NOLOCK)
   	  where Co = @co and Mth = @month and BatchId = @batchid and BatchSeq = @seq
   	  if @@rowcount = 0
   	      begin
   	      select @msg = 'Invalid Batch Seq# ' + isnull(convert(varchar(6),@seq),''), @rcode = 1
   	      goto bspexit
   	      end
   	end
   	
   if @source = 'U'
   	begin
   	  select @apvendorgroup = VendorGroup, @apvendor = Vendor, @invdate=InvDate, @apuireviewergroup = ReviewerGroup
   	  from bAPUI WITH (NOLOCK)
   	  where APCo = @co and UIMth = @month and UISeq = @seq
   	  if @@rowcount = 0
   	      begin
   	      select @msg = 'Invalid UI Seq# ' + isnull(convert(varchar(6),@seq),''), @rcode = 1
   	      goto bspexit
   	      end
   	end
    
	-- get default Pay Terms
	select @vendpayterms = PayTerms
	from bAPVM WITH (NOLOCK)
	where VendorGroup = @apvendorgroup and Vendor = @apvendor    
	if @@rowcount = 0
		begin
		select @msg = 'Invalid Vendor ' + isnull(convert(varchar(10),@apvendor),''), @rcode = 1
		goto bspexit
		end
    
	-- get Discount Rate for default Pay Terms - may be null
	select @discrate = 0
	if @popayterms is not null
		begin
		select @discrate = t.DiscRate
		from bHQPT t
		where PayTerms = @popayterms
		end
--	else
--		if @vendpayterms is not null
--		begin
--		select @discrate = t.DiscRate
--		from bHQPT t
--		where PayTerms = @vendpayterms
--		end
    
     -- make sure PO and AP Vendors match
     select @povendor = Vendor from bPOHD WITH (NOLOCK) where POCo = @co and PO = @po
     if @povendor <> @apvendor
         begin
         select @msg = 'Purchase Order Vendor (' + isnull(convert(varchar(15),@povendor),'') +
                    ') does not match the Vendor on the invoice(' + isnull(convert(varchar(15),@apvendor),'') +
                    ') you are initializing', @rcode = 1
         goto bspexit
         end
        
    -- check PO compliance
	if exists (select 1 from POCT WITH (NOLOCK) where POCo=@co and PO=@po and Verify='Y' and 
    				(Complied='N' or (ExpDate is not null and ExpDate < @invdate )) )
    	and exists (select 1 from APCO WITH (NOLOCK) where APCo=@co and POCompChkYN='Y' )
    	begin
    		select @pocompmsg = 'The PO :' + isnull(@po,'') + ' is not in compliance.' --, @rcode = 1
         	/*goto bspexit*/
    		select @complied = 'N'
    	end
         
    -- get pay types from bAPCO  
    select @exppaytype=ExpPayType, @jobpaytype=JobPayType, @smpaytype=SMPayType, @usingpaycategory=PayCategoryYN
    	 from bAPCO WITH (NOLOCK) where APCo = @co
        
	-- process each line of the PO
	IF @source = 'E'
	BEGIN
		DECLARE bcPOItemLine cursor LOCAL FAST_FORWARD for
		SELECT l.POItem, l.POItemLine
 		FROM dbo.vPOItemLine l (NOLOCK)
 		JOIN dbo.bPOIT i (NOLOCK) ON i.POCo=l.POCo AND i.PO=l.PO AND i.POItem=l.POItem
 		WHERE i.POCo = @co 
 		AND i.PO = @po 
 		AND
       		((l.InUseMth IS NULL AND l.InUseBatchId IS NULL) OR 
			(l.InUseMth = @month AND l.InUseBatchId = @batchid))
		AND ( i.InUseMth IS NULL AND i.InUseBatchId IS NULL)
		ORDER BY POItem,POItemLine
     	--select @poitem = min(POItem)
     	--from bPOIT WITH (NOLOCK)
     	--where POCo = @co and PO = @po and
      --     	((InUseMth is null and InUseBatchId is null) or 
    		--(InUseMth = @month and InUseBatchId = @batchid))	--#23398 
	END
		
	IF @source = 'U'
	BEGIN
		DECLARE bcPOItemLine cursor LOCAL FAST_FORWARD for
		SELECT POItem, POItemLine
 		FROM dbo.vPOItemLine (NOLOCK)
 		WHERE POCo = @co and PO = @po
 		ORDER BY POItem,POItemLine 
	END
   
	OPEN bcPOItemLine
	SELECT @OpenPOItemLine = 1
  
POItemLine_loop:      -- loop through each line

	FETCH NEXT FROM bcPOItemLine into @poitem, @POItemLine
   
    IF @@fetch_status <> 0 GOTO bspexit
         
         
         SELECT @itemtype = ItemType, @jcco = CASE ItemType WHEN 1 THEN PostToCo ELSE null END,
                @inco = CASE ItemType WHEN 2 THEN PostToCo ELSE null END,
                @emco=CASE ItemType WHEN 4 THEN PostToCo WHEN 5 THEN PostToCo ELSE null END,
                @job = Job, @phasegroup = PhaseGroup, @phase = Phase, @jcctype = JCCType,
                @wo = WO, @woitem = WOItem, @equip = Equip, @emgroup = EMGroup, @costcode = CostCode,
                @emctype = EMCType, @loc = Loc,@glco = GLCo, @glacct = GLAcct,  @taxgroup = TaxGroup,
                @taxcode = TaxCode, @taxtype=TaxType,@invunits = InvUnits, @invcost = InvCost,
                @recvdunits = RecvdUnits,@recvdcost = RecvdCost, @bounits = BOUnits, @bocost = BOCost,
                @comptype=CompType,@component=Component, @popaytype=PayType, @popaycategory=PayCategory,
                @smco = SMCo, @smworkorder = SMWorkOrder, @smscope = SMScope, @smphasegroup = SMPhaseGroup, @smphase = SMPhase, @smjccosttype = SMJCCostType
         FROM dbo.vPOItemLine (NOLOCK)
         WHERE POCo = @co and PO = @po and POItem = @poitem AND POItemLine=@POItemLine
         
         SELECT @matlgroup = MatlGroup, @material = Material,@description = Description, @um = UM,
				@recyn = RecvYN,@curunitcost = CurUnitCost,@ecm = CurECM,@supplier = Supplier  --DC #130833
		 FROM dbo.bPOIT (NOLOCK)
		 WHERE POCo = @co and PO = @po and POItem = @poitem 
       
	if @source = 'E'
   	begin
    	-- select units and cost from AP batch minus oldunits, oldgross - #25714
    	select @batchunits = (isnull(sum(Units),0) - isnull(sum(OldUnits),0)),
   				@batchgross = (isnull(sum(GrossAmt),0) - isnull(sum(OldGrossAmt),0))
    	from APLB WITH (NOLOCK)
    	where Co=@co and Mth=@month and BatchId=@batchid 
   		and isnull(PO,'')= isnull(@po,'') and isnull(POItem,'') = @poitem AND ISNULL(POItemLine,'') = @POItemLine
   	end
   	
   if @source = 'U' 
   	begin
   		-- select units and invcost from any unposted AP batch for add
		select @batchunits = (isnull(sum(Units),0) - isnull(sum(OldUnits),0)),
   			   @batchgross = (isnull(sum(GrossAmt),0) - isnull(sum(OldGrossAmt),0))
		from dbo.bAPLB WITH (NOLOCK)
		where Co=@co and isnull(PO,'')= isnull(@po,'') and isnull(POItem,'') = @poitem AND ISNULL(POItemLine,'') = @POItemLine
   		-- get units and cost from all UIMths/UISeq
   		select @uigross = isnull(sum(GrossAmt),0),@uiunits = isnull(sum(Units),0)
   		from dbo.bAPUL with (nolock) 
   		where APCo = @co and PO = @po and POItem = @poitem AND ISNULL(POItemLine,'') = @POItemLine
   	end
   
   	-- include batch units and cost in invoiced 
	select @invcost = @invcost + isnull(@batchgross,0) + isnull(@uigross,0)
	select @invunits = @invunits + isnull(@batchunits,0) + isnull(@uiunits,0) 
	select @bocost = @bocost - (@batchgross + isnull(@uigross,0)) 
	select @bounits = @bounits - (@batchunits + isnull(@uiunits,0))
    
	select @ecmfactor = 1
	if @ecm = 'C' select @ecmfactor = 100
	if @ecm = 'M' select @ecmfactor = 1000
    
	IF @recyn='Y'
	BEGIN
        if @um='LS'
			if @recvdcost<>@invcost
     			select @grossamt=@recvdcost-@invcost, @unitcost=0, @units = 0
     	    else
     	      	select @grossamt=0, @unitcost=0, @units=0
        else
            if @recvdunits <> @invunits
     	     	select @grossamt=((@recvdunits-@invunits) * (@curunitcost/@ecmfactor)), @unitcost=@curunitcost,
     	      	      @units = @recvdunits-@invunits
     	    else
     	     	select @grossamt=0, @unitcost=0, @units=0
     END
     ELSE
     BEGIN
         if @um='LS'
             if @bocost<>0
     			select @grossamt=@bocost, @unitcost=0, @units=0
   		 else
     			select @grossamt=0, @unitcost=0, @units=0
			else
				if @bounits<>0
     	      		select @grossamt=(@bounits * (@curunitcost/@ecmfactor)), @unitcost=@curunitcost, @units=@bounits
				else
     				select @grossamt=0, @unitcost=0, @units=0
     END 
       
		 -- get Tax rate
		select @taxrate = 0
		if @taxcode is not null
		begin
			exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @posteddate, @taxrate = @taxrate output 
			if @rcode <> 0
				begin
				goto bspexit
				end
			else
				select @taxbasis = @grossamt
		end
		else
			select @taxbasis = 0
        
    	-- if using pay category get pay types from bAPPC 
    	if @usingpaycategory='Y'
    		begin
    		exec @rcode = bspAPPayTypeGet @co, @userid, @exppaytype output, @jobpaytype output, 
    	  		@smpaytype OUTPUT,null,null,null,null,@paycategory output, @msg output
    	 	if @rcode=1
    			begin
    			goto bspexit
    			end
    		end
         -- set Pay Type
    	 if @popaytype is null
    		 begin   
    	     select @paytype = @exppaytype, @popaytypeyn = 'N'
    	     if @itemtype = 1  select @paytype = @jobpaytype
    	     if @itemtype = 6  select @paytype = @smpaytype
    		 end
    	 else
    		 begin
    		 select @paytype = @popaytype, @popaytypeyn = 'Y', @paycategory=@popaycategory
    		 end
   		         		      
    --handle GLAcct for job type issue #19163
    if @itemtype = 1
    begin
		-- Get GL override
    	select @GLCostOveride = GLCostOveride from bJCCO WITH (NOLOCK) where JCCo = @jcco
		-- Get Job Status 
    	select @jobstatus = JobStatus from bJCJM with (nolock) where JCCo=@jcco and Job=@job
		-- Save off PO GLAcct
		select @poglacct = @glacct
		-- Get Default Job GLAcct
		exec @rcode = bspJCCAGlacctDflt @jcco, @job, @phasegroup, @phase, 
		  @jcctype, 'N', @glacct output, @msg output
   			if @rcode= 0 select @msg= null -- clear returned phase desc 
		-- Determine which GL Acct to use
		If isnull(@glacct,'') = ''
			begin
			if @jobstatus < 3 -- job is not closed
				begin
				select @glacct = @poglacct
				end
			else
				begin
				select @rcode = 1, @msg = 'GL Account default is null for PO ' + isnull(@po,'')
    						 + ' Item: ' + convert(varchar(4),@poitem) + ' and cannot be initialized.'
    			goto bspexit
				end
			end
		else
			begin
			--return warning if job glacct and po glacct are different
			if @glacct <> @poglacct
				begin
				select @rcode = 2 --warn PO GLacct is diff from default Gl acct
				end 
			if @GLCostOveride = 'Y'  
				begin
				if @jobstatus in (1,2) select @glacct = @poglacct -- job is open or soft closed
				end
			end

--    		if @glacct <> @newglacct 
--    			begin
--    			select @rcode = 2
--    			if @newglacct is not null 
--    				begin
--    				select @glacct = @newglacct
--    				end
--    			else
--    				begin
--    				if @GLCostOveride = 'N'
--    					begin
--    					select @rcode = 1, @msg = 'GL Account default is null for PO ' + isnull(@po,'')
--    						 + ' Item: ' + convert(varchar(4),@poitem) + ' and cannot be initialized.'
--    					goto bspexit
--    					end
--    				end
--    			
--    			end
    end
    
   
   if @source = 'E'
   	begin 
         -- get next Line
		-- get max line # from bAPTL  - #132114
		select @aptlline = isnull(max(l.APLine),0) 
		 FROM bAPTL l WITH (NOLOCK)
		 JOIN bAPHB h WITH (NOLOCK) on h.Co=l.APCo and h.Mth=l.Mth and h.APTrans=l.APTrans
         where h.Co=@co and h.Mth=@month and h.BatchId=@batchid and h.BatchSeq=@seq
		-- get max line # from bAPLB 
		select @apline = isnull(max(APLine),0) from bAPLB WITH (NOLOCK)
         where Co=@co and Mth=@month and BatchId=@batchid and BatchSeq=@seq
		-- increment line #
		if @aptlline > @apline select @apline = @aptlline + 1
		else select @apline = @apline + 1
--         select @apline = isnull(max(APLine),0) + 1
--         from bAPLB WITH (NOLOCK)
--         where Co=@co and Mth=@month and BatchId=@batchid and BatchSeq=@seq
        
         if @units <> 0 or @unitcost <> 0 or @grossamt <> 0
             begin   
             insert into dbo.bAPLB(Co, Mth, BatchId, BatchSeq, APLine, BatchTransType, LineType, PO, POItem, POItemLine,
                 ItemType, JCCo, Job, PhaseGroup, Phase, JCCType, EMCo, WO, WOItem, Equip, EMGroup,
          	    CostCode, EMCType, INCo, Loc, MatlGroup, Material, GLCo, GLAcct, Description,
        	        UM, Units, UnitCost, ECM, PayType, GrossAmt, MiscAmt, MiscYN, TaxGroup, TaxCode, TaxType,
                 TaxBasis, TaxAmt, Retainage, Discount, CompType, Component, POPayTypeYN, PayCategory, VendorGroup,
                 Supplier, 
                 SMCo, SMWorkOrder, Scope, SMPhaseGroup, SMPhase, SMJCCostType)
             values(@co, @month, @batchid, @seq, @apline, 'A', 6, @po, @poitem,@POItemLine, @itemtype,
                 @jcco, @job, @phasegroup, @phase, @jcctype, @emco, @wo, @woitem, @equip, @emgroup,
                 @costcode, @emctype, @inco, @loc, @matlgroup, @material, @glco, @glacct, @description,
                 @um, @units, @unitcost, @ecm, @paytype,@grossamt, 0, 'N', @taxgroup, @taxcode, @taxtype,
    			 @taxbasis, (@grossamt*@taxrate), 0,(@grossamt*@discrate),@comptype,@component,
    			 @popaytypeyn, @paycategory, @apvendorgroup,
    			 @supplier, 
    			 @smco, @smworkorder, @smscope, @smphasegroup, @smphase, @smjccosttype)
             end
   	end 
	if @source = 'U'
	begin
		-- get next Line
		select @apline = isnull(max(Line),0) + 1
		from bAPUL WITH (NOLOCK)
		where APCo=@co and UIMth=@month and UISeq=@seq
    
		if @units <> 0 or @unitcost <> 0 or @grossamt <> 0
		begin  
			 -- Get default Reviewer Group based on PO Item Type #144000
			 IF @itemtype = 1 -- Job
			 BEGIN
				SELECT @ReviewerGroup = RevGrpInv 
   				FROM dbo.bJCJM 
   				WHERE JCCo=@jcco AND Job=@job
			 END
			 IF @itemtype = 2 -- Inventory
			 BEGIN
				SELECT @ReviewerGroup = ReviewerGroup 
				FROM dbo.INLM
				WHERE INCo=@inco AND Loc=@loc
			 END 
			 IF @itemtype = 3 -- Expense
			 BEGIN
 				SELECT @ReviewerGroup = ReviewerGroup
				FROM dbo.GLAC
				WHERE GLCo=@glco AND GLAcct=@glacct 
			 END
			 IF @itemtype in (4,5) -- Equip, Work Order
			 BEGIN
				SELECT @Dept = Department
				FROM dbo.EMEM
				WHERE EMCo=@emco AND Equipment=@equip
				IF @Dept IS NOT NULL
				BEGIN
					SELECT @ReviewerGroup = ReviewerGroup
					FROM dbo.EMDM
					WHERE EMCo=@emco AND Department=@Dept 
				END
			 END 
			insert into bAPUL(APCo,Line, UIMth, UISeq,LineType, PO, POItem,POItemLine,
				ItemType, JCCo, Job, PhaseGroup, Phase, JCCType, EMCo, WO, WOItem, Equip, EMGroup,
          	    CostCode, EMCType, INCo, Loc, MatlGroup, Material, GLCo, GLAcct, Description,
				UM, Units, UnitCost, ECM, PayType, GrossAmt, MiscAmt, MiscYN, TaxGroup, TaxCode, TaxType,
				TaxBasis, TaxAmt, Retainage, Discount, CompType, Component, PayCategory, VendorGroup,
				Supplier, ReviewerGroup)  --DC #130833 (supplier)   
			values(@co,@apline, @month,@seq, 6, @po, @poitem, @POItemLine, @itemtype,
				@jcco, @job, @phasegroup, @phase, @jcctype, @emco, @wo, @woitem, @equip, @emgroup,
				@costcode, @emctype, @inco, @loc, @matlgroup, @material, @glco, @glacct, @description,
				@um, @units, @unitcost, @ecm, @paytype,@grossamt, 0, 'N', @taxgroup, @taxcode, @taxtype,
				@taxbasis, (@grossamt*@taxrate), 0,(@grossamt*@discrate),@comptype,@component,@paycategory,
				@apvendorgroup,@supplier,--DC #130833 (supplier)
				CASE @ReviewerGroup WHEN NULL THEN @apuireviewergroup ELSE @ReviewerGroup END) 
		end
   	end
   	
   	GOTO   POItemLine_loop 

   
	--IF @source = 'E'
	--BEGIN
	--	SELECT @POItemLine = min(POItemLine)
	--	from dbo.vPOItemLine (NOLOCK)
	--	WHERE 	(POCo = @co and PO = @po and POItem > @poitem) and 
 --   			((InUseMth is null and InUseBatchId is null) or
 --    			(InUseMth = @month and InUseBatchId = @batchid)) 
	--	--select @poitem = min(POItem)
	--	--from bPOIT WITH (NOLOCK)
	--	--where 	(POCo = @co and PO = @po and POItem > @poitem) and 
 -- --  			((InUseMth is null and InUseBatchId is null) or
 -- --   			(InUseMth = @month and InUseBatchId = @batchid))
	--	end
   
	--if @source = 'U'
	--	begin
 --  		select @poitem = min(POItem)   
	--	from bPOIT WITH (NOLOCK)
	--	where POCo = @co and PO = @po and POItem > @poitem
 --  		end
  
    
     bspexit:
		IF @OpenPOItemLine = 1
		BEGIN
			close bcPOItemLine
			deallocate bcPOItemLine		
		END
   		if @rcode <> 1 and @pocompmsg is not null select @msg=@pocompmsg --#26296
       	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPOInit] TO [public]
GO
