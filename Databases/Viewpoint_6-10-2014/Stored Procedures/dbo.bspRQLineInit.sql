SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRQLineInit    Script Date: 4/28/2004 7:14:24 AM ******/
     CREATE  proc [dbo].[bspRQLineInit]
     /***********************************************************
      * CREATED BY: 	DC 6/1/04
      * MODIFIED By 	DC 12/27/04 - 26495
      *				DC 1/13/05 - 26778 - WO has non-valid part results in blank desc
	*			DC 03/20/08 - #127554 - Modify RQ Line Initialization for International Addresses
	*			DC 12/4/08	- #130129 - Combine RQ and PO into a single module
	*			GF 07/07/2010 - issue #137272 - vendor material description is 60 characters.
	*			GF 09/10/2010 - issue #141031 changed to use function vfDateOnly
	*
      *
      * USAGE:
      * Used by the RQ Initialize to populate RQDQ with
      * materials that need to be requisitioned.
      * 
      * INPUT PARAMETERS
      *   Co		RQ Co to validate against
      *   RQID		RQ Header ID
      *	 in			Run IN process
      *	 em			Run EM process
      *   Reqtr		RQ Header Requestor
      *   HDesc		RQ Header Description
      *   INCo		IN Co to validate against
      *   INLoc		IN Location
      *   INLocGrp	IN Location Group
      *   MatlCat	Materical category
      *   EMCo		EM Company
      *   EMShop		EM Shop
      *   EMWODays	EM Work Order through date
      *   ShipLoc	Shipping Location
      *   ReqDate	Required Date
      *	 Reviewer	Reviewer
      *	 Vendor		Vendor
      *	 VendorGrp	Vendor Group
      *	 Route		Route
      *
      * OUTPUT PARAMETERS
      *   @msg      error message if error occurs otherwise RQ ID is returned or message that no RQ was created.
      *
      * RETURN VALUE
      *   0         success
      *   1         Failure
      *****************************************************/
     	(@co bCompany, @rqid bRQ, @in bYN, @em bYN, @reqtr varchar(20) = null, @hdesc bDesc = null, 
     	@inco bCompany = null, @inlocgrp bGroup = null, @inloc bLoc = null, @matlcat varchar(10) = null,
     	@emco bCompany = null, @emshop varchar(20) = null, @emwodays bDate = null, @shiploc varchar(10) = null,
     	@reqdate bDate = null, @reviewer varchar(3) = null, @vendor bVendor = null, @vendorgrp bGroup = null,
     	@route tinyint, @msg varchar(255) output)
     
     as
     set nocount on
     
     	declare @rcode int,
     		@headerid varchar(10),
     		@lineid	bItem,
     		@linetype tinyint,
     		@status int,
     		@unitcost bUnitCost,
     		@emct bEMCType,
     		@matl bMatl,
     		@units bUnits,
     		@ecm bECM,
     		@um bUM,
     		@source varchar(20),
     		@ireccount int,
     		@reorderloop int,
     		@totalcost bDollar,
     		@successmsg varchar(255),
     		@reviewstatus int,
     		@newrq int,
   			@in_linetype tinyint,
   			@wo_linetype tinyint

     	--Variables needed to get default Unit Cost
     	Declare @uc_rc int,
     		@uc_lineid int,
      		@uc_vendgroup bGroup, 
     		@uc_vend bVendor, 
     		@uc_matlgroup bGroup, 
     		@uc_material bMatl,
      		@uc_um bUM, 
     		@uc_inco bCompany , 
     		@uc_loc bLoc ,
          	@uc_unitcost bUnitCost , 
     		@uc_ecm bECM ,
      		@uc_venddescrip bItemDesc , ----#137272
     		@uc_errmsg varchar(60) 

		--variables needed to get Shipping Location Address  --DC #127554
		declare @posladdress varchar(60),
			@poslcity varchar(30),
			@poslstate varchar(4),
			@poslzip varchar(12),
			@posladdress2 varchar(60),
			@poslcountry varchar(2)
     
     	--table variable to hold records from INMT
     	declare	@INMT_temp TABLE (lineid smallint,
     			inco tinyint,
     			inloc varchar(10),
     			MatlGroup tinyint,
     			Material varchar(20),
     			ReOrder numeric(12,3),
     			LowStock numeric(12,3),
     			OnHand numeric(12,3),
     			Units numeric(12,3),
     			UM varchar(3),
     			address varchar(60),
     			city varchar(30),
     			state char(4),  --DC #127554
     			zip varchar(12),
				country varchar(2),  --DC #127554
     			address2 varchar(60),
     			vendor int,
     			vendorgrp tinyint,
     			ecm char(1),
     			unitcost numeric(16,5),
     			indesc varchar(60), ----#137272
     			totalcost numeric(12,2)) 
     
     	--table variable to hold records from EMWP
     	declare	@EMWP_temp TABLE (lineid smallint,
     			emco tinyint,
     			wo varchar(10),
     			woitem smallint,
     			partsct tinyint,
     			matlgroup tinyint,
     			material varchar(20),
     			emgroup tinyint,
     			equip varchar(10),
     			descr varchar(60), ----#137272
     			um varchar(3),
     			qty numeric(12,3),
     			psflag char(1),
     			comptype varchar(10),
     			comp varchar(10),	
     			costcode varchar(10),
     			datesched smalldatetime,
     			vendor int,
     			vendorgrp tinyint,
     			ecm char(1),
     			unitcost numeric(16,5),
     			emdesc varchar(60), ----#137272
     			totalcost numeric(12,2),
     			address varchar(60),  --DC #127554
     			city varchar(30),  --DC #127554
     			state char(4),  --DC #127554
     			zip varchar(12),  --DC #127554
				country varchar(2),  --DC #127554
     			address2 varchar(60))  --DC #127554
     
     	--table variable to hold records from RQRL
     	declare	@RQRL_IN_temp TABLE (lineid smallint,
     			inco tinyint,
     			inloc varchar(10),
     			MatlGroup tinyint,
     			Material varchar(20),
     			Units numeric(12,3),
     			UM varchar(3)) 
     
     	--table variable to hold records from RQRL
     	declare	@RQRL_EM_temp TABLE (lineid smallint,
     			emco tinyint,
     			wo varchar(10),
     			woitem smallint,
     			matlgroup tinyint,
     			material varchar(20),
     			units numeric(12,3),
     			um varchar(3)) 
     
     	SELECT	@rcode = 0
     	SELECT	@uc_rc = 0
     	SELECT	@source = 'RQ Init'
     	SELECT	@ireccount = 0
     	SELECT	@status = 0		-- Open
     	SELECT 	@reviewstatus = 0 --New RQ
     	SELECT	@unitcost = 0
     	SELECT	@ecm = 'E'
   		SELECT	@in_linetype = 2
   		SELECT	@wo_linetype = 5
     	
     	if @co is null
     		begin
     		select @msg = 'Missing PO Company!', @rcode = 1
     		goto bspexit
     		end
     
     	IF EXISTS(select top 1 1 from RQRH WITH (NOLOCK) where RQCo = @co AND RQID = @rqid)
     		BEGIN
     		SELECT @newrq = 1
     		END
     	ELSE
     		BEGIN	
     		SELECT @newrq = 0
     		END
     
     	--set lineid to = max RQLine if adding Lines to an existing RQHQ
     	IF @rqid is null
     		BEGIN
     		--set lineid to = 0 if adding lines to a new RQRH
     		SET @lineid = 0
     		--set if RQID is null, then use 1+ max(RQID)
     		SELECT @rqid = isnull(max(RQID),0) + 1
     		FROM RQRH WITH (NOLOCK)
     		WHERE RQCo = @co AND isnumeric(RQID) = 1	
     		END
     	ELSE
     		BEGIN
     		SELECT @lineid = isnull(max(RQLine),0)
     		FROM RQRL WITH (NOLOCK)
     		WHERE RQCo = @co AND RQID = @rqid AND isnumeric(RQLine) = 1	
     		END
     
   	--Set @rqid to a str so it will be right aligned.
   	SELECT @rqid = str((convert(bigint,@rqid)),10)

	--If there is a Ship Location passed in, set the address variables
	IF isnull(@shiploc,'') <> ''
		BEGIN
		Select @posladdress = Address, @poslcity = City, @poslstate = State,
			@poslzip = Zip, @posladdress2 = Address2, @poslcountry = Country
		From POSL
		Where POCo = @co and ShipLoc = @shiploc
		END

     if @in = 'Y'
     	BEGIN
     	
     	SELECT	@linetype = @in_linetype  	-- Inventory
     	SELECT	@reorderloop = 0
   
     	/****************************************
     	select records from INMT into @INMT_temp
     	******************************************/
     	INSERT INTO @INMT_temp (lineid,inco,inloc,MatlGroup,Material, ReOrder,LowStock,OnHand,Units,
     							UM,address,city,state,zip,address2, country, vendor, vendorgrp,ecm, unitcost)
     			SELECT 	@lineid, i.INCo,i.Loc,i.MatlGroup,i.Material,i.ReOrder,i.LowStock,(i.OnHand-i.Alloc+i.OnOrder),0,
     					h.StdUM,l.ShipAddress,l.ShipCity,l.ShipState,l.ShipZip,l.ShipAddress2,l.ShipCountry, @vendor, @vendorgrp,@ecm,
     					@unitcost
     			FROM	INMT i WITH (NOLOCK)
     			Join	INLM l WITH (NOLOCK) on l.INCo = i.INCo and l.Loc = i.Loc
     			Join	HQMT h WITH (NOLOCK) on i.MatlGroup = h.MatlGroup and i.Material = h.Material
     			WHERE	ISNULL(i.INCo,'') = ISNULL(@inco,ISNULL(i.INCo, '')) 
     				AND ISNULL(i.Loc,'') = ISNULL(@inloc,ISNULL(i.Loc,'')) 
     				AND ISNULL(h.Category,'') = ISNULL(@matlcat,ISNULL(h.Category,''))
     				AND ISNULL(l.LocGroup,'') = ISNULL(@inlocgrp,ISNULL(l.LocGroup,''))
     				AND (i.OnHand-i.Alloc+i.OnOrder) < i.LowStock
     				AND i.ReOrder > 0
     				AND	i.LowStock > 0
     	IF @@rowcount = 0 
     		GOTO IN_END
     
     	/***********************************************
     	Select IN records from RQRL into @RQRL_IN_temp
     	***********************************************/
     	INSERT INTO @RQRL_IN_temp (lineid,inco,inloc,MatlGroup,Material,Units,UM)
     			SELECT 	l.RQLine,l.INCo,l.Loc,l.MatlGroup,l.Material,l.Units,l.UM
     			FROM	RQRL l WITH (NOLOCK)
     			Join	INLM m WITH (NOLOCK) on m.INCo = l.INCo and m.Loc = l.Loc
     			Join	HQMT t WITH (NOLOCK) on l.MatlGroup = t.MatlGroup and l.Material = t.Material
     			Join	RQRH h WITH (NOLOCK) on l.RQCo = h.RQCo and l.RQID = h.RQID
     			WHERE	ISNULL(l.INCo,'') = ISNULL(@inco,ISNULL(l.INCo, '')) 
     				AND ISNULL(l.Loc,'') = ISNULL(@inloc,ISNULL(l.Loc,'')) 
     				AND ISNULL(t.Category,'') = ISNULL(@matlcat,ISNULL(t.Category,''))
     				AND ISNULL(m.LocGroup,'') = ISNULL(@inlocgrp,ISNULL(m.LocGroup,''))
     				AND l.LineType = @linetype
     				AND h.InUseBy is null
     				AND l.PO is null
     				AND	l.Status <> 3
     
     	/*****************************************
     	Join @INMT_temp to @RQRL_IN_temp via Material, INCo, INLoc, MatlGroup
     	Add  @RQRL_IN_temp.Units to @INMT_temp.Units 
     	*****************************************/
     	IF @@rowcount <> 0
     		BEGIN
     		UPDATE @INMT_temp
     		SET Units = (SELECT sum(l.Units) 
     				FROM @RQRL_IN_temp l 
     				WHERE l.Material = t.Material 
     					AND l.inco = t.inco 
     					AND l.inloc = t.inloc 
     					AND l.MatlGroup = t.MatlGroup 
     				GROUP BY l.Material, l.inco, l.inloc, l.MatlGroup)
     		FROM @INMT_temp t
     
     		/********************************************
     		loop thru all records in @INMT_temp and delete records 
     		that are not lowstock because of the units added from @RQRL_temp
     		********************************************/
     		Delete @INMT_temp
     		where ISNULL(Units,0) + ISNULL(OnHand,0) >= ISNULL(LowStock,0)
     		END
     
     	/********************************************
     	Set units to 0 to elimate any units from 
   	another RQ.  Loop thru all records in @INMT_temp
   	and increase Lowstock until onhand is greater 
   	then low stock.
     	********************************************/
   	UPDATE @INMT_temp
   	SET Units = 0
   
     	WHILE @reorderloop = 0
     	BEGIN
     		update @INMT_temp
     		set Units = ISNULL(Units,0) + ISNULL(ReOrder,0)
     		where ISNULL(Units,0) + ISNULL(OnHand,0) < ISNULL(LowStock,0)
     
     		if not exists(select top 1 1 from @INMT_temp where Units + OnHand < LowStock)
     			select @reorderloop = 1
     	END
     
     	/****************************************
     	Now we need to do line by line updates.
     	*****************************************/
     	--1.update @INMT_Temp! LineID
     	update @INMT_temp
     	set @lineid = @lineid + 1,  lineid = @lineid
     
     	--2.Default Unit Cost using bspHQMatUnitCostDflt
     	--Use cursor to update every line in @INMT_temp
         declare c_inmt cursor for
         select lineid, vendorgrp, vendor, MatlGroup, Material, UM, inco, inloc
         from @INMT_temp
     
         OPEN c_inmt
         FETCH NEXT FROM c_inmt
         into @uc_lineid, @uc_vendgroup, @uc_vend, @uc_matlgroup, @uc_material, @uc_um, @uc_inco, @uc_loc
     
         While (@@FETCH_STATUS = 0)
         Begin 	
     
     	exec @uc_rc = bspHQMatUnitCostDflt @uc_vendgroup, @uc_vend, @uc_matlgroup, @uc_material,
      			@uc_um , NULL , NULL , @uc_inco , @uc_loc , @uc_unitcost output, @uc_ecm output,
      			@uc_venddescrip output, @uc_errmsg output
     
     	IF @uc_rc = 0
     		BEGIN
     		update @INMT_temp
     		set unitcost = @uc_unitcost, 
     			ecm = @uc_ecm, 
     			indesc = @uc_venddescrip, ----#137272
     			totalcost = Units * (@uc_unitcost / (Case @uc_ecm WHEN 'E' then 1 WHEN 'C' then 100 WHEN 'M' then 1000 End))
     		where lineid = @uc_lineid
     		END
     
         FETCH NEXT FROM c_inmt
         into @uc_lineid, @uc_vendgroup, @uc_vend, @uc_matlgroup, @uc_material, @uc_um, @uc_inco, @uc_loc
         end
     
         CLOSE c_inmt
         DEALLOCATE c_inmt
     
     IN_END:
     	END
     
     -- Run EM process if @em = 1
     IF @em = 'Y' 
     	BEGIN
     	--Set @linetype,  @reorderloop
     	SELECT	@linetype = @wo_linetype  	-- Work Order
     	SELECT	@reorderloop = 0
   
     	/****************************************
     	select records from EMWP into @EMWP_temp
     	******************************************/
     	INSERT INTO @EMWP_temp (lineid,emco,wo,woitem,partsct,matlgroup,material,emgroup,equip,descr,um,
     					qty,psflag,comptype,comp,costcode,datesched, vendor, vendorgrp,ecm, unitcost,
     					address, city, state, zip, address2, country)  --DC #127554
     			SELECT 	0,p.EMCo,p.WorkOrder,p.WOItem,c.PartsCT,p.MatlGroup,p.Material,i.EMGroup,p.Equipment,p.Description,p.UM,
     					p.QtyNeeded,p.PSFlag,i.ComponentTypeCode,i.Component,i.CostCode,i.DateSched, @vendor, @vendorgrp,@ecm,
     					@unitcost,
						l.ShipAddress, l.ShipCity, l.ShipState, l.ShipZip, l.ShipAddress2,l.ShipCountry  --DC #127554
     			FROM 	EMWP p WITH (NOLOCK)
     				Join	EMCO c WITH (NOLOCK) on p.EMCo = c.EMCo
     				Join 	EMWI i WITH (NOLOCK) on p.EMCo = i.EMCo and p.WorkOrder = i.WorkOrder and p.WOItem = i.WOItem
     				Left Join  HQMT t WITH (NOLOCK) on p.MatlGroup = t.MatlGroup and p.Material = t.Material
     				join	EMWH h WITH (NOLOCK) on h.EMCo = p.EMCo and h.WorkOrder = p.WorkOrder
   					join	EMWS s WITH (NOLOCK) on s.EMGroup = c.EMGroup and i.StatusCode = s.StatusCode
					LEFT join INLM l on l.INCo = h.INCo and l.Loc = h.InvLoc  --DC #127554
     			WHERE	ISNULL(t.Category,'') = ISNULL(@matlcat,ISNULL(t.Category,''))	
     				AND	ISNULL(p.EMCo,'') = ISNULL(@emco,ISNULL(p.EMCo, ''))
      				AND	ISNULL(h.Shop,'') = ISNULL(@emshop,ISNULL(h.Shop, ''))
     				AND 	(ISNULL(i.DateSched,'') <= ISNULL(@emwodays,ISNULL(i.DateSched, '')) or i.DateSched is null )
     				AND	p.PSFlag = 'P'
     				AND	p.Required = 'Y'
   				AND	s.StatusType <> 'F'
   
     	IF @@rowcount = 0 
     		goto EM_END
     
     	/***********************************************
     	Select EM records from RQRL into @RQRL_EM_temp
     	***********************************************/
     	INSERT INTO @RQRL_EM_temp (lineid,emco,wo,woitem,matlgroup,material,units,um)
     			SELECT 	l.RQLine,l.EMCo,l.WO,l.WOItem,l.MatlGroup,l.Material,l.Units,l.UM
     			FROM	RQRL l WITH (NOLOCK)
     			Join	EMWI i WITH (NOLOCK) on i.EMCo = l.EMCo and i.WorkOrder = l.WO and i.WOItem = l.WOItem
     			Join	HQMT t WITH (NOLOCK) on l.MatlGroup = t.MatlGroup and l.Material = t.Material
     			Join	RQRH h WITH (NOLOCK) on l.RQCo = h.RQCo and l.RQID = h.RQID
     			Join	EMWH w WITH (NOLOCK) on w.EMCo = l.EMCo and w.WorkOrder = l.WO
     			WHERE	(ISNULL(i.DateSched,'') <= ISNULL(@emwodays,ISNULL(i.DateSched, '')) or i.DateSched is null)
     				AND	ISNULL(t.Category,'') = ISNULL(@matlcat,ISNULL(t.Category,''))	
     				AND	ISNULL(l.EMCo,'') = ISNULL(@emco,ISNULL(l.EMCo, ''))
     				AND l.LineType = @linetype
     				AND h.InUseBy is null
     				AND	ISNULL(w.Shop,'') = ISNULL(@emshop,ISNULL(w.Shop, ''))	
     					
     	/*****************************************
     	Delete records from @EMWP_temp that exist in @RQRL_EM_temp
     	*****************************************/
     	IF @@rowcount <> 0
     		BEGIN
     		DELETE @EMWP_temp
     		FROM @EMWP_temp e
     			Join @RQRL_EM_temp r on r.emco = e.emco 
     									AND r.wo = e.wo 
     									AND r.woitem = e.woitem 
     
     									AND r.matlgroup = e.matlgroup 
     									AND r.material = e.material
     		END
     
     	/****************************************
     	Now we need to do line by line updates.
     	*****************************************/
     	--1.update @EMWP_temp! LineID
     	update @EMWP_temp
     	set @lineid = @lineid + 1,  lineid = @lineid
     
     	--2.Default Unit Cost using bspHQMatUnitCostDflt
     	--Use cursor to update every line in @EMWP_temp
         declare c_emmt cursor for
         select lineid, vendorgrp, vendor, matlgroup, material, um
         from @EMWP_temp
     
         OPEN c_emmt
         FETCH NEXT FROM c_emmt
         into @uc_lineid, @uc_vendgroup, @uc_vend, @uc_matlgroup, @uc_material, @uc_um
     
         While (@@FETCH_STATUS = 0)
         Begin 	
     
     	exec @uc_rc = bspHQMatUnitCostDflt @uc_vendgroup, @uc_vend, @uc_matlgroup, @uc_material,
      			@uc_um, NULL, NULL, NULL, NULL, @uc_unitcost output, @uc_ecm output,
      			@uc_venddescrip output, @uc_errmsg output
     
     	IF @uc_rc = 0
     		BEGIN
     		update @EMWP_temp
     		set unitcost = @uc_unitcost, 
     			ecm = @uc_ecm, 
     			emdesc = @uc_venddescrip, ----#137272
     			totalcost = qty * (@uc_unitcost / (Case @uc_ecm WHEN 'E' then 1 WHEN 'C' then 100 WHEN 'M' then 1000 End))
     		where lineid = @uc_lineid
     		END
     
         FETCH NEXT FROM c_emmt
         into @uc_lineid, @uc_vendgroup, @uc_vend, @uc_matlgroup, @uc_material, @uc_um
         end
     
         CLOSE c_emmt
         DEALLOCATE c_emmt
     
     EM_END:
     	END	
     
     	/****************************************
     	open transaction to insert into RQRH and RQRL
     	*****************************************/
     	IF exists(select 1 from @EMWP_temp) OR exists(select 1 from @INMT_temp)
     		BEGIN
     		BEGIN TRANSACTION 
     		IF @newrq = 0 
     			BEGIN
   			SELECT @successmsg = 'Requisition Items Created' + char(13) + ' PO Company: ' + LTRIM(@co) + ' RQ ID: ' + ltrim(@rqid)
     			END
     		ELSE
     			BEGIN
     			SELECT @successmsg = 'Requisition Items Appended' + char(13) + ' PO Company: ' + LTRIM(@co) + ' RQ ID: ' + ltrim(@rqid)
     			END
     	
     		/******************************************
     		Create header record in RQRH
     		*******************************************/
     		IF not exists(select top 1 0 from RQRH WITH (NOLOCK) where RQCo = @co and RQID = @rqid)
     			BEGIN
     			INSERT INTO RQRH (RQCo, RQID, Source, Requestor, RecDate, Description)
     				values(@co,@rqid,@source,@reqtr, dbo.vfDateOnly(),@hdesc)
     			IF @@rowcount <> 1
     				GOTO ERR_INSERT
     			END
   
     		/******************************************
     		Copy records from @EMWP_temp to RQRL
     		******************************************/
     		IF exists(select 1 from @EMWP_temp)
     			BEGIN
     			SELECT	@linetype = @wo_linetype
   
     			INSERT INTO RQRL (RQCo, RQID, RQLine,LineType,Route,Status,EMCo,WO,WOItem,EMCType,ShipLoc,MatlGroup,
     								Material,Phase,PhaseGroup,EMGroup,Equip,Description,UM,UnitCost,Units,ECM,CompType,
     								Component,CostCode,ReqDate,TotalCost, Vendor, VendorGroup,
									Address, City, State, Zip, Address2, Country )  --DC 127554
     				SELECT @co, @rqid, t.lineid, @linetype, isnull(@route,0), @status, t.emco, t.wo,t.woitem, t.partsct, @shiploc,t.matlgroup,
     						t.material,h.MatlPhase,c.PhaseGroup,t.emgroup,t.equip,t.descr,t.um,t.unitcost,t.qty,t.ecm,t.comptype,  --DC 26778
     						t.comp,t.costcode,t.datesched,isnull(t.totalcost,0), t.vendor, t.vendorgrp,
     						CASE WHEN @shiploc IS NULL THEN t.address ELSE @posladdress END,  --DC 127554
							CASE WHEN @shiploc IS NULL THEN t.city ELSE @poslcity END,  --DC 127554
							CASE WHEN @shiploc IS NULL THEN t.state ELSE @poslstate END,  --DC 127554
							CASE WHEN @shiploc IS NULL THEN t.zip ELSE @poslzip END,  --DC 127554
							CASE WHEN @shiploc IS NULL THEN t.address2 ELSE @posladdress2 END,  --DC 127554
							CASE WHEN @shiploc IS NULL THEN t.country ELSE @poslcountry END  --DC 127554
     				FROM @EMWP_temp t
     				Left Join	HQMT h WITH (NOLOCK) on t.matlgroup = h.MatlGroup and t.material = h.Material  --DC 26495
     				Join 	HQCO c WITH (NOLOCK) on c.HQCo = t.emco
     			IF @@rowcount <> (select count(1) from @EMWP_temp)
     				BEGIN
     				GOTO ERR_INSERT
     				END
     			/******************************************
     			If @reviewer is not null, insert reviewers 
     			for each RQ Lines into RQRR
     			******************************************/
     			IF isnull(@reviewer,'') <> '' 
     				BEGIN
     				/****************************************
     				First delete any records from @EMWP_temp 
     				that already have a matching reviewer record in RQRR
     				******************************************/
     				DELETE @EMWP_temp
     				FROM @EMWP_temp e 
     					JOIN RQRR r ON e.lineid = r.RQLine
     				WHERE r.RQCo = @co
     					AND r.Reviewer = @reviewer
     					AND r.RQID = @rqid
     				--Now insert reviewer records into RQRR from @EMWP_temp 
     				INSERT INTO RQRR (RQCo, Reviewer, RQID, RQLine, AssignedDate, Status)
     					SELECT @co, @reviewer, @rqid, t.lineid, dbo.vfDateOnly(), @reviewstatus
     					FROM @EMWP_temp t	
   					WHERE @reviewer NOT IN (select Reviewer
   											from RQRR with (NOLOCK)
   											where RQCo = @co
   												and RQID = @rqid
   												and RQLine = t.lineid)			
     				END
     			END
   
     		/******************************************
     		Copy records from @INMT_Temp to RQRL
     		******************************************/
     		If exists(select 1 from @INMT_temp)
     			BEGIN
     			SELECT	@linetype = @in_linetype  	-- Inventory
     			INSERT INTO RQRL (RQCo, RQID, RQLine,LineType,Route,Status,INCo,Loc,ShipLoc,MatlGroup,
     								Material,Phase,PhaseGroup,Description,UM,UnitCost,Units,ECM,
     								Address,City,State,Zip,Address2,Country, TotalCost, Vendor, VendorGroup, ReqDate)
     				SELECT @co, @rqid, t.lineid, @linetype, isnull(@route,0), @status, t.inco, t.inloc,@shiploc,t.MatlGroup,
     						t.Material,h.MatlPhase,c.PhaseGroup,h.Description,t.UM,t.unitcost,t.Units,t.ecm,
     						CASE WHEN @shiploc IS NULL THEN t.address ELSE @posladdress END,  --DC 127554
							CASE WHEN @shiploc IS NULL THEN t.city ELSE @poslcity END,  --DC 127554
							CASE WHEN @shiploc IS NULL THEN t.state ELSE @poslstate END,  --DC 127554
							CASE WHEN @shiploc IS NULL THEN t.zip ELSE @poslzip END,  --DC 127554
							CASE WHEN @shiploc IS NULL THEN t.address2 ELSE @posladdress2 END,  --DC 127554
							CASE WHEN @shiploc IS NULL THEN t.country ELSE @poslcountry END,  --DC 127554
							isnull(t.totalcost,0), t.vendor, t.vendorgrp, @reqdate
     				FROM @INMT_temp t
     				Join	HQMT h WITH (NOLOCK) on t.MatlGroup = h.MatlGroup and t.Material = h.Material
     				Join 	HQCO c WITH (NOLOCK) on c.HQCo = t.inco
     			IF @@rowcount <> (select count(1) from @INMT_temp)
     				BEGIN
     				GOTO ERR_INSERT
     				END
     			/******************************************
     			If @reviewer is not null, insert reviewers 
     			for each RQ Lines into RQRR
     			******************************************/
     			IF isnull(@reviewer,'') <> '' 
     				BEGIN
     				/****************************************
     				First delete any records from @INMT_temp 
     				that already have a matching reviewer record in RQRR
     				******************************************/
     				DELETE @INMT_temp
     				FROM @INMT_temp i 
     					JOIN RQRR r ON i.lineid = r.RQLine
     				WHERE r.RQCo = @co
     					AND r.Reviewer = @reviewer
     					AND r.RQID = @rqid
     				--Now insert reviewer records into RQRR from @INMT_temp 
     				INSERT INTO RQRR (RQCo, Reviewer, RQID, RQLine, AssignedDate, Status)
     					SELECT @co, @reviewer, @rqid, t.lineid, dbo.vfDateOnly(), @reviewstatus
     					FROM @INMT_temp t		
   					WHERE @reviewer NOT IN (select Reviewer
   											from RQRR with (NOLOCK)
   											where RQCo = @co
   												and RQID = @rqid
   												and RQLine = t.lineid)		
     				END
     
     			END
     			
     		COMMIT TRANSACTION 
     		GOTO bspexit
     		END
     	ELSE
     		BEGIN
     		SELECT @successmsg = 'No items needed to be requisitioned.'
     		GOTO bspexit
     		END
     
     ERR_INSERT:
     	ROLLBACK TRANSACTION
     	select @rcode = 1
     	select @msg = 'Error inserting into RQRH and RQRL'
     	GOTO bspexit
     
     bspexit:
         IF @rcode<>0 
     		BEGIN
     		SELECT @msg=@msg + char(13) + char(10) + '[bspRQLineInit]'
     		return @rcode
     		END
     	ELSE
     		BEGIN
     		Select @msg = @successmsg
     		return @rcode
     		END

GO
GRANT EXECUTE ON  [dbo].[bspRQLineInit] TO [public]
GO
