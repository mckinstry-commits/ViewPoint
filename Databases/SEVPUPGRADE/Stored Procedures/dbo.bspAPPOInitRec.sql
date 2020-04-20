SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPOInitRec    Script Date: 02/19/2000 ******/            
	CREATE                     proc [dbo].[bspAPPOInitRec]
	/***********************************************************
	* CREATED BY	: danf 02/19/2000
	* Modified By	: MV 12/19/02 - #19670 - pull in CompType and Component for Equip type.
	*					MV 02/09/04 - #18763 - PayType from bPOIT, set POPayTypeYN flag
	*					MV 02/09/04 - #18769 - PayCategory from bPOIT
	*					MV 03/02/04 - #18769 - Pay Types from Pay Category
	*					MV 03/02/04 - #23061 - isnull wrap / performance enhancements
	*					MV 05/05/04 - #24539 - remove second Pay Type from bAPLB insert
	*					MV 05/26/04 - #24682 - insert VendorGroup in bAPLB
	*					MV 05/28/04 - #24686 - correct logic for inusebatch check	
	*					MV 08/20/04 - #17820 - Init POs in Unapproved 
	*					MV 08/25/04 - #25414 - don't null out paycategory if PO paytype is null
	*					MV 09/27/04 - #17820 - Don't check UI for batch in use
	*					MV 11/03/04 - #17820 - Get vendor and vendorgroup for Unapproved
	*					MV 02/14/06 - #120238 - truncate 60 char description for insert to bAPLB.
	*					MV 08/07/06 - #26096 - init PO if Receiver passed in is null
	*					MV 02/16/07 - #123805 - default GLAcct
	*					MV 03/06/08	- #126640 - always return warning if PO glacct <> JOb glacct
	*					MV 09/11/08 - #129788 - taxbasis shld be 0 if there is no taxcode on the PO
	*					DC 11/10/08 - #130833 - add the 'Supplier' field to the PO Entry form
	*					MV 12/03/08 - #131245 - use only PO payterms to get disc rate
	*					MV 02/03/09 - #132114 - include bAPTL when getting next Line# for bAPLB insert
	*					MV 02/05/09 - #123778 - exclude from bPORD by APMth/APTrans/APLine instead of InvFlag
	*											include Receiver # in bAPLB insert
	*					MV 04/08/09 - #131822 - default APUI ReviewerGroup to APUL
	*					MV 09/01/10 - #141042 - use PORD.APMth,APTrans and APLine rather than InvdFlag in where clause for nxtpoitem 
	*					ECV 05/25/11 - TK-05443 - Add SMPayType parameter to bspAPPayTypeGet
	*					MV 05/26/11 - #144000 - default ReviewerGroup based on POItem Type 
     *					TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *					MV 08/24/11 - TK-07944 - AP project to use POItemLine, converted pseudo cursor to real thing
	* 
	* USAGE:
	* Called by AP Invoice Entry program to initialize a new batch entry
	* based on a selected Purchase Order and Receiver#.
	*
	* INPUTS:
	*    @co         AP Company
	*    @month      Batch month - expense month
	*    @batchid    BatchID
	*    @seq        Sequence # within batch to add new entries to
	*    @po         Purchase order to pull items from.
	*    @receiver   receiver #
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
	@po varchar(30), @receiver varchar(20)= null,@posteddate bDate = null, @userid bVPUserName,
	@msg varchar(255) output)
       
	as

	set nocount on

	declare @rcode int, @numrows int, @poco bCompany, @aplinetype tinyint, @apline int, @poitem bItem, @POItemLine INT,
	@itemtype tinyint, @recyn bYN, @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType,
	@emco bCompany, @wo bWO, @woitem bItem, @equip bEquip, @emgroup bGroup, @costcode bCostCode, @emctype bEMCType,
	@hqsource bSource, @inco bCompany, @loc bLoc, @matlgroup bGroup, @material bMatl, @glco bCompany, @glacct bGLAcct,
	@description bDesc, @um bUM, @units bUnits, @unitcost bUnitCost, @ecm bECM, @paytype tinyint, @grossamt bDollar,
	@taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @taxrate bRate, @recvdunits bUnits, @recvdcost bDollar,
	@invunits bUnits, @invcost bDollar, @bounits bUnits, @bocost bDollar, @curunitcost bUnitCost, @discrate bRate,
	@inusemth bMonth, @inusebatchid int, @jobpaytype tinyint, @smpaytype tinyint, @exppaytype tinyint, @inuseby bVPUserName,@taxbasis bDollar,
	@apvendorgroup bGroup, @apvendor bVendor, @povendor bVendor, @ecmfactor int, @vendpayterms bPayTerms, @status tinyint,
	@comptype as varchar(10), @component as bEquip, @popaytype tinyint, @popaytypeyn bYN, @paycategory int,@jobstatus tinyint,
	@apcopaycategory int, @usingpaycategory bYN, @popaycategory int, @source varchar (1),@poglacct bGLAcct,@GLCostOveride bYN,
	@supplier bVendor,@popayterms bPayTerms, @aptlline int, @apuireviewergroup varchar(10),@ReviewerGroup varchar(10),
    @Dept bDept, @OpenPORD INT

	select @rcode = 0, @source = case @batchid when 0 then 'U' else 'E' end, @OpenPORD = 0

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
           
	if @source = 'E'
		begin
		-- No longer locking/checking POHD InUse - AP project to use PO Item Line 
		--     if (@inusemth is not null or @inusebatchid is not null) and (@inusemth<>@month and @inusebatchid<>@batchid)
   --		if ((@inusemth is not null or @inusebatchid is not null) and (@inusemth<>@month or @inusebatchid<>@batchid))
			--begin
			--select @hqsource = Source
   --      	from bHQBC WITH (NOLOCK) 
   --      	where Co = @co and Mth = @inusemth and BatchId = @inusebatchid
   --      	select @msg = 'Purchase Order already in use by Mth: ' +
   --      		      isnull(convert(varchar(2),datepart(month, @inusemth)),'') + '/' +
   --      		      isnull(substring(convert(varchar(4),datepart(year, @inusemth)),3,4),'') +
   --      				' Batch: ' + isnull(convert(varchar(6),@inusebatchid),'') + ' - '
   --  				 	+ ' Source: ' + isnull(@hqsource,''), @rcode = 1
   --      	goto bspexit
   --      	end
      
		-- get Vendor from Batch Seq Header
		select @apvendorgroup = VendorGroup, @apvendor = Vendor
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
		-- get Vendor from APUI
		select @apvendorgroup = VendorGroup, @apvendor = Vendor, @apuireviewergroup = ReviewerGroup
		from bAPUI WITH (NOLOCK) 
		where APCo = @co and UIMth = @month and UISeq = @seq
		if @@rowcount = 0
           begin
           select @msg = 'Invalid Unapproved Seq# ' + isnull(convert(varchar(6),@seq),''), @rcode = 1
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
       
	-- make sure PO and AP Vendors match
	select @povendor = Vendor from bPOHD WITH (NOLOCK) where POCo = @co and PO = @po
	if @povendor <> @apvendor
		begin
		select @msg = 'Purchase Order Vendor (' + isnull(convert(varchar(15),@povendor),'') +
                      ') does not match the Vendor on the invoice(' + isnull(convert(varchar(15),@apvendor),'') +
                      ') you are initializing', @rcode = 1
		goto bspexit
		end
             
     -- get pay types from bAPCO  
     select @exppaytype=ExpPayType, @jobpaytype=JobPayType, @smpaytype=SMPayType, @usingpaycategory=PayCategoryYN
     	 from bAPCO WITH (NOLOCK) where APCo = @co
     -- if using pay category get pay types from bAPPC 
     if @usingpaycategory='Y'
     	begin
     	exec @rcode = bspAPPayTypeGet @co, @userid, @exppaytype output, @jobpaytype output, @smpaytype OUTPUT,
       		null,null,null,null,@paycategory output, @msg output
      	if @rcode=1
     		begin
     		goto bspexit
     		end
     	end
     	
    -- check if there are any po receipts to process	
    IF NOT EXISTS( SELECT * 
		FROM dbo.bPORD r WITH (NOLOCK) 
		WHERE r.POCo = @co AND r.PO = @po AND ISNULL(r.Receiver#,'') = ISNULL(ISNULL(@receiver,r.Receiver#),'') 
			AND (r.APMth IS NULL AND r.APTrans IS NULL AND r.APLine IS NULL))
    BEGIN
		SELECT @msg = 'No PO Receipts found for PO: ' + ISNULL(@po,''), @rcode = 1
		GOTO bspexit
	END
       
	-- process each line of the PO
	DECLARE vcPORD cursor LOCAL FAST_FORWARD for
	SELECT POItem, POItemLine 
	FROM dbo.bPORD r WITH (NOLOCK) 
	WHERE r.POCo = @co AND r.PO = @po AND ISNULL(r.Receiver#,'') = ISNULL(ISNULL(@receiver,r.Receiver#),'') 
		AND (r.APMth IS NULL AND r.APTrans IS NULL AND r.APLine IS NULL)
	ORDER BY POItem,POItemLine
	
	
	OPEN vcPORD
	SELECT @OpenPORD = 1
  
PORD_loop:      -- loop through each line

	FETCH NEXT FROM vcPORD into @poitem, @POItemLine
   
    IF @@fetch_status <> 0 GOTO bspexit
      
    SELECT @recvdunits = sum(r.RecvdUnits), @recvdcost = sum(r.RecvdCost)
	FROM dbo.bPORD r WITH (NOLOCK)
    WHERE r.POCo = @co and r.PO = @po and r.POItem = @poitem and r.POItemLine=@POItemLine and
			isnull(r.Receiver#,'') = isnull(isnull(@receiver,r.Receiver#),'') 
			and r.APMth is null and r.APTrans is null and r.APLine is null /*and r.InvdFlag = 'N'*/
    SELECT	@itemtype = i.ItemType, 
			@jcco = CASE i.ItemType WHEN 1 THEN i.PostToCo ELSE null END,
			@inco = CASE i.ItemType WHEN 2 THEN i.PostToCo ELSE null END,
            @emco=CASE i.ItemType WHEN 4 THEN i.PostToCo WHEN 5 THEN i.PostToCo ELSE null END,
            @job = i.Job, @phasegroup = i.PhaseGroup, @phase = i.Phase, @jcctype = i.JCCType,
            @wo = i.WO, @woitem = i.WOItem, @equip = i.Equip, @emgroup = i.EMGroup, @costcode = i.CostCode,
            @emctype = i.EMCType, @loc = i.Loc,@glco = i.GLCo, @glacct = i.GLAcct,  @taxgroup = i.TaxGroup,
            @taxcode = i.TaxCode, @taxtype=i.TaxType, @component=Component,@invunits = i.InvUnits, @invcost = i.InvCost,
            @comptype=CompType,@bounits = i.BOUnits, @bocost = i.BOCost, @inusemth = i.InUseMth, @inusebatchid = i.InUseBatchId,
 			@popaytype = i.PayType, @popaycategory=i.PayCategory 
 	FROM dbo.vPOItemLine i (NOLOCK)
    WHERE POCo = @co and PO = @po and POItem = @poitem AND POItemLine=@POItemLine		 
	SELECT @matlgroup = MatlGroup, @material = Material,@description = Description, @um = UM,
		@recyn = RecvYN,@curunitcost = CurUnitCost,@ecm = CurECM,@supplier = Supplier  
	FROM dbo.bPOIT (NOLOCK)
	WHERE POCo = @co and PO = @po and POItem = @poitem 
  
    IF @source = 'E' and (@inusemth is not null or @inusebatchid is not null)
		 and (@inusemth<>@month or @inusebatchid<>@batchid) GOTO PORD_loop
       
   	-- recvdcost and recvdunits always default to 0
    IF (@um ='LS' and @recvdcost = 0) or (@um <>'LS' and @recvdunits = 0) GOTO PORD_loop
       
       
	SELECT @ecmfactor = 1
	IF @ecm = 'C' SELECT @ecmfactor = 100
	IF @ecm = 'M' SELECT @ecmfactor=1000

	IF @recyn='Y'
    BEGIN
       IF @um='LS'
   	       SELECT @grossamt=@recvdcost, @unitcost=0, @units = 0
       ELSE
   	       SELECT @grossamt=((@recvdunits) * (@curunitcost/@ecmfactor)), @unitcost=@curunitcost,
   	       	      @units = @recvdunits
    END
	ELSE
	BEGIN
		SELECT @grossamt=0, @unitcost=0, @units=0
	END
       
	 -- get Tax rate
     select @taxrate = 0
     if @taxcode is not null
         begin
         exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @posteddate, @taxrate = @taxrate output, @msg = @msg output 
		 if @rcode <> 0
			begin
			goto bspexit
			end
		 else
			select @taxbasis = @grossamt
         end
	else
		select @taxbasis = 0
          
 		-- set Pay Type
 	 if @popaytype is null
 		 begin
 	     select @paytype = @exppaytype, @popaytypeyn = 'N' --, @paycategory = null #25414
 	     if @itemtype = 1  select @paytype = @jobpaytype
 	     if @itemtype = 6 SELECT @paytype = @smpaytype
 		 end
 	 else
 		 begin
 		 select @paytype = @popaytype, @popaytypeyn = 'Y',@paycategory=@popaycategory
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
		end
		
   	IF @source = 'E'
   	BEGIN 
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
	
		IF @units <> 0 or @unitcost <> 0 or @grossamt <> 0
		BEGIN   -- will need to add CompType and Component for EM
			INSERT into bAPLB(Co, Mth, BatchId, BatchSeq, APLine, BatchTransType, LineType, PO, POItem,POItemLine,
				ItemType, JCCo, Job, PhaseGroup, Phase, JCCType, EMCo, WO, WOItem, Equip, EMGroup,
				CostCode, EMCType, INCo, Loc, MatlGroup, Material, GLCo, GLAcct, Description,
				UM, Units, UnitCost, ECM, GrossAmt, MiscAmt, MiscYN, TaxGroup, TaxCode, TaxType,TaxBasis,
   				TaxAmt, Retainage, Discount, CompType, Component,PayType,POPayTypeYN,PayCategory, VendorGroup,
   				Supplier, Receiver#)         
			VALUES(@co, @month, @batchid, @seq, @apline, 'A', 6, @po, @poitem, @POItemLine, @itemtype,
				@jcco, @job, @phasegroup, @phase, @jcctype, @emco, @wo, @woitem, @equip, @emgroup,
				@costcode, @emctype, @inco, @loc, @matlgroup, @material, @glco, @glacct, @description,
				@um, @units, @unitcost, @ecm, @grossamt, 0, 'N', @taxgroup, @taxcode, @taxtype,
				@taxbasis, (@grossamt*@taxrate), 0, (@grossamt*@discrate),@comptype,@component,@paytype,
				@popaytypeyn,@paycategory, @apvendorgroup,@supplier, @receiver)  
   		END
   	END
   	
   	IF @source = 'U'
   	BEGIN
   		-- get next Line
         select @apline = isnull(max(Line),0) + 1
         from bAPUL WITH (NOLOCK)
         where APCo=@co and UIMth=@month and UISeq=@seq
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
		
         IF @units <> 0 or @unitcost <> 0 or @grossamt <> 0
         BEGIN   
             INSERT into bAPUL(APCo,Line, UIMth, UISeq, LineType, PO, POItem,POItemLine,
                 ItemType, JCCo, Job, PhaseGroup, Phase, JCCType, EMCo, WO, WOItem, Equip, EMGroup,
          	    CostCode, EMCType, CompType, Component, INCo, Loc, MatlGroup, Material, GLCo, GLAcct, Description,
        	        UM, Units, UnitCost, ECM, VendorGroup, PayType, GrossAmt, MiscAmt, MiscYN, TaxGroup, TaxCode, TaxType,
                 TaxBasis, TaxAmt, Retainage, Discount, PayCategory,
                 Supplier, Receiver#,ReviewerGroup)  --DC #130833 add supplier      
             VALUES(@co, @apline, @month, @seq,6, @po, @poitem, @POItemLine, @itemtype,
                 @jcco, @job, @phasegroup, @phase, @jcctype, @emco, @wo, @woitem, @equip, @emgroup,
                 @costcode, @emctype, @comptype,@component,@inco, @loc, @matlgroup, @material, @glco, @glacct, @description,
                 @um, @units, @unitcost, @ecm, @apvendorgroup,@paytype,@grossamt, 0, 'N', @taxgroup, @taxcode, @taxtype,
    			 @taxbasis, (@grossamt*@taxrate), 0,(@grossamt*@discrate),@paycategory,@supplier, @receiver,--DC #130833 add supplier
    			 CASE @ReviewerGroup WHEN NULL THEN @apuireviewergroup ELSE @ReviewerGroup END)  
        END
    END
              
    GOTO PORD_loop          

       
	bspexit:
		IF @OpenPORD = 1
		BEGIN
			close vcPORD
			deallocate vcPORD		
		END 
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPOInitRec] TO [public]
GO
