SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    PROCEDURE [dbo].[bspPOCopy]
    /*******************************************************************************
    * Created By:   GF 03/18/2003
    * Modified By:	 MV 05/14/03 - #18763 - copy Pay Type from source to dest PO
    *		RT 08/21/03 - #21582 - Added Address2 column.
    *		RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
    *		MV 03/03/04 - #18769 - Pay Category
    *		MV 06/05/06 - #121466 - order by POItem in POIT cursor
    *		DC 9/22/06 - Re-code for 6.x.  Added EMGroup to the output for Equipment 
	*							and Work Order types to the call to bspPOITCoVal
	*		TJL 01/29/08 - Issue #126814:  Return EMCO.MatlLastUsedYN value.  Modified params for all DDFI ValProcs using this.
	*		DC 3/07/2008 - Issue #127075:  Modify PO/RQ  for International addresses
	*		GF 03/11/2008 - issue #127076 added country as output parameter to bspJCJMPostVal
	*		Dan Soch 03/17/08 - #127082 - added @incountry
	*		DC 11/11/08 - #129999 - Not all PO Items copy if over 276 items.@srcpoitems needs to be bigger
	*		DC 1/27/09 - #131948 - POCopy not copying the Company columns correctly
	*		GP 06/03/09 - Issue 132805 added null to bspJCJMPostVal
	*		DC 12/22/09 - #122288  Store Tax Rate in POIT
	*		DC 8/25/2010 - #135180 - Destination job is in header but not in the items
	*		GF 10/29/2010 - #136979 - added vendor terms to POHB insert from APVM.
	*		AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function., Fixing performance issue by using an inline table function.
	*		TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *		MV 11/4/11 - TK-09070 - added NULL output param to bspVendorVal
    *		GP 4/9/12 - TK-13774 added validation against POUnique view
    *
    * This SP will copy a source PO into a destination PO. Called from POCopy.
    *
    *
    * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
    *
    * Pass In
    * poco          PO Company
    * srcpo			Source PO
    * destpo		Destination PO
    * destvendor	Destination Vendor
    * destdesc		Destination description
    * destorderdate Destination Order Date
    * destorderedby Destination Ordered By
    * destexpdate	Destination Expected Date
    * destjcco		Destination JCCo
    * destjob		Destination Job
    * destshiploc	Destination Ship Location
    * destinco		Destination INCo
    * destinloc		Destination IN Location
    * clearpohdnotes	Clear POHD Notes
    * clearpohdmemos	Clear POHD User Memos
    * keepitemprices	Keep POIT Item unit prices
    * setitemunits		Set POIT Item quantities to one
    * clearpoitnotes	Clear POIT Notes
    * clearpoitmemos	Clear POIT User Memos
    * copyworkorders	Copy POIT work order items
    * overridewo		Override work order item values
    * woemco			Work Order EMCo
    * wo				Work Order
    * copyequipment		Copy POIT equipment items
    * overrideequip		Override equipment item values
    * equipemco			Equipment EMCo
    * equipment			Equipment
    * srcpoitems		Source PO items string to copy each item separated by ';'
    * month				Batch Month
    * batchid			Batch Id
    *
    *
    *
    * RETURN PARAMS
    *   msg           Error Message, or Success message
    *
    * Returns
    *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
    *
    ********************************************************************************/
    (
      @poco bCompany = NULL,
      @srcpo varchar(30) = NULL,
      @destpo varchar(30) = NULL,
      @destvendor bVendor = NULL,
      @destdesc bDesc = NULL,
      @destorderdate bDate = NULL,
      @destorderedby VARCHAR(10) = NULL,
      @destexpdate bDate = NULL,
      @destjcco bCompany = NULL,
      @destjob bJob = NULL,
      @destshiploc VARCHAR(10) = NULL,
      @destinco bCompany = NULL,
      @destinloc bLoc = NULL,
      @clearpohdnotes bYN = 'N',
      @clearpohdmemos bYN = 'N',
      @keepitemprices bYN = 'N',
      @setitemunits bYN = 'N',
      @clearpoitnotes bYN = 'N',
      @clearpoitmemos bYN = 'N',
      @copyworkorders bYN = 'N',
      @overridewo bYN = 'N',
      @ovrwoemco bCompany = NULL,
      @ovrwo bWO = NULL,
      @copyequipment bYN = 'N',
      @overrideequip bYN = 'N',
      @ovrequipemco bCompany = NULL,
      @ovrequipment bEquip = NULL,
      @srcpoitems VARCHAR(8000) = NULL,
      @mth bMonth,
      @batchid bBatchID,
      @msg VARCHAR(1000) OUTPUT
    )
