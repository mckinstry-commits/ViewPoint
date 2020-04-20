SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspRQPOBatchInit    Script Date: 9/22/2004 12:30:53 PM ******/
CREATE     proc [dbo].[bspRQPOBatchInit]
/************************************************
* Created By: DC  9/22/04
* Modified by: DANF 12/21/04 - Issue #26577: Changed reference from DDUP 
*		DC 1/21/05 - Issue 26900:  Initialization is incorrectly updating the Last Used PO# in PO Company
*		DC 4/05/05 - Issue 28354:  Creating multiple PO's when there should only be one; difference when using F4.
*		DC 10/24/07 - 125463: Cannot insert the value NULL into column 'GLCo', table 'bPOIB' - Expense type
*		DC 10/30/07 - 123917:  Needed to change the data type of the Notes column in POIB and 
*						in RQRL.  So I needed to change this sp to match the change in data type.
*		DC 11/14/07 - 124581:  Add a prefix input to be used before the starting PO#
*		TJL 01/29/08 - Issue #126814:  Return EMCO.MatlLastUsedYN value.  Modified params for all DDFI ValProcs using this.
*		DC 02/27/08 - Issue #127117: SQL error on PO initialization
*		DC 03/07/08 - Issue #127567:  Modify PO/RQ  for International addresses
*		DC 03/24/08 - Issue #127046:  Error converting data type varchar to numeric when Item Type=2-Inventory
*		DC 01/13/09 - Issue #131806:  JC Company, IN Company, EM Company not being populated during PO Init
*		DC 12/21/09 - #122288 - Store Tax Rate in POIT
*		GF 09/05/2010 - issue #141031 use function vfDateOnly
*		GF 10/19/2010 - issue #139670 make intelligent default using HQCO.DefaultCountry for the tax type either 1 or 3.
*		ECV 05/25/11 - TK-05443 - Add SMPayType parameter to bspAPPayTypeGet
*		TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*		GP 8/4/2011 - TK-07144 fixed errors from bPO expansion
*		MV 11/4/11 - TK-09070 added NULL output param to bspAPVendorVal
*		GP 4/9/12 - TK-13774 added validation against POUnique view
*		GF 06/04/2012 TK-15373 related to TK-09070 we missed the 2nd validation for AP vendor
*
*
*
* USED IN
*    RQ PO Initialize
*    
* PASS IN
*		RQCo		RQ Company#
*   	INCo		IN Company
*		INLocGrp	IN Location Group
*		INLoc		IN Location
* 	MatlCat		Material Category
*		JCCo		JC Company
*		JCJob		JC Jobs
*		EMCo		EM Company
*		EMShop		EM Shop
*		Vendor		Vendor
*		VendorGrp	Vendor Group
*		LineType	RQ Line Type
*		RQID		RQRH ! RQID
*		ReqDate		Required Date
*		BatchMth	PO Batch Month
* 	HeaderDesc	PO Batch Header Desc
*		PONumber	Starting PO Number
*		POPrefix	Set Prefix for all PO Number created.
*		RecvYN		Receiving YN flag
*
* RETURNS
*   0 on Success
*   1 on ERROR and places error message in msg
**********************************************************/
(@rqco bCompany = 0,@inco bCompany = null, @inlocgrp bGroup = null,@inloc bLoc = null,
 @matlcat varchar(10) = null,@jcco bCompany = null,@jcjob bJob = null,@emco bCompany = null,
 @emshop varchar(20) = null,	@vendor bVendor = null,	@vendorgrp bGroup = null,
 @linetype tinyint = null,@rqid bRQ = null,@reqdate bDate = null, @pobatchmth bDate = null,
 @headerdesc bDesc = null, 
 @ponumber varchar(31), @poprefix varchar(10), --#124581
 @recv bYN, @orderedby varchar(10), @msg varchar(500) output)