AS 
    SET nocount ON
    
    DECLARE @rcode INT,
        @retcode INT,
        @validcnt INT,
        @open_cursor TINYINT,
        @errmsg VARCHAR(255),
        @pohbseq INT,
        @address VARCHAR(60),
        @city VARCHAR(30),
        @state VARCHAR(4),
        @address2 VARCHAR(60),
        @country VARCHAR(2),  --DC #127075
        @pocount INT,
        @poitemcount INT,
        @zip bZip,
        @retmsg VARCHAR(255),
        @baditems VARCHAR(500)
    
    DECLARE @contract bContract,
        @jobstatus TINYINT,
        @lockedphases bYN,
        @jobtaxcode bTaxCode,
        @jobaddress VARCHAR(60),
        @jobcity VARCHAR(30),
        @jobstate VARCHAR(4),
        @jobzip bZip,
        @jobaddress2 VARCHAR(60),
        @vendorpayterms bPayTerms,
        @vendortaxcode bTaxCode,
        @vendorgroup bGroup,
        @vendorsort VARCHAR(15),
        @inaddress VARCHAR(60),
        @incity VARCHAR(30),
        @instate VARCHAR(4),
        @inzip bZip,
        @inaddress2 VARCHAR(60),
        @incountry VARCHAR(2),
        @posladdress VARCHAR(60),
        @poslcity VARCHAR(30),
        @poslstate VARCHAR(4),
        @poslzip bZip,
        @posladdress2 VARCHAR(60),
        @posltaxcode bTaxCode,
        @srcpoitem bItem,
        @invtaxcode bTaxCode,
        @poslcountry VARCHAR(2),
        @jobcountry VARCHAR(2)  --DC #127075
    
    DECLARE @itemtype TINYINT,
        @matlgroup bGroup,
        @material bMatl,
        @vendmatid VARCHAR(30),
        @poitdesc bItemDesc,
        @um bUM,
        @recvyn bYN,
        @posttoco bCompany,
        @loc bLoc,
        @job bJob,
        @phasegroup bGroup,
        @phase bPhase,
        @jcctype bJCCType,
        @equip bEquip,
        @comptype VARCHAR(10),
        @component bEquip,
        @emgroup bGroup,
        @costcode bCostCode,
        @emctype bEMCType,
        @wo bWO,
        @woitem bItem,
        @glco bCompany,
        @glacct bGLAcct,
        @reqdate bDate,
        @taxgroup bGroup,
        @taxcode bTaxCode,
        @taxtype TINYINT,
        @origunits bUnits,
        @origunitcost bUnitCost,
        @origecm bECM,
        @origcost bDollar,
        @origtax bDollar,
        @requisitionnum VARCHAR(20),
        @paytype TINYINT,
        @paycategory INT
    
    DECLARE @poitunits bUnits,
        @poitunitcost bUnitCost,
        @poitecm bECM,
        @poitcost bDollar,
        @maxpoibitem bItem,
        @maxpoititem bItem,
        @newitem bItem,
        @pohbvendorgroup bGroup,
        @pohbvendor bVendor,
        @pohbjcco bCompany,
        @pohbjob bJob,
        @pohbinco bCompany,
        @pohbloc bLoc,
        @pohbshiploc VARCHAR(10),
        @pohborderdate bDate,
        @pohbexpdate bDate,
        @columnname VARCHAR(30),
        @updatestring VARCHAR(1000),
        @dfltunitcost bUnitCost,
        @dfltecm bECM,
        @taxable bYN,
        @poittax bDollar,
        @taxrate bRate,
        @postcosttocomp CHAR(1),
        @woequip bEquip,
        @wocomp bEquip,
        @wocomptypecode VARCHAR(10),
        @wocostcode bCostCode,
        @description bDesc,
        @ecmfactor INT,
        @gstrate bRate  --DC #122288
   			
   	--DC #131948		
    DECLARE @poitjcco bCompany,
        @poitinco bCompany,
        @poitemco bCompany,
        @supplier bVendor,
        @suppliergroup bGroup
        
    SELECT  @rcode = 0,
            @retcode = 0,
            @open_cursor = 0,
            @pocount = 0,
            @poitemcount = 0
    
    IF @poco IS NULL 
        BEGIN
            SELECT  @msg = 'Missing PO company',
                    @rcode = 1
            GOTO bspexit
        END
    
    IF @srcpo IS NULL 
        BEGIN
            SELECT  @msg = 'Missing Source PO',
                    @rcode = 1
            GOTO bspexit
        END
    
    IF @destpo IS NULL 
        BEGIN
            SELECT  @msg = 'Missing Destination PO',
                    @rcode = 1
            GOTO bspexit
        END
    
    IF @destvendor IS NULL 
        BEGIN
            SELECT  @msg = 'Missing Destination PO Vendor',
                    @rcode = 1
            GOTO bspexit
        END
        
	--checks the POUnique view for records in vPOPendingPurchaseOrder
	exec @rcode = dbo.vspPOInitVal @poco, @destpo, @msg output
	if @rcode = 1	goto bspexit
    
    -- validate source PO
    EXEC @rcode = bspPOCopySrcVal @poco, @srcpo, @mth, @batchid, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, @errmsg OUTPUT
    IF @rcode <> 0 
        BEGIN
            SELECT  @msg = @errmsg,
                    @rcode = 1
            GOTO bspexit
        END
    
    -- validate destination PO
    EXEC @rcode = bspPOCopyDestPOUnique @poco, @mth, @batchid, @destpo, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        @errmsg OUTPUT
    IF @rcode <> 0 
        BEGIN
            SELECT  @msg = @errmsg,
                    @rcode = 1
            GOTO bspexit
        END
    
    -- validate HQ company
    SELECT  @vendorgroup = VendorGroup
    FROM    HQCO WITH ( NOLOCK )
    WHERE   HQCo = @poco
    IF @@rowcount = 0 
        BEGIN
            SELECT  @msg = 'Invalid HQ company ' + CONVERT(VARCHAR(3), @poco)
                    + '!',
                    @rcode = 1
            GOTO bspexit
        END
        
    -- create destination PO header POHB if not already in batch
    IF NOT EXISTS ( SELECT  Co
                    FROM    POHB WITH ( NOLOCK )
                    WHERE   Co = @poco
                            AND Mth = @mth
                            AND BatchId = @batchid
                            AND PO = @destpo ) 
        BEGIN
    	
    	-- validate vendor
            SELECT  @vendorsort = CONVERT(VARCHAR(15), @destvendor)
            EXEC @rcode = bspAPVendorVal @poco, @vendorgroup, @vendorsort, 'Y',
                'R', NULL, @vendorpayterms OUTPUT, NULL, NULL, NULL, NULL,
                NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @errmsg OUTPUT
            IF @rcode <> 0 
                BEGIN
                    SELECT  @msg = @errmsg,
                            @rcode = 1
                    GOTO bspexit
                END
    
    	-- validate IN location
            IF @destinloc IS NOT NULL 
                BEGIN
                    EXEC @rcode = bspINLocValForPO @destinco, @destinloc, 'Y',
                        @inaddress OUTPUT, @incity OUTPUT, @instate OUTPUT,
                        @inzip OUTPUT, @inaddress2 OUTPUT, @incountry OUTPUT,
                        NULL, @errmsg OUTPUT
                    IF @rcode <> 0 
                        BEGIN
                            SELECT  @msg = @errmsg,
                                    @rcode = 1
                            GOTO bspexit
                        END
                END
    
    	-- validate JC Job
            IF @destjob IS NOT NULL 
                BEGIN
                    EXEC @rcode = bspJCJMPostVal @destjcco, @destjob,
                        @contract OUTPUT, @jobstatus OUTPUT,
                        @lockedphases OUTPUT, NULL, @jobaddress OUTPUT,
                        @jobcity OUTPUT, @jobstate OUTPUT, @jobzip OUTPUT,
                        NULL, NULL, @jobaddress2 OUTPUT, @jobcountry OUTPUT,
                        NULL, @errmsg OUTPUT
                    IF @rcode <> 0 
                        BEGIN
                            SELECT  @msg = @errmsg,
                                    @rcode = 1
                            GOTO bspexit
                        END
                END
    
    	-- validate PO Ship Location
            IF @destshiploc IS NOT NULL 
                BEGIN
                    EXEC @rcode = bspPOSLVal @poco, @destshiploc,
                        @posladdress OUTPUT, @poslcity OUTPUT,
                        @poslstate OUTPUT, @poslzip OUTPUT, NULL,
                        @posladdress2 OUTPUT, @poslcountry OUTPUT,
                        @errmsg OUTPUT
                    IF @rcode <> 0 
                        BEGIN
                            SELECT  @msg = @errmsg,
                                    @rcode = 1
                            GOTO bspexit
                        END
                END
    
    	-- set destination PO address columns based on default hierarchy
            IF @destshiploc IS NOT NULL 
                BEGIN
    		-- always use ship location address if there is one
                    SELECT  @address = @posladdress,
                            @city = @poslcity,
                            @state = @poslstate,
                            @zip = @poslzip,
                            @address2 = @posladdress2,
                            @country = @poslcountry
                END
            ELSE 
                BEGIN
    		-- use in location address if there is one
                    IF @destinloc IS NOT NULL
                        AND @inaddress IS NOT NULL 
                        BEGIN
                            SELECT  @address = @inaddress,
                                    @city = @incity,
                                    @state = @instate,
                                    @zip = @inzip,
                                    @address2 = @inaddress2,
                                    @country = @incountry
                        END
                    ELSE 
                        BEGIN
    			--use job address if there is one
                            IF @destjob IS NOT NULL 
                                BEGIN
                                    SELECT  @address = @jobaddress,
                                            @city = @jobcity,
                                            @state = @jobstate,
                                            @zip = @jobzip,
                                            @address2 = @jobaddress2,
                                            @country = @jobcountry
                                END
                        END
                END
    
    	-- get next available sequence # for this batch
    
            SELECT  @pohbseq = ISNULL(MAX(BatchSeq), 0) + 1
            FROM    POHB WITH ( NOLOCK )
            WHERE   Co = @poco
                    AND Mth = @mth
                    AND BatchId = @batchid
    
    	-- insert PO
            INSERT  INTO POHB
                    ( Co,
                      Mth,
                      BatchId,
                      BatchSeq,
                      BatchTransType,
                      PO,
                      VendorGroup,
                      Vendor,
                      Description,
                      OrderDate,
                      OrderedBy,
                      ExpDate,
                      Status,
                      JCCo,
                      Job,
                      INCo,
                      Loc,
                      ShipLoc,
                      Address,
                      City,
                      State,
                      Zip,
                      Country, --DC #127571
                      ShipIns,
                      HoldCode,
                      PayTerms,
                      CompGroup,
                      Notes,
                      OldVendorGroup,
                      OldVendor,
                      OldDesc,
                      OldOrderDate,
                      OldOrderedBy,
                      OldExpDate,
                      OldStatus,
                      OldJCCo,
                      OldJob,
                      OldINCo,
                      OldLoc,
                      OldShipLoc,
                      OldAddress,
                      OldCity,
                      OldState,
                      OldZip,
                      OldShipIns,
                      OldHoldCode,
                      OldPayTerms,
                      OldCompGroup,
                      Attention,
                      OldAttention,
                      PayAddressSeq,
                      OldPayAddressSeq,
                      POAddressSeq,
                      OldPOAddressSeq,
                      Address2
                    )
                    SELECT  @poco,
                            @mth,
                            @batchid,
                            @pohbseq,
                            'A',
                            @destpo,
                            @vendorgroup,
                            @destvendor,
                            @destdesc,
                            @destorderdate,
                            @destorderedby,
                            @destexpdate,
                            0,
                            @destjcco,
                            @destjob,
                            @destinco,
                            @destinloc,
                            @destshiploc,
                            @address,
                            @city,
                            @state,
                            @zip,
                            @country,
    			----#136979
                            NULL,
                            NULL,
                            @vendorpayterms,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            @address2
            IF @@rowcount <> 1 
                BEGIN
                    SELECT  @msg = 'Unable to add entry to PO Entry Batch!',
                            @rcode = 1
                    GOTO bspexit
                END
   
    	-- update notes notes if needed
            IF @clearpohdnotes = 'N' 
                BEGIN
                    UPDATE  POHB
                    SET     Notes = b.Notes
                    FROM    POHD b
                    WHERE   b.POCo = @poco
                            AND b.PO = @srcpo
                            AND POHB.Co = @poco
                            AND POHB.Mth = @mth
                            AND POHB.BatchId = @batchid
                            AND POHB.PO = @destpo
                END
     
    	-- update user memos if needed
            IF @clearpohdmemos = 'N' 
                BEGIN
                    EXEC @retcode = bspBatchUserMemoInsertExisting @poco, @mth,
                        @batchid, @pohbseq, 'PO Entry', 0, @errmsg OUTPUT
                END
   
    -- only copy user memos if flagged to be copied
            IF @clearpoitmemos = 'N' 
                BEGIN
   		 -- if copying user memos need to do something different since PO source and destination are different
                    IF EXISTS ( SELECT  name
                                FROM    syscolumns
                                WHERE   name LIKE 'ud%'
                                        AND id = OBJECT_ID('dbo.bPOHB') ) 
                        BEGIN
                            SELECT  @columnname = MIN(ColumnName)
								-- use inline table function for perf
                            FROM    dbo.vfDDFIShared('POEntry')
                            WHERE   FieldType = 4
                                    AND ColumnName LIKE 'ud%'
                            WHILE @columnname IS NOT NULL 
                                BEGIN
	   	 		
                                    SELECT  @updatestring = 'update POHB set '
                                            + @columnname + ' = d.'
                                            + @columnname
                                            + ' from POHD d where d.POCo = '
                                            + CONVERT(VARCHAR(3), @poco)
                                            + ' and d.PO = ' + CHAR(39)
                                            + @srcpo + CHAR(39)
                                            + ' and POHB.Co = '
                                            + CONVERT(VARCHAR(3), @poco)
                                            + ' and POHB.Mth = ' + CHAR(39)
                                            + CONVERT(VARCHAR(100), @mth)
                                            + CHAR(39)
                                            + ' and POHB.BatchId = '
                                            + CONVERT(VARCHAR(10), @batchid)
                                            + ' and POHB.PO = ' + CHAR(39)
                                            + @destpo + CHAR(39)
	   	 
                                    EXEC (@updatestring)
	   	 
                                    SELECT  @columnname = MIN(ColumnName)
										-- use inline table function for perf
                                    FROM    dbo.vfDDFIShared('POEntry')
                                    WHERE   FieldType = 4
                                            AND ColumnName LIKE 'ud%'
                                            AND ColumnName > @columnname
                                    IF @@rowcount = 0 
                                        SELECT  @columnname = NULL
                                END
                        END
                END   
            SELECT  @pocount = @pocount + 1 -- po copy count    
        END
       
    -- get POHB info
    SELECT  @pohbseq = BatchSeq,
            @pohbvendorgroup = VendorGroup,
            @pohbvendor = Vendor,
            @pohbjcco = JCCo,
            @pohbjob = Job,
            @pohbinco = INCo,
            @pohbloc = Loc,
            @pohbshiploc = ShipLoc,
            @pohborderdate = OrderDate,
            @pohbexpdate = ExpDate
    FROM    POHB WITH ( NOLOCK )
    WHERE   Co = @poco
            AND Mth = @mth
            AND BatchId = @batchid
            AND PO = @destpo
    IF @@rowcount = 0 
        BEGIN
            SELECT  @msg = 'Unable to read PO Header Batch Info!',
                    @rcode = 1
            GOTO bspexit
        END
        
   -- create cursor on bPOIT for source PO items flagged to be copied
    DECLARE bcPOIT CURSOR FAST_FORWARD
    FOR
        SELECT  p.POItem
        FROM    POIT p WITH ( NOLOCK )
        WHERE   p.POCo = @poco
                AND p.PO = @srcpo
                AND CHARINDEX(';' + RTRIM(CONVERT(VARCHAR(5), p.POItem)) + ';',
                              @srcpoitems) <> 0
        ORDER BY p.POItem
    
    OPEN bcPOIT
    SELECT  @open_cursor = 1
    
    POIT_loop:
    FETCH NEXT FROM bcPOIT INTO @srcpoitem
    
    IF @@fetch_status <> 0 
        GOTO POIT_end
    
    -- read source po item data from bPOIT
    SELECT  @itemtype = ItemType,
            @matlgroup = MatlGroup,
            @material = Material,
            @vendmatid = VendMatId,
            @poitdesc = Description,
            @um = UM,
            @recvyn = RecvYN,
            @posttoco = PostToCo,
            @loc = Loc,
            @job = Job,
            @phasegroup = PhaseGroup,
            @phase = Phase,
            @jcctype = JCCType,
            @equip = Equip,
            @comptype = CompType,
            @component = Component,
            @emgroup = EMGroup,
            @costcode = CostCode,
            @emctype = EMCType,
            @wo = WO,
            @woitem = WOItem,
            @glco = GLCo,
            @glacct = GLAcct,
            @reqdate = ReqDate,
            @taxgroup = TaxGroup,
            @taxcode = TaxCode,
            @taxtype = TaxType,
            @origunits = ISNULL(OrigUnits, 0),
            @origunitcost = ISNULL(OrigUnitCost, 0),
            @origecm = OrigECM,
            @origcost = ISNULL(OrigCost, 0),
            @origtax = ISNULL(OrigTax, 0),
            @requisitionnum = RequisitionNum,
            @paytype = PayType,
            @paycategory = PayCategory,
   			--DC #129999
            @supplier = Supplier,
            @suppliergroup = SupplierGroup
    FROM    POIT WITH ( NOLOCK )
    WHERE   POCo = @poco
            AND PO = @srcpo
            AND POItem = @srcpoitem
    
    --DC #131948
    SELECT  @poitjcco = NULL
    SELECT  @poitinco = NULL
    SELECT  @poitemco = NULL
    
    -- when item type = 1 job and job assigned in header use
    IF @itemtype = 1 
        BEGIN
            SELECT  @poitjcco = @posttoco  --DC #131948
    	
    	--DC #135180
            IF ISNULL(@pohbjob, '') <> '' 
                BEGIN
                    SELECT  @job = @pohbjob
                END
				
    	-- verify JC Job exists for post to company
            SELECT  @validcnt = COUNT(1)
            FROM    JCJM WITH ( NOLOCK )
            WHERE   JCCo = @posttoco
                    AND Job = @job
            IF @validcnt = 0 
                BEGIN
                    SELECT  @baditems = ISNULL(@baditems, '') + ' PO Item: '
                            + CONVERT(VARCHAR(6), @srcpoitem)
                            + ' not copied. JC Job: ' + ISNULL(@job, '')
                            + ' does not exist!' + CHAR(13)
                    GOTO POIT_loop
                END
        END
    
    -- when item type = 2 location and location assigned in header use
    IF @itemtype = 2 
        BEGIN    	
            SELECT  @poitinco = @posttoco  --DC #131948
    	
    	--DC #135180
            IF ISNULL(@pohbloc, '') <> '' 
                BEGIN
                    SELECT  @loc = @pohbloc
                END
				
    	-- verify IN location exists for post to company
            SELECT  @validcnt = COUNT(1)
            FROM    INLM WITH ( NOLOCK )
            WHERE   INCo = @posttoco
                    AND Loc = @loc
            IF @validcnt = 0 
                BEGIN
                    SELECT  @baditems = ISNULL(@baditems, '') + ' PO Item: '
                            + CONVERT(VARCHAR(6), @srcpoitem)
                            + ' not copied. IN Location: ' + ISNULL(@loc, '')
                            + ' does not exist!' + CHAR(13)
                    GOTO POIT_loop
                END
        END
    
    -- when item type = 3 expense no post to company
    IF @itemtype = 3 
        SELECT  @posttoco = @poco
    
    -- when item type = 4 W0 or 5 Equipment - only copy when copy flags are 'Y'
    IF @itemtype = 4
        AND @copyequipment <> 'Y' 
        GOTO POIT_loop
    IF @itemtype = 5
        AND @copyworkorders <> 'Y' 
        GOTO POIT_loop
    
    -- when item type = 4 Equip check override flag to set equipment values
    IF @itemtype = 4 
        BEGIN
            SELECT  @poitemco = @posttoco  --DC #131948    		
            IF @overrideequip = 'Y' 
                BEGIN
                    SELECT  @posttoco = @ovrequipemco,
                            @equip = @ovrequipment
                    SELECT  @poitemco = @posttoco  --DC #131948
                END
    
    	-- check equipment post cost to component flag
            EXEC @retcode = bspEMEquipValNoComponent @posttoco, @equip, NULL,
                NULL, NULL, NULL, @postcosttocomp OUTPUT, @retmsg OUTPUT
            IF @retcode <> 0 
                SET @postcosttocomp = 'N'
            IF @postcosttocomp <> 'Y' 
                BEGIN
                    SELECT  @comptype = NULL,
                            @component = NULL
                END
        END
    
    -- when item type = 5 WO check override flag to set WO values
    IF @itemtype = 5 
        BEGIN
            SELECT  @poitemco = @posttoco  --DC #131948    		
            IF @overridewo = 'Y' 
                BEGIN
                    SELECT  @posttoco = @ovrwoemco,
                            @wo = @ovrwo
                    SELECT  @poitemco = @posttoco  --DC #131948 
                END
    	
    	-- validate work order items - only copy items that exists for WO
            SELECT  @woequip = NULL,
                    @wocomp = NULL,
                    @wocomptypecode = NULL,
                    @wocostcode = NULL
            EXEC @retcode = bspEMWOItemVal @posttoco, @wo, @woitem, NULL,
                @woequip OUTPUT, NULL, NULL, NULL, NULL, NULL, @wocomp OUTPUT,
                NULL, @wocomptypecode OUTPUT, NULL, NULL, NULL, NULL,
                @wocostcode OUTPUT, NULL, NULL, NULL, NULL, NULL, NULL,
                @retmsg OUTPUT
            IF @retcode <> 0 
                BEGIN
                    SELECT  @baditems = @baditems + ISNULL(@retmsg, '')
                    SELECT  @baditems = ISNULL(@baditems, '') + ' PO Item: '
                            + CONVERT(VARCHAR(6), @srcpoitem)
                            + ' not copied. Problem with WO Item: '
                            + CONVERT(VARCHAR(6), @woitem) + ' !' + CHAR(13)
                    GOTO POIT_loop
                END
    	
    	-- when wo is changed, if wo item valid change component, component type, and cost code
            IF @overridewo = 'Y' 
                BEGIN
                    SET @equip = @woequip
                    SET @comptype = @wocomptypecode
                    SET @component = @wocomp
                    SET @costcode = @wocostcode
                END
        END
    
    -- validate post to company and get groups and glco
    EXEC @retcode = bspPOITCoVal @posttoco, @mth, @itemtype, @glco OUTPUT,
        NULL, @matlgroup OUTPUT, @phasegroup OUTPUT, @taxgroup OUTPUT, NULL,
        NULL, NULL, NULL, @retmsg OUTPUT
    
    -- get appropiate tax code to use for PO items.
    SELECT  @vendortaxcode = NULL,
            @jobtaxcode = NULL,
            @invtaxcode = NULL,
            @posltaxcode = NULL
    EXEC @retcode = bspPOCopyDefaultTaxCodes @poco, @pohbvendorgroup,
        @pohbvendor, @posttoco, @job, @pohbshiploc, @posttoco, @loc,
        @vendortaxcode OUTPUT, @jobtaxcode OUTPUT, @invtaxcode OUTPUT,
        @posltaxcode OUTPUT, @retmsg OUTPUT
    
    IF @itemtype <> 1 
        SET @jobtaxcode = NULL
    -- need to get taxable flag for material
    IF ISNULL(@material, '') <> '' 
        BEGIN
            SELECT  @taxable = Taxable
            FROM    HQMT WITH ( NOLOCK )
            WHERE   MatlGroup = @matlgroup
                    AND Material = @material
            IF @@rowcount = 0 
                SELECT  @taxable = 'Y'
        END
    ELSE
    	-- if no material assume taxable
        SELECT  @taxable = 'Y'
        
   -- get pricing for material in case re-defaulting
    EXEC @retcode = bspHQMatUnitCostDflt @pohbvendorgroup, @pohbvendor,
        @matlgroup, @material, @um, @posttoco, @job, @posttoco, @loc,
        @dfltunitcost OUTPUT, @dfltecm OUTPUT, NULL, @retmsg OUTPUT
    IF @retcode <> 0 
        BEGIN
            SELECT  @dfltunitcost = @origunitcost,
                    @dfltecm = @origecm
        END
   
    IF @dfltunitcost IS NULL 
        SELECT  @dfltunitcost = @origunitcost
    IF @dfltecm IS NULL 
        SELECT  @dfltecm = @origecm
   
    -- set pricing values different if UM = 'LS'
    IF @um = 'LS' 
        BEGIN
            SET @poitunits = 0
            SET @poitunitcost = 0
            SET @poitecm = NULL
            SET @poitcost = @origcost
        END
    ELSE 
        BEGIN
    	-- set item units depending on flag
            IF @setitemunits <> 'Y' 
                SET @poitunits = @origunits
            ELSE 
                SET @poitunits = 1
    
    	-- keep item pricing depending on flag
            IF @keepitemprices <> 'Y' 
                BEGIN
                    SET @poitunitcost = @dfltunitcost
                    SET @poitecm = @dfltecm
                    SET @ecmfactor = CASE @poitecm
                                       WHEN 'C' THEN 100
                                       WHEN 'M' THEN 1000
                                       ELSE 1
                                     END
                    SET @poitcost = @poitunits * ( @poitunitcost / @ecmfactor )
                END
            ELSE 
                BEGIN
                    SET @poitunitcost = @origunitcost
                    SET @poitecm = @origecm
                    SET @ecmfactor = CASE @poitecm
                                       WHEN 'C' THEN 100
                                       WHEN 'M' THEN 1000
                                       ELSE 1
                                     END 
                    SET @poitcost = @poitunits * ( @poitunitcost / @ecmfactor )
                END
        END
        
    -- re-default tax code depending on item type
    IF @taxable = 'N' 
        BEGIN
            SET @taxrate = 0  --DC #135180
            SET @gstrate = 0  --DC #135180    	
            SET @taxtype = NULL
            SET @taxcode = NULL
            SET @poittax = 0
        END
    ELSE 
        BEGIN
            SET @taxrate = 0
            SET @gstrate = 0  --DC #122288
            SET @poittax = 0
            SET @taxtype = ISNULL(@taxtype, 1)
    	-- set tax code based on item type
            IF @itemtype = 1 
                BEGIN
                    SET @taxcode = ISNULL(@jobtaxcode, NULL)
                    GOTO get_tax_rate
                END
            IF @itemtype IN ( 4, 5 ) 
                SET @taxcode = ISNULL(@jobtaxcode, @taxcode)
            ELSE 
                BEGIN
                    IF ISNULL(@posltaxcode, '') <> '' 
                        SET @taxcode = @posltaxcode
                    ELSE 
                        IF @itemtype = 2 
                            SET @taxcode = ISNULL(@invtaxcode, @taxcode)
                    IF @itemtype = 3 
                        SET @taxcode = ISNULL(@vendortaxcode, @taxcode)
                END
   
            get_tax_rate:   	
   		-- get tax rate and calculate tax amount - use order date from POHB as invoice date
		--DC #122288
            EXEC @retcode = vspHQTaxRateGet @taxgroup, @taxcode,
                @pohborderdate, NULL, @taxrate OUTPUT, NULL, NULL,
                @gstrate OUTPUT, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                @retmsg OUTPUT   	
    	-- get tax rate and calculate tax amount - use order date from POHB as invoice date
    	--exec @retcode = bspHQTaxRateGet @taxgroup, @taxcode, @pohborderdate, @taxrate output, null, null, @retmsg output
            IF ISNULL(@taxrate, 0) <> 0 
                BEGIN
                    SET @poittax = @taxrate * @poitcost
                END
        END
            
    -- get the maximum PO item from POIB
    SELECT  @maxpoibitem = 0,
            @maxpoititem = 0,
            @newitem = 0
    SELECT  @maxpoibitem = MAX(POItem)
    FROM    bPOIB WITH ( NOLOCK )
    WHERE   Co = @poco
            AND Mth = @mth
            AND BatchId = @batchid
            AND BatchSeq = @pohbseq
    IF ISNULL(@maxpoibitem, 0) = 0 
        SELECT  @maxpoibitem = 0
    -- get maximum PO item from POIT
    SELECT  @maxpoititem = MAX(POItem)
    FROM    bPOIT WITH ( NOLOCK )
    WHERE   POCo = @poco
            AND PO = @destpo
    IF ISNULL(@maxpoititem, 0) = 0 
        SELECT  @maxpoititem = 0
    
    -- if max poib item > max poit item use plus 1
    IF @maxpoibitem > @maxpoititem 
        SELECT  @newitem = @maxpoibitem + 1
    -- if max poit item > max poib item use plus 1
    IF @maxpoititem > @maxpoibitem 
        SELECT  @newitem = @maxpoititem + 1
    -- if equal use poib item plus 1
    IF @maxpoibitem = @maxpoititem 
        SELECT  @newitem = @maxpoibitem + 1
    IF ISNULL(@newitem, 0) = 0 
        SELECT  @newitem = 1
    
    -- if @newitem exceeds 99999 then throw error
    IF @newitem > 99999 
        BEGIN
            SELECT  @msg = 'Unable to add PO Item: '
                    + CONVERT(VARCHAR(6), @newitem)
                    + ' exceeds maximum number allowed!',
                    @rcode = 1
            GOTO bspexit
        END                
    
    --insert into POIB
    INSERT  POIB
            ( Co,
              Mth,
              BatchId,
              BatchSeq,
              POItem,
              BatchTransType,
              ItemType,
              MatlGroup,
              Material,
              VendMatId,
              Description,
              UM,
              RecvYN,
              PostToCo,
              Loc,
              Job,
              PhaseGroup,
              Phase,
              JCCType,
              Equip,
              CompType,
              Component,
              EMGroup,
              CostCode,
              EMCType,
              WO,
              WOItem,
              GLCo,
              GLAcct,
              ReqDate,
              TaxGroup,
              TaxCode,
              TaxType,
              OrigUnits,
              OrigUnitCost,
              OrigECM,
              OrigCost,
              OrigTax,
              OldItemType,
              OldMatlGroup,
              OldMaterial,
              OldVendMatId,
              OldDesc,
              OldUM,
              OldRecvYN,
              OldPostToCo,
              OldLoc,
              OldJob,
              OldPhaseGroup,
              OldPhase,
              OldJCCType,
              OldEquip,
              OldCompType,
              OldComponent,
              OldEMGroup,
              OldCostCode,
              OldEMCType,
              OldWO,
              OldWOItem,
              OldGLCo,
              OldGLAcct,
              OldReqDate,
              OldTaxGroup,
              OldTaxCode,
              OldTaxType,
              OldOrigUnits,
              OldOrigUnitCost,
              OldOrigECM,
              OldOrigCost,
              OldOrigTax,
              RequisitionNum,
              OldRequisitionNum,
              PayType,
              PayCategory,
   			--DC #129999
              JCCo,
              EMCo,
              INCo,
              Supplier,
              SupplierGroup,
              TaxRate,
              GSTRate
            )  --DC #122288
            SELECT  @poco,
                    @mth,
                    @batchid,
                    @pohbseq,
                    @newitem,
                    'A',
                    @itemtype,
                    @matlgroup,
                    @material,
                    @vendmatid,
                    @poitdesc,
                    @um,
                    @recvyn,
                    @posttoco,
                    @loc,
                    @job,
                    @phasegroup,
                    @phase,
                    @jcctype,
                    @equip,
                    @comptype,
                    @component,
                    @emgroup,
                    @costcode,
                    @emctype,
                    @wo,
                    @woitem,
                    @glco,
                    @glacct,
                    @pohbexpdate,
                    @taxgroup,
                    @taxcode,
                    @taxtype,
                    @poitunits,
                    @poitunitcost,
                    @poitecm,
                    @poitcost,
                    @poittax,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    @requisitionnum,
                    NULL,
                    @paytype,
                    @paycategory,
    	   --DC #129999
                    @poitjcco,
                    @poitemco,
                    @poitinco,
                    @supplier,
                    @suppliergroup,
                    @taxrate,
                    @gstrate  --DC #122288
    IF @@rowcount = 0 
        BEGIN
            SELECT  @msg = 'Unable to add PO Item '
                    + CONVERT(VARCHAR(6), ISNULL(@newitem, 0))
                    + ' to POIB for batch seq '
                    + CONVERT(VARCHAR(6), ISNULL(@pohbseq, 0)),
                    @rcode = 1
            GOTO bspexit
        END
    
    -- po item copy count
    SELECT  @poitemcount = @poitemcount + 1
        
    -- update notes notes if needed
    IF @clearpoitnotes = 'N' 
        BEGIN
            UPDATE  POIB
            SET     Notes = b.Notes
            FROM    POIT b
            WHERE   b.POCo = @poco
                    AND b.PO = @srcpo
                    AND b.POItem = @srcpoitem
                    AND POIB.Co = @poco
                    AND POIB.Mth = @mth
                    AND POIB.BatchId = @batchid
                    AND POIB.BatchSeq = @pohbseq
                    AND POIB.POItem = @newitem
        END
    
    -- only copy user memos if flagged to be copied
    IF @clearpoitmemos = 'N' 
        BEGIN
   	 -- if copying user memos need to do something different since PO items are renumbered
            IF EXISTS ( SELECT  name
                        FROM    syscolumns
                        WHERE   name LIKE 'ud%'
                                AND id = OBJECT_ID('dbo.bPOIB') ) 
                BEGIN
                    SELECT  @columnname = MIN(ColumnName)
						-- use inline table function for perf
                    FROM    dbo.vfDDFIShared('POEntryItems')
                    WHERE   FieldType = 4
                            AND ColumnName LIKE 'ud%'
                    WHILE @columnname IS NOT NULL 
                        BEGIN
   	 		
                            SELECT  @updatestring = 'update POIB set '
                                    + @columnname + ' = d.' + @columnname
                                    + ' from POIT d where d.POCo = '
                                    + CONVERT(VARCHAR(3), @poco)
                                    + ' and d.PO = ' + CHAR(39) + @srcpo
                                    + CHAR(39) + ' and d.POItem = '
                                    + CONVERT(VARCHAR(6), @srcpoitem)
                                    + ' and POIB.Co = '
                                    + CONVERT(VARCHAR(3), @poco)
                                    + ' and POIB.Mth = ' + CHAR(39)
                                    + CONVERT(VARCHAR(100), @mth) + CHAR(39)
                                    + ' and POIB.BatchId = '
                                    + CONVERT(VARCHAR(10), @batchid)
                                    + ' and POIB.BatchSeq = '
                                    + CONVERT(VARCHAR(10), @pohbseq)
                                    + ' and POIB.POItem = '
                                    + CONVERT(VARCHAR(6), @newitem)
   	 
                            EXEC (@updatestring)
   	 
                            SELECT  @columnname = MIN(ColumnName)
                            -- use inline table function for perf
                            FROM    dbo.vfDDFIShared('POEntryItems')
                            WHERE   FieldType = 4
                                    AND ColumnName LIKE 'ud%'
                                    AND ColumnName > @columnname
                            IF @@rowcount = 0 
                                SELECT  @columnname = NULL
                        END
                END
        END
        
    GOTO POIT_loop
            
    POIT_end:
    IF @open_cursor = 1 
        BEGIN
            CLOSE bcPOIT
            DEALLOCATE bcPOIT
            SELECT  @open_cursor = 0
        END
    
    bspexit:
    IF @open_cursor = 1 
        BEGIN
            CLOSE bcPOIT
            DEALLOCATE bcPOIT
            SELECT  @open_cursor = 0
        END
    
    IF @rcode = 0 
        BEGIN
            IF @pocount = 0 
                SELECT  @msg = 'Copied ' + CONVERT(VARCHAR(6), @poitemcount)
                        + ' PO items.' + CHAR(13)
            ELSE 
                SELECT  @msg = 'Copied ' + CONVERT(VARCHAR(6), @pocount)
                        + ' Purchase Order, with '
                        + CONVERT(VARCHAR(6), @poitemcount) + ' PO items.'
                        + CHAR(13)
    
    		-- add any bad items to message
            IF ISNULL(@baditems, '') <> '' 
                SELECT  @msg = @msg + @baditems
        END
    ELSE 
        BEGIN
            SELECT  @msg = @msg + CHAR(13) + CHAR(10) + '[bspPOCopy]'
        END
    
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOCopy] TO [public]
GO