as
set nocount on
    
    	Declare @rcode int,
   			@route int,
   			@status int,
   			@glco bCompany,
   			@glacct bGLAcct,
   			@batchseq int,
   			@poheader_desc bDesc, 
   			@poitem bItem,
   			@ltype tinyint,
   			@taxgrp bGroup,
   			@recvyn bYN,
   			@taxcode bTaxCode,
   			@taxtype tinyint,
   			@taxrate bRate,
   			@gstrate bRate, --DC #122288
   			@jobpaytype tinyint,
   			@exppaytype tinyint,
   			@paycategory int,
   			@po varchar(30),
   			@ct_items int,
   			@pocompgroup varchar(10),
   			@restrict bYN,
   			@adjust bYN,
   			@batchid int,
   			@source varchar(10),
   			@tablename varchar(20),
   			@rollback int,
   			@batchmsg varchar(500),
   			@committed int,
   			@transmsg varchar(255),
			@endpo varchar(30), --#124581
			@bpolen int,  --#124581
			@ponumbertwo decimal(30,0),  --#124581
			@lastposeq varchar(31) --#124581
   
   	--Variables needed to get GL Acct and populate PO Header
   	Declare @gl_jcco bCompany, 
   			@gl_job bJob, 
   			@gl_phasegroup bGroup,
   			@gl_phase bPhase,
   			@gl_costtype bJCCType,
   			@gl_inco bCompany,
   			@gl_loc bLoc,
   			@gl_matl bMatl,
   			@gl_matlgrp bGroup,
   			@gl_emco bCompany,
   			@gl_emgroup bGroup,
   			@gl_emctype bEMCType,
   			@gl_costcode bCostCode,
   			@gl_equip bEquip,
   			@gl_shiploc varchar(10) 
   
   	--Variables needed to for PO Header cursor
   	Declare @po_vendorgroup bGroup,
   			@po_vendor bVendor,
    		@po_address varchar(60),
   			@po_attention bDesc, 
   			@po_city varchar(30),
    		@po_state varchar(4), --DC #127567
   			@po_zip bZip, 
   			@po_address2 varchar(60),
			@po_country varchar(2), --DC #127567
        	@po_shipins varchar(60)
   
   	--Variables needed to for PO item cursor
   	Declare @itemc_batchseq int,
   		@itemc_poitem smallint
   
   	--Table variable to hold records from RQRL
   	DECLARE @RQRL_temp TABLE (rqco tinyint, 
   		rqid varchar(10),
   		rqline smallint,
   		linetype tinyint,
   		route tinyint,
   		quote int,
   		expdate smalldatetime,
   		quoteline int,
   		reqdate smalldatetime,
   		po varchar(30),
   		poitem smallint,
   		status tinyint,
   		description varchar(60),
   		jcco tinyint,
   		job varchar(10),
   		jcctype tinyint,
   		inco tinyint,
   		loc varchar(10),
   		shiploc varchar(10),
   		vendorgroup tinyint,
   		vendor int,
   		vendormatlid varchar(30),
   		unitcost numeric(16,5),
   		emco tinyint,
   		wo varchar(10),
   		woitem smallint,
   		emctype tinyint,
   		costcode varchar(10),
   		equip varchar(10),
   		phasegroup tinyint,
   		phase varchar(20),
   		matlgroup tinyint,
   		material varchar(20),
   		um varchar(3),
   		units numeric(12,3),
   		comptype varchar(10),
   		component varchar(10),
   		ecm char(1),
   		notes varchar(max),  --DC 123917
   		address varchar(60),
   		attention varchar(30),
   		city varchar(30),
   		state char(4),  --DC #127567
   		zip varchar(12),
   		address2 varchar(60),
		country varchar(2),  --DC #127567
   		shipins varchar(60),
   		emgroup tinyint,
   		totalcost numeric(12,2),
   		glacct char(20),
   		glco tinyint) 
   
   	--Table variable to hold records to be inserted into bPOHB
   	DECLARE @POHB_temp TABLE (co tinyint, 
   		mth smalldatetime,
   		batchid int,
   		batchseq int,
   		batchtranstype char(1),
   		po varchar(30),
   		vendorgroup tinyint,
   		vendor int,
   		status tinyint,
   		address varchar(60),
   		city varchar(30),
   		state char(4),  --DC #127567
   		zip varchar(12),
		country varchar(2),  --DC #127567
   		shipins varchar(60),
   		attention varchar(30),
   		address2 varchar(60),
   		header_desc varchar(30),
   		order_date smalldatetime,
   		payterms varchar(10),
   		orderedby nvarchar(256),
   		jcco tinyint,
   		job varchar(10),
   		inco tinyint,
   		loc varchar(10),
   		shiploc varchar(10),
   		compgroup varchar(10))
   
   	--Table variable to hold records to be inserted into bPOIB
   	DECLARE @POIB_temp TABLE (co tinyint, 
   		mth smalldatetime,
   		batchid int,
   		batchseq int,
   		po varchar(30),
   		poitem smallint,
   		rqid varchar(10),
   		rqline smallint,
   		batchtranstype char(1),
   		itemtype tinyint,
   		matlgroup tinyint,
   		material varchar(20),
   		vendmatid varchar(30),
   		item_desc varchar(60),
   		um varchar(3),
   		recvyn char(1),
   		posttoco tinyint,
   		emco tinyint,
   		inco tinyint,
   		jcco tinyint,
   		loc varchar(10),
   		shiploc varchar(10),
   		job varchar(10),
   		phasegroup tinyint,
   		phase varchar(20),
   		jcctype tinyint,
   		equip varchar(10),
   		comptype varchar(10),
   		component varchar(10),
   		emgroup tinyint,
   		costcode varchar(10),
   		emctype tinyint,
   		wo varchar(10),
   		woitem smallint,
   		glco tinyint,
   		glacct char(20),
   		reqdate smalldatetime,
   		taxgroup tinyint,
   		taxcode varchar(10),
   		taxrate numeric(8,6),  --DC #122288,
   		gstrate numeric(8,6),  --DC #122288
   		taxtype tinyint,
   		units numeric(12,3),
   		unitcost numeric(16,5),
   		ecm char(1),
   		cost numeric(12,2),
   		tax numeric(12,2),
   		notes varchar(max),  --DC 123917
   		paycategory int,
   		paytype tinyint,
   		status int)
   
   	--Table variable to hold records from RQRL that could not be sent to PO
   	DECLARE @RQRL_error TABLE (rqco tinyint, 
   		rqid varchar(10),
   		rqline smallint,
   		error varchar(255))
   
   if @rqco is null
   	begin
   	select @msg = 'Missing RQ Company', @rcode = 1
   	goto bspexit
   	end
   
   if @pobatchmth is null
   	begin
   	select @msg = 'Missing PO Batch Month', @rcode = 1
   	goto bspexit
   	end
   
   if @ponumber is null
   	begin
   	select @msg = 'Missing Starting PO #', @rcode = 1
   	goto bspexit
   	end
   
   if @recv is null
   	begin
   	select @msg = 'Missing Received YN Flag', @rcode = 1
   	goto bspexit
   	end
   	
   	--validate against POUnique for records in vPOPendingPurchaseOrder
	exec @rcode = dbo.vspPOInitVal @rqco, @ponumber, @msg output
	if @rcode = 1	goto bspexit   	
   
   	SELECT @poheader_desc = @headerdesc
   	SELECT @batchseq = 0
   	SELECT @poitem = 0
   	SELECT @recvyn = @recv
   	SELECT @taxtype = 1 --Sales Tax
   	SELECT @source = 'PO Entry'
   	SELECT @tablename = 'POHB'
   	SELECT @rollback = 0
   	SELECT @rcode = 0
   	SELECT @status = 4 --Approved for Purchase
   	SELECT @route = 2
	SELECT @bpolen = 30

   /*****************************************************************
   	Populate the temp table with the Requisition lines 
   	that have a status of Approved for Purchase
   ******************************************************************/
   INSERT INTO @RQRL_temp (rqco, rqid,	rqline,	linetype, route, quote,	expdate, quoteline,	reqdate,
   		status,	description,jcco,job,jcctype,inco,loc,shiploc,vendorgroup,vendor,
   		vendormatlid,unitcost,emco,	wo,	woitem,	emctype,costcode,equip,	phasegroup,	phase,
   		matlgroup,material,	um,	units,comptype,component,ecm,notes,	address,attention,city,
   		state,zip,address2,country,	--DC #127567
		shipins,emgroup,totalcost,glacct, glco)
   		--Get all the requisition lines (filtered by the passed in filters) 
   		SELECT l.RQCo,l.RQID,l.RQLine,l.LineType,l.Route,l.Quote,l.ExpDate,l.QuoteLine,l.ReqDate,
   			l.Status,l.Description,l.JCCo,l.Job,l.JCCType,l.INCo,l.Loc,l.ShipLoc,isnull(l.VendorGroup,''),isnull(l.Vendor,''),
   			l.VendorMatlId,l.UnitCost,l.EMCo,l.WO,l.WOItem,l.EMCType,l.CostCode,l.Equip,l.PhaseGroup,l.Phase,
   			l.MatlGroup,l.Material,l.UM,l.Units,l.CompType,l.Component,l.ECM,l.Notes,isnull(l.Address,''),isnull(l.Attention,''),isnull(l.City,''),
   			isnull(l.State,''),isnull(l.Zip,''),isnull(l.Address2,''),isnull(l.Country,''), --DC #127567
			isnull(l.ShipIns,''),l.EMGroup,l.TotalCost,l.GLAcct,l.GLCo
   		FROM RQRL l
   			LEFT JOIN HQMT t ON l.Material = t.Material and l.MatlGroup = t.MatlGroup
   			LEFT JOIN INLM m ON l.INCo = m.INCo and l.Loc = m.Loc
   			LEFT JOIN EMWH w ON w.EMCo = l.EMCo and w.WorkOrder = l.WO
   		WHERE l.PO IS NULL 
   			AND l.Route <> @route  --Not Stock
   			AND l.Status = @status  --Approved for Purchase
   			AND l.RQCo = @rqco
   			--Filters passed in
   			AND ISNULL(l.INCo, '') = ISNULL(@inco,ISNULL(l.INCo,''))
   			AND ISNULL(m.LocGroup,'') = ISNULL(@inlocgrp,ISNULL(m.LocGroup,''))
   			AND ISNULL(l.Loc, '') = ISNULL(@inloc,ISNULL(l.Loc,''))
   			AND ISNULL(t.Category,'') = ISNULL(@matlcat,ISNULL(t.Category,''))
   			AND ISNULL(l.JCCo, '') = ISNULL(@jcco,ISNULL(l.JCCo,''))
   			AND ISNULL(l.Job, '') = ISNULL(@jcjob,ISNULL(l.Job,''))
   			AND ISNULL(l.EMCo, '') = ISNULL(@emco,ISNULL(l.EMCo,''))
   			AND ISNULL(w.Shop, '') = ISNULL(@emshop,ISNULL(w.Shop,''))
   			AND ISNULL(l.Vendor, '') = ISNULL(@vendor,ISNULL(l.Vendor,''))
   			AND ISNULL(l.VendorGroup, '') = ISNULL(@vendorgrp,ISNULL(l.VendorGroup,''))
   			AND ISNULL(l.LineType, '') = ISNULL(@linetype,ISNULL(l.LineType,''))
   			AND ISNULL(l.RQID, '') = ISNULL(@rqid,ISNULL(l.RQID,''))
   			AND ISNULL(l.ReqDate, '') <= ISNULL(@reqdate,ISNULL(l.ReqDate,''))
   	IF @@error <> 0 
   		BEGIN
   		SELECT @msg = 'Error creating RQRL table variable', @rcode = 1
   		GOTO bspexit
   		END
   
   /*****************************************************************
   	Spin through those records and pull out the ones that are 
   	not ready for po because they are missing required info.
   ******************************************************************/
   	-- Check for VendorGroup, Vendor, MatlGroup
   		--Insert Error
   		INSERT INTO @RQRL_error(rqco,rqid,rqline,error)
   			SELECT l.rqco,
   					l.rqid,
   					l.rqline,
   					Case 
   						WHEN l.vendorgroup IS NULL THEN 'Missing Vendor Group'
   						WHEN l.vendor IS NULL THEN 'Missing Vendor'
   						WHEN l.matlgroup IS NULL THEN 'Missing Material Group'
   					END
   			FROM @RQRL_temp l
   			WHERE l.vendorgroup IS NULL 
   				OR l.vendor IS NULL 
   				OR l.matlgroup IS NULL 
   
   		--Delete 
   		DELETE @RQRL_temp
   		WHERE vendorgroup IS NULL 
   			OR vendor IS NULL 
   			OR matlgroup IS NULL
   
   	/************************************************************
    	Create a cursor from req's that group by the fields needed 
   	for the PO Batch Header
   	*************************************************************/
       declare POHeader_c cursor for
   		select vendorgroup,vendor,address,attention,city,state,zip,address2,country,shipins
   		from @RQRL_temp
   		group by vendorgroup,vendor,address,attention,city,state,zip,address2,country,shipins
   
       OPEN POHeader_c
       FETCH NEXT FROM POHeader_c
       into @po_vendorgroup, @po_vendor, @po_address, @po_attention, @po_city, @po_state, @po_zip, @po_address2, @po_country, @po_shipins
   
       While (@@FETCH_STATUS = 0)
       Begin 	
   
   		SELECT @batchseq = @batchseq + 1	
   		SELECT @poitem = 0
   	/*******************************************************
   	Populate PO Batch header table variable from cursor row
   	******************************************************/
   	INSERT INTO @POHB_temp (co, mth, batchseq, batchtranstype, vendorgroup, vendor, status, address, city,
   		state, zip, shipins, attention, address2, country, header_desc, order_date,payterms, orderedby) 
   		SELECT TOP 1 @rqco, @pobatchmth, @batchseq, 'A', @po_vendorgroup, @po_vendor, 0, @po_address, @po_city,
   			@po_state, @po_zip, @po_shipins, @po_attention, @po_address2, @po_country, @poheader_desc,
   			----#141031
   			dbo.vfDateOnly(),
   			a.PayTerms, @orderedby
   		FROM @RQRL_temp l
   			LEFT JOIN APVM a ON a.VendorGroup = l.vendorgroup and a.Vendor = l.vendor
   		WHERE l.vendorgroup = @po_vendorgroup
   			AND l.vendor = @po_vendor
   			AND l.address = @po_address
   			AND l.attention = @po_attention
   			AND l.city = @po_city
   			AND l.state = @po_state
   			AND l.zip = @po_zip
   			AND l.address2 = @po_address2
   			AND l.shipins = @po_shipins
			AND l.country = @po_country
   	IF @@error <> 0 
   		BEGIN
   		SELECT @msg = 'Error creating PO Header table variable', @rcode = 1
   	    CLOSE POHeader_c
       	DEALLOCATE POHeader_c
   		GOTO bspexit
   		END
   
   	/*******************************************************
   	Populate PO Batch Item table variable from cursor row
   	******************************************************/
   	INSERT INTO @POIB_temp (co, mth, batchseq, rqid, rqline, batchtranstype, itemtype, matlgroup,
   			material, vendmatid, item_desc, um, loc, shiploc, inco, jcco, emco, job, phasegroup, phase,
   			jcctype, equip, comptype, component, emgroup, costcode, emctype, wo, woitem, 
   			reqdate, units, unitcost, ecm, cost, notes, glco, glacct, status)  
   		SELECT @rqco, @pobatchmth, @batchseq, l.rqid, l.rqline, 'A', l.linetype, l.matlgroup, 
   			l.material, l.vendormatlid, l.description, l.um, l.loc, l.shiploc, l.inco, l.jcco, l.emco, l.job, l.phasegroup, l.phase,
   			l.jcctype, l.equip, l.comptype, l.component, l.emgroup, l.costcode, l.emctype, l.wo, l.woitem,
   			l.reqdate, l.units, l.unitcost, l.ecm, l.totalcost, l.notes, l.glco , l.glacct, 1
   		FROM @RQRL_temp l
   		WHERE l.vendorgroup = @po_vendorgroup
   			AND l.vendor = @po_vendor
   			AND l.address = @po_address
   			AND l.attention = @po_attention
   			AND l.city = @po_city
   			AND l.state = @po_state
   			AND l.zip = @po_zip
   			AND l.address2 = @po_address2
   			AND l.shipins = @po_shipins
			AND l.country = @po_country
   	IF @@error <> 0 
   		BEGIN
   		SELECT @msg = 'Error creating PO Item table variable', @rcode = 1
   	    CLOSE POHeader_c
       	DEALLOCATE POHeader_c
   		GOTO bspexit
   		END
   
   	/*******************************************************
   	Set POItem for all records in POIB_temp with status = 1
   	******************************************************/
   	UPDATE @POIB_temp
   	SET poitem = @poitem, @poitem = @poitem + 1
   	WHERE status = 1
   
   	/****************************************************
   	Create cursor from POIB_temp to cycle through to edit
   	the records one at a time
   	****************************************************/
   	    declare POItem_c cursor for
   			select batchseq, poitem
   			from @POIB_temp
   			where status = 1
   	
   	    OPEN POItem_c
   	    FETCH NEXT FROM POItem_c
   	    into @itemc_batchseq, @itemc_poitem 
   
   	    While (@@FETCH_STATUS = 0)
   	    BEGIN 	
   			/********************************************
   			Clear the @gl... varables 
   			*********************************************/
   			select 	@glacct = NULL,
   					@glco = NULL,
   					@taxgrp = NULL,
   					@taxcode = NULL,
   					@taxrate = NULL,
   					@gstrate = NULL,  --DC #122288
   					@jobpaytype = NULL,
   	 				@paycategory = NULL,
   					@exppaytype = NULL
   			
   			/***********************************************
   			populate the following fields in POIB_temp
   				GLCo  - if not null
   				GLAcct - if not null
   				RecvYN
   				PostToCo
   				Tax
   				taxgroup
   				taxcode 
   				taxrate
   				gstrate
   				taxtype 
   				paycategory
   				paytype
   			************************************************/
   			SELECT @ltype = itemtype, 
   					@gl_jcco = jcco, 
   					@gl_job = job, 
   					@gl_phasegroup = phasegroup,
   					@gl_phase = phase,
   					@gl_costtype = jcctype,
   					@gl_inco = inco,
   					@gl_loc = loc,
   					@gl_matl = material,
   					@gl_matlgrp = matlgroup,
   					@gl_emco = emco,
   					@gl_emgroup = emgroup,
   					@gl_emctype = emctype,
   					@gl_costcode = costcode,
   					@gl_equip = equip,
   					@gl_shiploc = shiploc
   			FROM @POIB_temp
   			WHERE batchseq = @itemc_batchseq
   				AND poitem = @itemc_poitem
   	
   			IF @ltype = 1  -- 1 = Job
   				BEGIN 
   
   				--get GLCo and TaxGroup
   				EXEC @rcode = bspPOITCoVal @gl_jcco, null, @ltype, @glco output, null, null,
   				 	  null, @taxgrp output, null, null, null, null, @msg output
   				IF @rcode = 1 
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error getting GLCo and TaxGroup', @rcode = 1
   					GOTO bsperror
   					END
   
   				--get GLAcct
   				exec bspJCCAGlacctDflt @gl_jcco, @gl_job, @gl_phasegroup,@gl_phase, @gl_costtype,'Y',@glacct output, @msg output	
   
   				--get TaxCode from Job Master if Base Tax on is Tax.  Get Vendor Tax Code if Job Master base tax on is Vendor.  If no tax code then no tax				
   				exec @rcode = bspPOJobVal @gl_jcco, @gl_job, @po_vendorgroup, @po_vendor, null,
   					null, null, @taxcode output, @msg output
   				IF @rcode = 1 
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error getting TaxCode', @rcode = 1
   					GOTO bsperror
   					END
   
   				--Get tax Rate
   				SET @taxtype = 1 ---- sales tax type default #139670
   				IF @taxcode is not null
   					BEGIN   					
					--DC #122288
					exec @rcode = vspHQTaxRateGet @taxgrp, @taxcode, NULL, NULL, @taxrate output, NULL, NULL, 
						@gstrate output, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @msg output
   					/*exec @rcode = bspHQTaxRateGet @taxgrp, @taxcode, null, @taxrate output, null,
   						null, @msg output*/
   					IF @rcode = 1 
   						BEGIN
   						SELECT @msg = @msg + char(13) + '.  Error getting Tax Rate', @rcode = 1
   						GOTO bsperror
   						END
   						
   					---- #139670 look at the HQCO for RQCo to get the default country to decide if 1- Sales or 3 - VAT tax type
   					IF EXISTS(SELECT TOP 1 1 FROM dbo.bHQCO WHERE HQCo = @rqco AND DefaultCountry <> 'US')
   						BEGIN
   						SET @taxtype = 3 ---- VAT
   						END
   					END
   				ELSE
   					BEGIN
   					SELECT @taxrate = 0
   					SELECT @gstrate = 0  --DC #122288
   					END
   
   				--get paycategory and paytype if PO Entry uses PayTypes
   				if exists(select 1 from POCO where POCo = @rqco and PayTypeYN = 'Y')
   					BEGIN
   					EXEC @rcode = bspAPPayTypeGet @rqco, null, null, @jobpaytype output, null, null,
   	 					null, null, null, @paycategory output, @msg output
   					IF @rcode = 1 
   						BEGIN
   						SELECT @msg = @msg + char(13) + '.  Error getting Pay Type and Pay Category', @rcode = 1
   						GOTO bsperror
   						END
   					END
   				
   				--update @POIB_temp
   				UPDATE @POIB_temp
   				SET posttoco = jcco, 
   					recvyn = @recvyn, 
   					taxtype = @taxtype,
   					glco = @glco, 
   					taxgroup = @taxgrp,
   					glacct = @glacct,
   					taxcode = @taxcode,
   					tax = @taxrate * cost,
   					taxrate = @taxrate,  --DC #122288
   					gstrate = @gstrate,  --DC #122288
   					paycategory = @paycategory, 
   					paytype = @jobpaytype
   				FROM @POIB_temp
   				WHERE batchseq = @itemc_batchseq
   					AND poitem = @itemc_poitem
   				
   				END
   
   			IF @ltype = 2  -- 2 = Inventory
   				BEGIN
   				--get GLCo and TaxGroup
   				EXEC @rcode = bspPOITCoVal @gl_inco, null, @ltype, @glco output, null, null,
   				 	  null, @taxgrp output, null, null,null, null, @msg output
   				IF @rcode = 1 
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error getting GLCo and TaxGroup', @rcode = 1
   					GOTO bsperror
   					END
   
   				--get GLAcct
   				exec @rcode = bspINGlacctDflt @gl_inco, @gl_loc, @gl_matl, @gl_matlgrp, @glacct output, null, @msg output
   				IF @rcode = 1 
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error getting Default GL Account', @rcode = 1
   					GOTO bsperror
   					END
   
   				--get TaxCode	
   				exec @rcode = bspINLocMatlValForPO @gl_inco, @gl_loc, @gl_matl, @gl_matlgrp, null, null, null, null, null, @taxcode output, null, null, @msg output  --DC #127046
   				IF @rcode = 1 
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error getting TaxCode', @rcode = 1
   					GOTO bsperror
   					END
   
				SET @taxtype = 1 ----sales tax type default #139670
   				IF @taxcode is not null
   					BEGIN
   					--Get tax Rate and update TotalCost
					--DC #122288
					exec @rcode = vspHQTaxRateGet @taxgrp, @taxcode, NULL, NULL, @taxrate output, NULL, NULL, 
						@gstrate output, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @msg output   					
   					/*exec @rcode = bspHQTaxRateGet @taxgrp, @taxcode, null, @taxrate output, null,
   						null, @msg output*/
   					IF @rcode = 1 
   						BEGIN
   						SELECT @msg = @msg + char(13) + '.  Error getting Tax Rate', @rcode = 1
   						GOTO bsperror
   						END
					---- #139670 look at the HQCO for RQCo to get the country to decide if 1- Sales or 3 - VAT tax type
   					IF EXISTS(SELECT TOP 1 1 FROM dbo.bHQCO WHERE HQCo = @rqco AND DefaultCountry <> 'US')
   						BEGIN
   						SET @taxtype = 3 ---- VAT
   						END
   					END
   				ELSE
   					BEGIN
   					SELECT @taxrate = 0
   					SELECT @gstrate = 0  --DC #122288
   					END
   
   				--get paycategory and paytype if PO Entry uses PayTypes
   				if exists(select 1 from POCO where POCo = @rqco and PayTypeYN = 'Y')
   					BEGIN
   					EXEC @rcode = bspAPPayTypeGet @rqco, null, @exppaytype output, null, null,
   	 					null, null, null, @paycategory output, @msg output
   					IF @rcode = 1 
   						BEGIN
   						SELECT @msg = @msg + char(13) + '.  Error getting Pay Type and Pay Category', @rcode = 1
   						GOTO bsperror
   						END
   					END
   
   				--update @POIB_temp
   				UPDATE @POIB_temp
   				SET posttoco = inco, 
   					recvyn = @recvyn, 
   					taxtype = @taxtype,
   					glco = @glco,
   				 	taxgroup = @taxgrp,
   					glacct = @glacct,
   					taxcode = @taxcode,
   					tax = @taxrate * cost,
   					taxrate = @taxrate,  --DC #122288
   					gstrate = @gstrate,  --DC #122288
   					paycategory = @paycategory, 
   					paytype = @exppaytype
   				FROM @POIB_temp
   				WHERE batchseq = @itemc_batchseq
   					AND poitem = @itemc_poitem
   
   				END
      
   			IF @ltype = 3  -- 3 = Expense
   				BEGIN
   				--get GLCo and TaxGroup
   				EXEC @rcode = bspPOITCoVal @rqco, null, @ltype, @glco output, null, null,
   				 	  null, @taxgrp output, null, null, null, null, @msg output
   				IF @rcode = 1 
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error getting GLCo and TaxGroup', @rcode = 1
   					GOTO bsperror
   					END
				--DC 125463
				IF @glco is null
					BEGIN
					SELECT @glco= isnull(GLCo,@rqco)	
					FROM APCO
					WHERE APCo = @rqco				
					END
   
   				--get GLAcct
   				exec bspAPGlacctDflt @po_vendorgroup, @po_vendor, @gl_matlgrp, @gl_matl, @glacct output, @msg output
   				IF @@Error <> 0 
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error getting Default GL Account', @rcode = 1
   					GOTO bsperror
   					END
   
   				--get TaxCode
   				exec @rcode = bspAPVendorVal @rqco, @po_vendorgroup, @po_vendor, 'X', 'X', null, null,
   					null, null, null, null, null, null, null, null, null, null, null, @taxcode output,NULL, @msg OUTPUT
   				IF @rcode = 1 
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error getting TaxCode', @rcode = 1
   					GOTO bsperror
   					END
   
				SET @taxtype = 1 ----sales tax type default #139670
   				IF @taxcode is not null
   					BEGIN
					--DC #122288
					exec @rcode = vspHQTaxRateGet @taxgrp, @taxcode, NULL, NULL, @taxrate output, NULL, NULL, 
						@gstrate output, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @msg output   					
   					--Get tax Rate and update TotalCost
   					/*exec @rcode = bspHQTaxRateGet @taxgrp, @taxcode, null, @taxrate output, null,
   						null, @msg output*/
   					IF @rcode = 1 
   						BEGIN
   						SELECT @msg = @msg + char(13) + '.  Error getting Tax Rate', @rcode = 1
   						GOTO bsperror
   						END
					---- #139670 look at the HQCO for RQCo to get the country to decide if 1- Sales or 3 - VAT tax type
   					IF EXISTS(SELECT TOP 1 1 FROM dbo.bHQCO WHERE HQCo = @rqco AND DefaultCountry <> 'US')
   						BEGIN
   						SET @taxtype = 3 ---- VAT
   						END
   					END
   				ELSE
   					BEGIN
   					SELECT @taxrate = 0
   					SELECT @gstrate = 0  --DC #122288
   					END
   
   				--get paycategory and paytype if PO Entry uses PayTypes
   				if exists(select 1 from POCO where POCo = @rqco and PayTypeYN = 'Y')
   					BEGIN
   					EXEC @rcode = bspAPPayTypeGet @rqco, null, @exppaytype output, null, null,
   	 					null, null, null, @paycategory output, @msg output
   					IF @rcode = 1 
   						BEGIN
   						SELECT @msg = @msg + char(13) + '.  Error getting Pay Type and Pay Category', @rcode = 1
   						GOTO bsperror
   						END
   					END
   
   				--update @POIB_temp
   				UPDATE @POIB_temp
   				SET recvyn = @recvyn, 
   					taxtype = @taxtype,
   					taxgroup = @taxgrp,
   					posttoco = @glco, --DC 125463
   					taxcode = @taxcode,
   					tax = @taxrate * cost,
   					taxrate = @taxrate,  --DC #122288
   					gstrate = @gstrate,  --DC #122288   					
   					paycategory = @paycategory,
   					paytype = @exppaytype,
   					glco = @glco, --DC 125463
   					glacct = isnull(glacct,@glacct)
   				FROM @POIB_temp
   				WHERE batchseq = @itemc_batchseq
   					AND poitem = @itemc_poitem
   
   				END
   
   			IF @ltype = 4  -- 4 = Equipment
   				BEGIN 
   				--get GLCo and TaxGroup
   				EXEC @rcode = bspPOITCoVal @gl_emco, null, @ltype, @glco output, null, null,
   				 	  null, @taxgrp output, null, null,null, null, @msg output
   				IF @rcode = 1 
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error getting GLCo and TaxGroup', @rcode = 1
   					GOTO bsperror
   					END
   				
   				--get GLAcct
   				exec @rcode = bspEMCostTypeValForCostCode @gl_emco, @gl_emgroup, @gl_emctype, @gl_costcode, @gl_equip,
   					'N', null, @glacct output, @msg output
   				IF @rcode = 1 
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error getting Default GL Account', @rcode = 1
   					GOTO bsperror
   					END
   					
   				--get TaxCode
   				exec @rcode = bspAPVendorVal @rqco, @po_vendorgroup, @po_vendor, 'X', 'X', null, null,
   					null, null, null, null, null, null, null, null, null, null, null, @taxcode output,
   					----TK-15373
   					NULL, @msg output
   				IF @rcode = 1 
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error getting TaxCode', @rcode = 1
   					GOTO bsperror
   					END
   				
   				--Get tax Rate
   				SET @taxtype = 1 ---- sales tax type default #139670
   				IF @taxcode is not null
   					BEGIN
					--DC #122288
					exec @rcode = vspHQTaxRateGet @taxgrp, @taxcode, NULL, NULL, @taxrate output, NULL, NULL, 
						@gstrate output, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @msg output   					
   					/*exec @rcode = bspHQTaxRateGet @taxgrp, @taxcode, null, @taxrate output, null,
   						null, @msg output*/
   					IF @rcode = 1 
   						BEGIN
   						SELECT @msg = @msg + char(13) + '.  Error getting Tax Rate', @rcode = 1
   						GOTO bsperror
   						END
					---- #139670 look at the HQCO for RQCo to get the country to decide if 1- Sales or 3 - VAT tax type
   					IF EXISTS(SELECT TOP 1 1 FROM dbo.bHQCO WHERE HQCo = @rqco AND DefaultCountry <> 'US')
   						BEGIN
   						SET @taxtype = 3 ---- VAT
   						END
   					END
   				ELSE
   					BEGIN
   					SELECT @taxrate = 0
   					SELECT @gstrate = 0  --DC #122288
   					END
   
   				--Get paycategory and paytype if PO Entry uses PayTypes
   				if exists(select 1 from POCO where POCo = @rqco and PayTypeYN = 'Y')
   					BEGIN
   					EXEC @rcode = bspAPPayTypeGet @rqco, null, @exppaytype output, null, null,
   	 					null, null, null, @paycategory output, @msg output
   					IF @rcode = 1 
   						BEGIN
   						SELECT @msg = @msg + char(13) + '.  Error getting Pay Type and Pay Category', @rcode = 1
   						GOTO bsperror
   						END
   					END
   
   				--update @POIB_temp
   				UPDATE @POIB_temp
   				SET posttoco = emco, 
   					recvyn = @recvyn, 
   					taxtype = @taxtype,
   					glco = @glco, 
   					taxgroup = @taxgrp,
   					glacct = @glacct,
   					taxcode = @taxcode,
   					tax = @taxrate * cost,
   					taxrate = @taxrate,  --DC #122288
   					gstrate = @gstrate,  --DC #122288   					
   					paycategory = @paycategory, 
   					paytype = @exppaytype
   				FROM @POIB_temp
   				WHERE batchseq = @itemc_batchseq
   					AND poitem = @itemc_poitem
   
   				END	
   
   			IF @ltype = 5  -- 5 = Work Order
   				BEGIN 
   				--get GLCo and TaxGroup
   				EXEC @rcode = bspPOITCoVal @gl_emco, null, @ltype, @glco output, null, null,
   				 	  null, @taxgrp output, null, null,null, null, @msg output
   				IF @rcode = 1 
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error getting GLCo and TaxGroup', @rcode = 1
   					GOTO bsperror
   					END
   
   				--get GLAcct
   				exec @rcode = bspEMCostTypeValForCostCode @gl_emco, @gl_emgroup, @gl_emctype, @gl_costcode, @gl_equip,
   					'N', null, @glacct output, @msg output
   				IF @rcode = 1 
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error getting Default GL Account', @rcode = 1
   					GOTO bsperror
   					END
   
   				--get TaxCode
   				exec @rcode = bspAPVendorVal @rqco, @po_vendorgroup, @po_vendor, 'X', 'X', null, null,
   					null, null, null, null, null, null, null, null, null, null, null, @taxcode output, @msg output
   				IF @rcode = 1 
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error getting TaxCode', @rcode = 1
   					GOTO bsperror
   					END
   
   				--Get tax Rate
   				SET @taxtype = 1 ----sales tax type default #139670
   				IF @taxcode is not null
   					BEGIN
					--DC #122288
					exec @rcode = vspHQTaxRateGet @taxgrp, @taxcode, NULL, NULL, @taxrate output, NULL, NULL, 
						@gstrate output, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @msg output   					
   					/*exec @rcode = bspHQTaxRateGet @taxgrp, @taxcode, null, @taxrate output, null,
   						null, @msg output*/
   					IF @rcode = 1 
   						BEGIN
   						SELECT @msg = @msg + char(13) + '.  Error getting Tax Rate', @rcode = 1
   						GOTO bsperror
   						END
					---- #139670 look at the HQCO for RQCo to get the country to decide if 1- Sales or 3 - VAT tax type
   					IF EXISTS(SELECT TOP 1 1 FROM dbo.bHQCO WHERE HQCo = @rqco AND Country <> 'US')
   						BEGIN
   						SET @taxtype = 3 ---- VAT
   						END
   					END
   				ELSE
   					BEGIN
   					SELECT @taxrate = 0
   					SELECT @gstrate = 0  --DC #122288
   					END
   
   				--Get paycategory and paytype if PO Entry uses PayTypes
   				if exists(select 1 from POCO where POCo = @rqco and PayTypeYN = 'Y')
   					BEGIN
   					EXEC @rcode = bspAPPayTypeGet @rqco, null, @exppaytype output, null, null,
   	 					null, null, null, @paycategory output, @msg output
   					IF @rcode = 1 
   						BEGIN
   						SELECT @msg = @msg + char(13) + '.  Error getting Pay Type and Pay Category', @rcode = 1
   						GOTO bsperror
   						END
   					END
   
   				--update @POIB_temp
   				UPDATE @POIB_temp
   				SET posttoco = emco,
   					recvyn = @recvyn, 
   					taxtype = @taxtype,
   					glco = @glco, 
   					taxgroup = @taxgrp,
   					glacct = @glacct,
   					taxcode = @taxcode,
   					tax = @taxrate * cost,
   					taxrate = @taxrate,  --DC #122288
   					gstrate = @gstrate,  --DC #122288   					
   					paycategory = @paycategory,
   					paytype = @exppaytype
   				FROM @POIB_temp
   				WHERE batchseq = @itemc_batchseq
   					AND poitem = @itemc_poitem
   
   				END
   		
   		--update status to = 0  
   		UPDATE @POIB_temp
   		SET status = 0
   		FROM @POIB_temp
   		WHERE batchseq = @itemc_batchseq
   			AND poitem = @itemc_poitem
   
   
   	    FETCH NEXT FROM POItem_c
   	    into @itemc_batchseq, @itemc_poitem 
   	    END
   	
   	    CLOSE POItem_c
   	    DEALLOCATE POItem_c
   
   	/************************************************
   	Update @POHB_temp if all the items are the same type
   	and have the same info 
   	*************************************************/
   	--Check to see if all items are the same type
   	SELECT @ct_items = count(1)
   	FROM @POIB_temp
   	Where batchseq = @batchseq
   		AND @ltype <> itemtype
   
   	IF @ct_items = 0 
   		BEGIN
   		--check to see if all items have the same JCCo
   		SELECT @ct_items = count(1)
   		FROM @POIB_temp
   		Where batchseq = @batchseq
   			AND @gl_jcco <> jcco
   		IF @ct_items = 0 
   			BEGIN
   			UPDATE @POHB_temp
   			SET jcco = @gl_jcco
   			WHERE batchseq = @batchseq
   			--check to see if all items have the same Job
   			SELECT @ct_items = count(1)
   			FROM @POIB_temp
   			Where batchseq = @batchseq
   				AND jcco = @gl_jcco
   				AND @gl_job <> job
   			IF @ct_items = 0 
   				BEGIN
   				--Get comp Group for job
   				SELECT @pocompgroup = POCompGroup
   				FROM JCJM
   				WHERE JCCo = @gl_jcco
   					AND Job = @gl_job
   				--update Job and Comp Group
   				UPDATE @POHB_temp
   				SET job = @gl_job, compgroup = @pocompgroup
   				WHERE batchseq = @batchseq
   				END
   			END
   		--check to see if all items have the same INCo
   		SELECT @ct_items = count(1)
   		FROM @POIB_temp
   		Where batchseq = @batchseq
   			AND @gl_inco <> inco
   		IF @ct_items = 0 
   			BEGIN
   			UPDATE @POHB_temp
   			SET inco = @gl_inco
   			WHERE batchseq = @batchseq
   			--check to see if all items have the same IN Loc
   			SELECT @ct_items = count(1)
   			FROM @POIB_temp
   			Where batchseq = @batchseq
   				AND @gl_inco = inco
   				AND @gl_loc <> loc
   			IF @ct_items = 0
   				BEGIN
   				UPDATE @POHB_temp
   				SET loc = @gl_loc
   				WHERE batchseq = @batchseq
   					AND @gl_inco = inco
   				END
   			END
   		--check to see if all items have the same Ship Loc
   		SELECT @ct_items = count(1)
   		FROM @POIB_temp
   		Where batchseq = @batchseq
   			AND @gl_shiploc <> shiploc
   		IF @ct_items = 0 
   			BEGIN
   			UPDATE @POHB_temp
   			SET shiploc = @gl_shiploc
   			WHERE batchseq = @batchseq
   			END
   
   		END
   
       FETCH NEXT FROM POHeader_c
       into @po_vendorgroup, @po_vendor, @po_address, @po_attention, @po_city, @po_state, @po_zip, @po_address2,@po_country,@po_shipins
       end
   
       CLOSE POHeader_c
       DEALLOCATE POHeader_c
   
   	--IF there are any records in POHB_temp then start transaction to add records
   	IF exists(select 1 from @POHB_temp)
   	BEGIN
   		/************************************************
   		Get Batchid
   		************************************************/
   		/* Get Restricted batch default from DDUP */
   		SELECT @restrict = isnull(RestrictedBatches,'N')
   		FROM dbo.vDDUP with (nolock)
   		WHERE VPUserName = SUSER_SNAME() 
   		IF @@rowcount <> 1 and (SUSER_SNAME()<>'bidtek' and SUSER_SNAME()<>'viewpointcs' )
   			BEGIN
   			SELECT @msg = @msg + char(13) + 'Missing user: ' + SUSER_SNAME() + ' from DDUP.', @rcode = 1
   			goto bspexit
   			END
   		
   		SELECT @restrict = isnull(@restrict,'N')
   	
   		EXEC @batchid = bspHQBCInsert @rqco, @pobatchmth, @source, @tablename, @restrict, 'N', null, null, @msg output
   		IF @batchid = 0
   		BEGIN
   		SELECT @msg = @msg + char(13) + '.  Error Getting Batch ID.', @rcode = 1
   		goto bspexit
   		END
   
   		SELECT @committed = 0
   		
   		--open cursor to spin try each header and item and set the BatchId and PO 
   	    DECLARE POHB_c cursor for
   			select batchseq
   			from @POHB_temp
   			
   	    OPEN POHB_c
   	    FETCH NEXT FROM POHB_c
   	    into @batchseq
   	
   	    While (@@FETCH_STATUS = 0)
   	    BEGIN 	

   			/*******************************************************
   			Get POHB Next PO  
   			******************************************************/
			--DC 124581 - replaced the commented section below with this
   			--check to see if @ponumber is valid
			POLoop:
				--check POHD, POHB, POPendingPurchaseOrder
   				select @endpo = isnull(@poprefix,'') + @ponumber
   				if exists(select 1 from dbo.POUnique where PO = @endpo AND POCo = @rqco )
   				begin

					select @ponumbertwo = cast(@ponumber as decimal(30,0))
					select @ponumbertwo = @ponumbertwo + 1.0
					select @ponumber = isnull(Replicate('0', Len(@ponumber) - Len(@ponumbertwo)),'') + cast(@ponumbertwo as varchar(31))

					if len(isnull(@poprefix,'')) + len(@ponumber) > @bpolen 
					Begin
							if @poprefix is null
							begin
								select @ponumber = 1
							end
							else
							begin
								select @lastposeq = isnull(@poprefix,'') + @ponumber
								goto EndPOSeq
							end
					end 
					
   					goto POLoop		
   				end
   
   			--open transaction
   			BEGIN TRANSACTION
   
   			--update POHB_item
   			UPDATE @POHB_temp
   			SET po = @endpo -- @ponumber  #124581 
   			WHERE batchseq = @batchseq
   			IF @@ERROR <> 0
   				BEGIN
   				SELECT @rollback = 1
   				goto ERR_ROLLBACK
   				END
   					
   			--update POIB_item
   			UPDATE @POIB_temp
   			SET po =  @endpo -- @ponumber  #124581 
   			WHERE batchseq = @batchseq
   			IF @@ERROR <> 0
   				BEGIN
   				SELECT @rollback = 1
   				goto ERR_ROLLBACK
   				END
   				
   			--DC #131806
   			UPDATE @POIB_temp
			SET jcco = Case itemtype When 1 then posttoco END,
				inco = Case itemtype When 2 then posttoco END,
				emco = Case itemtype When 3 then glco 
							 When 4 then posttoco
							 When 5 then posttoco END
			where batchseq = @batchseq

   			-- insert POHB_Temp to bPOHB
   			INSERT INTO POHB (Co, Mth, BatchId, BatchSeq, BatchTransType, PO, VendorGroup, Vendor, Status, Address, City, 
   				State, Zip, ShipIns, Attention, Address2, Country, Description, OrderDate, PayTerms, OrderedBy, JCCo, 
   				Job, INCo, Loc, ShipLoc, CompGroup) 
   				SELECT co, mth, @batchid, batchseq, batchtranstype, po, vendorgroup, vendor, status, address, city, 
   					state, zip, shipins, attention, address2, country, header_desc, order_date, payterms, orderedby,	jcco,
   					job, inco, loc, shiploc, compgroup
   				FROM @POHB_temp	
   				WHERE batchseq = @batchseq
   				IF @@ERROR <> 0
   					BEGIN
   					SELECT @rollback = 1
   					goto ERR_ROLLBACK
   					END
   
   			-- insert POIB_temp to bPOIB
   			INSERT INTO POIB (Co, Mth, BatchId, BatchSeq, POItem, BatchTransType, ItemType, MatlGroup, Material,
   				VendMatId, Description, UM, RecvYN, PostToCo, Loc, Job, PhaseGroup, Phase, JCCType, Equip,
   				CompType, Component, EMGroup, CostCode, EMCType, WO, WOItem, GLCo, GLAcct, ReqDate, TaxGroup,
   				TaxCode, TaxType, OrigUnits, OrigUnitCost, OrigECM, OrigCost, OrigTax, Notes, PayCategory, PayType,
   				INCo, JCCo, EMCo,  --DC #131806
   				TaxRate, GSTRate)  --DC #122288
   				SELECT co, mth, @batchid, batchseq, poitem, batchtranstype, itemtype, matlgroup, material,
   					vendmatid, item_desc, um, recvyn, posttoco, loc, job, phasegroup, phase, jcctype, equip,
   					comptype, component, emgroup, costcode, emctype, wo, woitem, glco, glacct, reqdate, taxgroup,
   					taxcode, taxtype, units, unitcost, ecm, cost, tax, notes, paycategory, paytype,
   					inco, jcco, emco,  --DC #131806 
   					taxrate, gstrate  --DC #122288
   				FROM @POIB_temp	
   				WHERE batchseq = @batchseq
   				IF @@ERROR <> 0
   					BEGIN
   					SELECT @rollback = 1
   					goto ERR_ROLLBACK
   					END
   	
   			-- update PO and POItem in bRQRL
   			UPDATE RQRL
   			SET RQRL.PO = t.po, RQRL.POItem = t.poitem
   			FROM RQRL, @POIB_temp t
   			WHERE t.rqid = RQRL.RQID
   				AND t.rqline = RQRL.RQLine
   				AND t.co = RQRL.RQCo
   				AND t.batchseq = @batchseq
   			IF @@ERROR <> 0
   				BEGIN
   				SELECT @rollback = 1
   				goto ERR_ROLLBACK
   				END	

			SELECT @ponumbertwo = cast(@ponumber as decimal(30,0))
			SELECT @ponumbertwo = @ponumbertwo + 1.0
			SELECT @ponumber = isnull(Replicate('0', Len(@ponumber) - Len(@ponumbertwo)),'') + cast(@ponumbertwo as varchar(31))
   
   			--select @ponumber = convert(bigint, @ponumber) + 1

   			--commit transaction			
   			COMMIT TRANSACTION
   			SELECT @committed = 1

			IF len(isnull(@poprefix,'')) + len(@ponumber) > @bpolen 
				Begin
					IF @poprefix is null
						begin
							select @ponumber = 1
						end
					ELSE
						begin
							select @lastposeq = isnull(@poprefix,'') + @ponumber
							goto EndPOSeq
						end
				end 
   
   			ERR_ROLLBACK:
   				If @rollback = 1
   					BEGIN
 
   					ROLLBACK TRANSACTION
   					SELECT @transmsg = 'Error:  Some records could not be initialized successfully.', @rollback = 0
   					END
   
   	    FETCH NEXT FROM POHB_c
   	    into @batchseq
   	    END
   	
		EndPOSeq:
   	    CLOSE POHB_c
   	    DEALLOCATE POHB_c
 	
   		--update POCO if AutoPO flag = 'Y'
   		IF @committed = 1 and @poprefix is null  --DC 124581
   			BEGIN
   			IF exists(select 1 from POCO where POCo = @rqco and AutoPO='Y')
   				BEGIN
   				UPDATE POCO
   				SET LastPO = convert(decimal(30,0), @ponumber) - 1   --DC 26900
   				WHERE POCo = @rqco
   				IF @@ERROR <> 0
   					BEGIN
   					SELECT @msg = @msg + char(13) + '.  Error Updating LastPO in POCO.', @rcode = 1
   					goto bspexit
   					END
   				END
   			END
   
   		--Exit batch
   		exec @rcode = bspHQBCExitCheck @rqco, @pobatchmth, @batchid, @source, @tablename, @msg output
   
   	END
   	ELSE
   		select @msg = 'No Requisitions ready to be sent to PO'
   
    bspexit:	
   	IF isnull(@batchid,0) = 0
   		BEGIN
   		select @batchmsg = 'Nothing found to initialize - did not create a PO Batch!'
   		END
   	ELSE
   		BEGIN
		IF @lastposeq is null
			BEGIN
   			select @batchmsg = 'Batch Created. ' + char(13) + 'PO Company: ' + convert(varchar(10), @rqco) + ' Month: ' + convert(varchar(2),datepart(mm,@pobatchmth)) + '/' + right(convert(varchar(4),datepart(yy,@pobatchmth)),2) + ' Batch#: ' + convert(varchar(10),@batchid)
   			END
		ELSE
			BEGIN
   			select @batchmsg = 'Batch Created. ' + char(13) + 'PO Company: ' + convert(varchar(10), @rqco) + ' Month: ' + convert(varchar(2),datepart(mm,@pobatchmth)) + '/' + right(convert(varchar(4),datepart(yy,@pobatchmth)),2) + ' Batch#: ' + convert(varchar(10),@batchid)
   			select @batchmsg = @batchmsg + char(13) + char(10) + 'RQ PO Initialize was stopped before all of the Requistions could be processed because the next generated PO, ' + @lastposeq + ', is longer then the 10 characters allowed'
			END
		END
   
   	IF @rcode = 0 SELECT @msg = @batchmsg  
   
   	IF LEN(isnull(@transmsg,'')) > 1 SELECT @msg = @msg + char(13) + @transmsg
   
    IF @rcode<>0 select @msg=@msg + char(13) + char(10) + '[bspRQPOBatchInit]'
   	return @rcode
      
   bsperror:
   CLOSE POItem_c
   DEALLOCATE POItem_c
   CLOSE POHeader_c
   DEALLOCATE POHeader_c
   GOTO bspexit


GO
GRANT EXECUTE ON  [dbo].[bspRQPOBatchInit] TO [public]
GO
