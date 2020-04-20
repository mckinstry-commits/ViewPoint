CREATE TABLE [dbo].[bEMCD]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[EMTrans] [dbo].[bTrans] NOT NULL,
[BatchId] [dbo].[bBatchID] NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[Component] [dbo].[bEquip] NULL,
[ComponentTypeCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Asset] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[WorkOrder] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[CostCode] [dbo].[bCostCode] NOT NULL,
[EMCostType] [dbo].[bEMCType] NOT NULL,
[PostedDate] [dbo].[bDate] NOT NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[Source] [dbo].[bSource] NULL,
[EMTransType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bItemDesc] NULL,
[InUseBatchID] [dbo].[bBatchID] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLTransAcct] [dbo].[bGLAcct] NULL,
[GLOffsetAcct] [dbo].[bGLAcct] NULL,
[ReversalStatus] [tinyint] NULL,
[PRCo] [dbo].[bCompany] NULL,
[PREmployee] [dbo].[bEmployee] NULL,
[APCo] [dbo].[bCompany] NULL,
[APTrans] [dbo].[bTrans] NULL,
[APLine] [int] NULL,
[VendorGrp] [dbo].[bGroup] NULL,
[APVendor] [dbo].[bVendor] NULL,
[APRef] [dbo].[bAPReference] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[INCo] [dbo].[bCompany] NULL,
[INLocation] [dbo].[bLoc] NULL,
[Material] [dbo].[bMatl] NULL,
[INStkUM] [dbo].[bUM] NULL,
[INStkUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bEMCD_INStkUnitCost] DEFAULT ((0)),
[INStkECM] [dbo].[bECM] NULL,
[SerialNo] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NOT NULL,
[Dollars] [dbo].[bDollar] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bEMCD_UnitPrice] DEFAULT ((0)),
[PerECM] [dbo].[bECM] NULL,
[TotalCost] [dbo].[bDollar] NULL,
[AllocCode] [tinyint] NULL,
[TaxType] [tinyint] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxBasis] [dbo].[bDollar] NULL,
[TaxRate] [dbo].[bRate] NULL,
[TaxAmount] [dbo].[bDollar] NULL,
[CurrentHourMeter] [dbo].[bHrs] NOT NULL,
[CurrentTotalHourMeter] [dbo].[bHrs] NOT NULL,
[CurrentOdometer] [dbo].[bHrs] NOT NULL,
[CurrentTotalOdometer] [dbo].[bHrs] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[MeterTrans] [dbo].[bTrans] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[POItemLine] [int] NULL,
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMCDd    Script Date: 1/29/2002 3:33:24 PM ******/
   CREATE    trigger [dbo].[btEMCDd] on [dbo].[bEMCD] for Delete
   as
    

/**************************************************************
    * Created: 5/6/99 RWH
    * Modified: bc  09/01/99	added update to EMEM for fuel used
    *           GG 06/20/01 - set bEMEM.UpdateYN = 'N' to avoid HQ auditing when updating fuel info
    *            JM 1/29/02 - Reset UpdateYN to 'Y' - Ref GG 01/29/02 email.
    *			  GF 02/26/2003 - issue #20531 - not validating fuel cap um as the validation procedure is. This can
    *								result in a trigger error during posting.
    *			  TV 02/11/04 - 23061 added isnulls
	*			  TRL 04/17/08 - Issue 127809 added IsNull(@xxx,'') 
	*			GP 05/26/09 - Issue 133434, added new HQAT insert
	*			JVH 1/28/10	- Issue 137693 - Skip updating fuel used if fueltype is none
	*				GF 05/05/2013 TFS-49039
	*
    *  This trigger updates  fields in EMMC.
    *
    *
    *  This trigger does not use a cursor, rather it iterates througt the deleted
    *      table using @KeyCo, @KeyMonth & @Trans
    **************************************************************/
    declare @errmsg varchar(255), @validcnt int, @validcnt2 int,@errno int, @numrows int, @nullcnt int,@rcode int,
    	@subtype char (1), @cxum bUM, @batchid bBatchID, @conversion bUnits, @convunits bUnits, @costcode bCostCode,
    	@dollars bDollar, @emco bCompany, @emcosttype bEMCType,	@emgroup bGroup, @emtrans bTrans, @equipment bEquip,
    	@fuelcapum bUM,	@fuelmatlcode bMatl, @fuelunits bUnits,	@material bMatl, @matlgroup bGroup,	@mth bMonth,
    	@stdum bUM,	@um bUM, @unitprice bUnitCost, @units bUnits, @emumconv bUnitCost, @umconv bUnitCost, @fueltype char(1)
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    /* cycle trough each record - start at the first company */
    select @emco=MIN(EMCo) from deleted
    while @emco is not null
        begin
        /* for each company start at the first Month */
        select @mth=Min(Mth) from deleted where EMCo=@emco
        While @mth is not null
            begin
            /* get first trans for this EMCo & Month */
            select @emtrans=Min(EMTrans) from deleted where EMCo=@emco and Mth=@mth
            while @emtrans is not null
                begin
     		    select @emgroup=EMGroup, @equipment=Equipment, @costcode=CostCode, @emcosttype=EMCostType,
                       @matlgroup = MatlGroup, @material = Material, @um=UM, @units=Units, @dollars=Dollars
               From deleted where EMCo=@emco and Mth=@mth and EMTrans=@emtrans
   			-- set fuel units
   			set @fuelunits = @units
   
    		    -- lookup cost Code/ Type combination
    		    select @cxum=UM from bEMCX with (nolock)
    		    Where EMGroup=@emgroup and CostCode=@costcode and CostType=@emcosttype
               -- if UM is not the same as the std CT UM fon;t update units
    		    if @um <> @cxum select @units=0
   			-- updtae EMMC back out units and dollars
               Update bEMMC set ActUnits = ActUnits - @units, ActCost = ActCost - @dollars
               where EMCo=@emco and Equipment=@equipment and EMGroup=@emgroup and CostCode=@costcode and CostType=@emcosttype and Month=@mth
    
   
   			-- update EMEM FuelUsed when @material is not null
			/*Issue 127809 added IsNull(,'')*/
			--if @material is Null goto Next_EMCD_Trans
   			if IsNull(@material,'')= ''goto Next_EMCD_Trans
   
   			-- get fuel cap info from EMEM
    			select @fuelmatlcode = FuelMatlCode, @fuelcapum = FuelCapUM, @fueltype = FuelType
   			from EMEM with (nolock) where EMCo = @emco and Equipment = @equipment
   			-- skip if fuel material code <> material code
				/*Issue 127809 added IsNulls(,'')*/
    			if IsNull(@fuelmatlcode,'') <> IsNull(@material,'') goto Next_EMCD_Trans
   
    			-- EMEM is only updated if the material being posted into EMCD is equal to the fuel material code in EMEM
    			-- get conversion for posted unit of measure
    			exec @rcode = bspHQStdUMGet @matlgroup, @material, @um, @umconv output, @stdum output, @errmsg output
    			if @rcode <> 0 goto error
    			
    		-- skip if fueltype is set to none 137693
			if @fueltype <> 'N'
				begin
    			
				-- get conversion for EM unit of measure
				exec @rcode = bspHQStdUMGet @matlgroup, @material, @fuelcapum, @emumconv output, null, @errmsg output
				if @rcode <> 0 goto error

   				/*Issue 127809 added IsNulls(,'')*/
   				if IsNull(@fuelcapum,'') = IsNull(@um,'')
   					begin
   					select @convunits = @fuelunits * 1
   					end
   				else
   					begin
    					if @emumconv <> 0 
    						select @convunits = @fuelunits * (@umconv / @emumconv)
    					else
    						select @convunits = 0
   					end
    			

   				-- convert the units and update the table
    				update EMEM set FuelUsed = FuelUsed - @convunits, UpdateYN = 'N' -- avoid HQ auditing
    				where EMCo = @emco and Equipment = @equipment
    				if @@rowcount = 0
    					begin
    					select @errmsg = 'Error updating Fuel in Equipment Master '
    					goto error
    					end
	   
   				-- Reset UpdateYN to 'Y' - Ref GG 01/29/02 email.
    				update EMEM set UpdateYN = 'Y' where EMCo = @emco and Equipment = @equipment
    			end
   
			-- Delete attachments if they exist. Make sure UniqueAttchID is not null
			insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
			select AttachmentID, suser_name(), 'Y' 
            from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
            where d.UniqueAttchID is not null    

    
   			Next_EMCD_Trans:
               /* get next transaction */
               select @emtrans=MIN(EMTrans) from deleted where EMCo=@emco and Mth=@mth and EMTrans>@emtrans
               if @@rowcount=0 select @emtrans=null
               end /*begin*/
            /* get next month */
            select @mth=MIN(Mth) from deleted where EMCo=@emco and Mth>@mth
            if @@rowcount=0 select @mth=null
            end /*begin*/
        select @emco=MIN(EMCo) from deleted where EMCo>@emco
        if @@rowcount=0 select @emco=null
        end /*begin*/
    Return
    error:
    select @errmsg = isnull(@errmsg,'') + ' - cannot delete Cost Detail Trans # ' + convert(varchar(12),@emtrans)
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
    
    
    
   
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   /****** Object:  Trigger dbo.btEMCDi    Script Date: 4/24/2002 3:27:14 PM ******/
   CREATE    trigger [dbo].[btEMCDi] on [dbo].[bEMCD] for insert
   as

/**************************************************************
    * Created: 5/6/99 RWH
    * Modified: 5/10/99 JM - Added 'Allocations' ,'Parts', 'Fuel' and 'Depn' to list of valid EMTransType
    *                   in validation statement.
    *		GG 07/15/99 Changes to component validation
    *		bc  09/01/99 added emem fuel material update
    *		ae  09/7/99 fixed for emalloc update
    *		gh 10/27/99 unremed if gltrans acct null statement
    *		ae 02/02/00   Changed type from EMAlloc to Alloc
    *		danf 04/06/00 Added - EMTime source
    *		GG 11/27/00 - changed datatype from bAPRef to bAPReference
    *		GG 04/10/01 - changed GL Account validation to use bspGLACfPostable
    *		DANF 04/25/01 - Added PO Source and PO Receipt Transaction Type.
    *		GG 06/20/01 - set bEMEM.UpdateYN = 'N' to avoid HQ auditing when updating fuel info
    *		TJL 08/15/01 - Added 'AR' to EM TransType and Source validation
    *		bc 09/04/01 - GLCo change.  Issue # 14521
    *		GG 10/04/01 - #14814 - Offset GL Account validation - if usage, allow 'E' subtype 
    *		JM 01/24/02 -  Ref Issue 15162 - Allow posting of depreciation to Inactive Equipment - added condition
    *		           	at Equipment validation to pass if bEMEM.Status = 'I' and inserted.Source = 'EMAdj' and 
    *		           	inserted.EMTransType = 'Depn'
    *		JM 1/29/02 - Reset UpdateYN to 'Y' - Ref GG 01/29/02 email.
    *		JM 4/23/02 - Revised validation proc for GLTrans and GLOffset accts to match validation in 
    *		         			bspEM_Val_Cost... procedures
    *		bc 9/17/2 - Issue #18594
    *		GF 10/03/2002 - Issue #18707 Validation overkill, no need to validate offset account. Remmed out.
    *		JM 10-07-02 - Corrected Depn and Alloc Sources to EMDepr and EMAlloc
    *		GF 07/31/2003 - issue #21933 - speed improvements
    *		TV 12/02/2003 - 23061 isnulls
	*		TJL 04/21/08 - Issue #124391, Equipment, Component Status must be A or D
    *		JVH 1/28/10	- Issue 137693 - Skip updating fuel used if fueltype is none
    *		TRL 02/04/2010 Issue 137916  change @description to 60 characters   
    *		TRL 135655 add isnulls around component and component type validation 
    *       ECV TK-06284 Add missing lookup of FueldMatlCode for the current equipment
	*		GF 05/05/2013 TFS-49039
	*		GF 07/30/2013 TFS-57298  
    *
    *  This trigger rejects insert in bEMCD (EM Cost Detail)
    *   if the following error condition exists:
    *
    *      invalid Cost Code or Cost Type
    *      invalid GLTransAcct
    *      invalid GLOffsetAcct
    *
    *      Updates corresponding fields in EMMC.
    *      note
    *
    *  This trigger does not use a cursor, rather it iterates througt the inserted
    *      table using @KeyCo, @KeyMonth & @Trans
    **************************************************************/
   declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @numrows int, @nullcnt int,@rcode int,@subtype char (1), 
   		@cxum bUM, @actualdate bDate, @alloccode tinyint, @apco bCompany, @apline int, @apref bAPReference, 
   		@aptrans bTrans, @apvendor bVendor, @asset varchar (20), @batchid bBatchID, @component bEquip, 
   		@componenttypecode varchar (10), @emumconv bUnitCost, @umconv bUnitCost, @convunits bUnits, 
   		@costcode bCostCode, @currenthourmeter bHrs, @currentodometer bHrs, @currenttotalhourmeter bHrs,
   		@currenttotalodometer bHrs, @description bItemDesc/*137916*/, @dollars bDollar, @emco bCompany, @emcosttype bEMCType, 
   		@ememdate bDate, @emgroup bGroup, @emtrans bTrans, @emtranstype varchar(10), @equipment bEquip, 
   		@fuelcapum bUM, @fuelmatlcode bMatl, @fuelunits bUnits, @fuelused bUnits, @glco bCompany, 
   		@gloffsetacct bGLAcct, @gltransacct bGLAcct, @inco bCompany, @inlocation bLoc, @inusebatchid bBatchID, 
   		@material bMatl, @matlgroup bGroup, @mth bMonth, @offsetglco bCompany, @perecm bECM, @posteddate bDate, 
   		@prco bCompany, @premployee bEmployee, @reversalstatus tinyint, @serialno varchar(20), @source bSource,
   		@taxamount bDollar, @taxbasis bDollar, @taxcode bTaxCode, @taxgroup bGroup, @taxrate bRate, 
   		@totalcost bDollar, @um bUM, @stdum bUM, @unitprice bUnitCost, @units bUnits, @vendorgrp bGroup, 
   		@woitem bItem, @workorder bWO, @fueltype char(1)
    
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   if @numrows = 1
   
   	select @emco=EMCo, @mth=Mth, @emtrans=EMTrans, @batchid=BatchId, @emgroup=EMGroup, @equipment=Equipment,
   		@component=Component, @componenttypecode=ComponentTypeCode, @asset=Asset, @workorder=WorkOrder,
   		@woitem=WOItem, @costcode=CostCode, @emcosttype=EMCostType, @posteddate=PostedDate, @actualdate=ActualDate, 
   		@source=Source, @emtranstype=EMTransType, @description=Description, @inusebatchid=InUseBatchID, 
   		@offsetglco=GLCo, @gltransacct=GLTransAcct, @gloffsetacct=GLOffsetAcct, @reversalstatus=ReversalStatus, 
   		@prco=PRCo, @premployee=PREmployee, @apco=APCo, @aptrans=APTrans, @apline=APLine, @vendorgrp=VendorGrp,
   		@apvendor=APVendor, @apref=APRef, @matlgroup=MatlGroup, @inco=INCo, @inlocation=INLocation, 
   		@material=Material, @serialno=SerialNo, @um=UM, @units=Units, @dollars=Dollars, @unitprice=UnitPrice,
   		@perecm=PerECM, @totalcost=TotalCost, @alloccode=AllocCode, @taxcode=TaxCode, @taxgroup=TaxGroup,
   		@taxbasis=TaxBasis, @taxrate=TaxRate, @taxamount=TaxAmount, @currenthourmeter=CurrentHourMeter,
   		@currenttotalhourmeter=CurrentTotalHourMeter, @currentodometer=CurrentOdometer,
   		@currenttotalodometer=CurrentTotalOdometer
       from inserted
   else
       begin
   	-- use a cursor to process each inserted row
   	declare bEMCD_insert cursor FAST_FORWARD
   	for select EMCo, Mth, EMTrans, BatchId, EMGroup, Equipment,
   		Component, ComponentTypeCode, Asset, WorkOrder,
   		WOItem, CostCode, EMCostType, PostedDate, ActualDate, 
   		Source, EMTransType, Description, InUseBatchID, 
   		GLCo, GLTransAcct, GLOffsetAcct, ReversalStatus, 
   		PRCo, PREmployee, APCo, APTrans, APLine, VendorGrp,
   		APVendor, APRef, MatlGroup, INCo, INLocation, 
   		Material, SerialNo, UM, Units, Dollars, UnitPrice,
   		PerECM, TotalCost, AllocCode, TaxCode, TaxGroup,
   		TaxBasis, TaxRate, TaxAmount, CurrentHourMeter,
   		CurrentTotalHourMeter, CurrentOdometer,
   		CurrentTotalOdometer, TaxType
   	from inserted
   
   	open bEMCD_insert
   
       fetch next from bEMCD_insert into @emco, @mth, @emtrans, @batchid, @emgroup, @equipment,
   		@component, @componenttypecode, @asset, @workorder,
   		@woitem, @costcode, @emcosttype, @posteddate, @actualdate, 
   		@source, @emtranstype, @description, @inusebatchid, 
   		@offsetglco, @gltransacct, @gloffsetacct, @reversalstatus, 
   		@prco, @premployee, @apco, @aptrans, @apline, @vendorgrp,
   		@apvendor, @apref, @matlgroup, @inco, @inlocation, 
   		@material, @serialno, @um, @units, @dollars, @unitprice,
   		@perecm, @totalcost, @alloccode, @taxcode, @taxgroup,
   		@taxbasis, @taxrate, @taxamount, @currenthourmeter,
   		@currenttotalhourmeter, @currentodometer,
   		@currenttotalodometer
   
       if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
       end
   
   insert_check:
   -- save the units for fuel posting incase @units is zeroed out
   select @fuelunits = @units
   
   -- TFS-57298 retrieve GLCo from EMCo and validate EMCo
   select @glco = GLCo from bEMCO with (nolock) where EMCo = @emco
   if @@rowcount = 0
   	begin
    	select @errmsg = 'EM Company is Invalid '
    	goto error
    	end
   
   -- Validate Equipment
   -- Ref Issue 15162 - Allow posting of depreciation to Inactive Equipment
   -- JM 12-05-02 Ref Issue 19565 - Imported records are assigned Source = 'EMAdj' and EMTransType = 'Depn', so include this condition'
   -- in the if statement that allows Inactive Equipment.
   if @source = 'EMDepr'  or (@source = 'EMAdj' and @emtranstype = 'Depn')
   	begin
   	if not exists(select top 1 1 from bEMEM with (nolock) where EMCo=@emco and Equipment=@equipment and Status in ('A', 'I', 'D'))
   		begin
   		select @validcnt = 0
   		-- old statement - not sure what is going on here
   		--select @validcnt = count(*) from bEMEM r with (nolock) 
   		--JOIN inserted i ON i.EMCo = r.EMCo and i.Equipment = r.Equipment 
   		--where r.Status in ('A','I','D')
   		end
   	end
   else
   	begin
   	if not exists(select top 1 1 from bEMEM with (nolock) where EMCo=@emco and Equipment=@equipment and Status in ('A', 'D'))
   		begin
   	 	select @errmsg = 'Equipment is Invalid '
   	 	goto error
   	 	end
   	end
   
   
   
   -- Validate component
	--if @component is not null  -135655
	if isnull(@component,'')<>''
		begin
		if @source = 'EMDepr'  or (@source = 'EMAdj' and @emtranstype = 'Depn')
   			begin
   			if not exists(select top 1 1 from bEMEM with (nolock) where EMCo=@emco and Equipment=@component and Status in ('A', 'I', 'D'))
   	 			begin
   	 			select @errmsg = 'Component is Invalid '
   	 			goto error
   	 			end
			end
		else
			begin
   			if not exists(select top 1 1 from bEMEM with (nolock) where EMCo=@emco and Equipment=@component and Status in ('A', 'D'))
   	 			begin
   	 			select @errmsg = 'Component is Invalid '
   	 			goto error
   	 			end
			end
		end


    
   -- Validate cost code / cost type combination
   select @cxum=UM from bEMCX with (nolock) where EMGroup=@emgroup and CostCode=@costcode and CostType=@emcosttype
   if @@rowcount = 0
   	begin
    	select @errmsg = 'Cost Code/Cost Type combination is Invalid '
    	goto error
    	end
   
   
   -- Validate EM Trans Type
   --if @emtranstype not in ('Equip','WO','Alloc','Parts','Fuel','Depn','Usage','AP','PR Entry','PO Receipt', 'AR')
   --	begin
   --	select @errmsg = 'Invalid Trans Type.'
   --	GoTo error
   --	End
    
   -- validate Source
   --if @source not in  ('EMAdj', 'EMRev', 'EMFuel', 'EMDepr', 'EMAlloc', 'EMParts', 'EMTime', 'PR', 'AP', 'PO', 'AR Receipt')
   --	begin
   --	select @errmsg = 'Invalid Source.'
   --	GoTo error
   --	End
    
   -- reversal status
   --if @reversalstatus not in (0,1,2,3,4)
   --	begin
   --	select @errmsg = 'Reversal Status '+ isnull(convert(varchar(2),@reversalstatus),'') + ' is invalid'
   --	GoTo error
   --	End
    
   
   -- check GL TransAcct - Revised 4-23-02 JM - To match cost validation bsp 
   if @gltransacct is not null
   	begin
   	if  @source = 'EMAdj' and @emtranstype = 'Fuel' or (@source = 'EMParts' and @emtranstype = 'Parts' ) or @source = 'EMFuel' 	
   		begin
   		exec @rcode = bspEMGLTransAcctValForFuelPosting @emco, @gltransacct, @errmsg output
   		if @rcode <> 0 goto error
   		end	
   	else
   		begin
   		exec @rcode = bspEMGLTransAcctVal @glco, @gltransacct, 'E', @errmsg output
   		if @rcode <> 0 goto error
   		end
   	end
   	
   -- validate HQUM
   if @um is not null
   	begin
   	if not exists (select top 1 1 from bHQUM with (nolock) where UM=@um)
   		begin
   		select @errmsg = 'Unit of Measure ' + isnull(@um,'') + ' is invalid'
   		GoTo error
   		End
   	end
   
   -- Create EMCH record if it doesn't exist
   if not exists(select top 1 1 from bEMCH with (nolock) where EMCo=@emco and Equipment=@equipment 
   				and EMGroup=@emgroup and CostCode=@costcode and CostType=@emcosttype)
   	begin
   	insert into bEMCH (EMCo, Equipment, EMGroup, CostCode, CostType, UM)
   	select @emco, @equipment, @emgroup, @costcode, @emcosttype, @cxum
   	end
    			
   -- if UM is not the same as the std CT UM don't update units
   if @um <> @cxum set @units = 0
    			
   -- insert EMMC record if it doesnt exist
   if not exists(select top 1 1 from bEMMC with (nolock) where EMCo=@emco and Equipment=@equipment 
   				and EMGroup=@emgroup and CostCode=@costcode and CostType=@emcosttype and Month=@mth)
   	begin
   	insert into bEMMC (EMCo, Equipment, EMGroup, CostCode, CostType, Month, ActUnits, ActCost, EstUnits, EstCost)
   	select @emco, @equipment, @emgroup, @costcode, @emcosttype, @mth, 0, 0, 0, 0
   	end
   
   -- update EMMC with units and dollars		
   update bEMMC set ActUnits = ActUnits + @units, ActCost = ActCost + @dollars 
   where EMCo=@emco and Equipment=@equipment and EMGroup=@emgroup and CostCode=@costcode 
   and CostType=@emcosttype and Month=@mth
   
   -- update EMEM FuelUsed
   if @material is not null
   	begin
   	
   	/* Lookup FuelMatlCode from EMEM for the current equipment TK-06284 */
   	select @fuelmatlcode = FuelMatlCode, @fuelcapum = FuelCapUM 
   	from bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment
   	    			
   	-- EMEM is only updated if the material being posted into EMCD is equal to the fuel material code in EMEM
   	if @fuelmatlcode = @material
   		begin
    			
   		-- get conversion for posted unit of measure
   		exec @rcode = bspHQStdUMGet @matlgroup, @material, @um, @umconv output, @stdum output, @errmsg output
   		if @rcode <> 0 goto error
   		
   		select @fuelmatlcode = FuelMatlCode, @fuelcapum = FuelCapUM, @fueltype = FuelType
   		from bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment
   		
   		-- skip if fueltype is set to none 137693
   		if @fueltype <> 'N'
   			begin
   			-- get conversion for EM unit of measure
   			exec @rcode = bspHQStdUMGet @matlgroup, @material, @fuelcapum, @emumconv output, @stdum output, @errmsg output
   			if @rcode <> 0 goto error
	    			
   			if @emumconv <> 0 
   				select @convunits = @fuelunits * (@umconv / @emumconv)
   			else
   				select @convunits = 0
	    		
   			-- we want to only update bEMEM with Fuel usage when there are units to update
   			if @convunits <> 0
   				begin
   				-- get last fuel date from bEMEM
   				select @ememdate = LastFuelDate 
   				from bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment
   				if @actualdate > @ememdate or @ememdate is null select @ememdate = @actualdate
	   
   				-- update bEMEM with fuel usage
   				update bEMEM set FuelUsed = FuelUsed + @convunits, 
   								 LastFuelDate = @ememdate, UpdateYN = 'N' -- avoid HQ auditing
   				where EMCo = @emco and Equipment = @equipment
   				if @@rowcount = 0
   					begin
   					select @errmsg = 'Error updating Fuel in Equipment Master '
   					goto error
   					end
	   	
   				-- Reset UpdateYN to 'Y' - Ref GG 01/29/02 email.
   				update bEMEM set UpdateYN = 'Y' 
   				where EMCo = @emco and Equipment = @equipment
   				end
   			end
   		End
   	End
   	
   
   
   
   
   if @numrows > 1
   	begin
   	fetch next from bEMCD_insert into @emco, @mth, @emtrans, @batchid, @emgroup, @equipment,
   		@component, @componenttypecode, @asset, @workorder,
   		@woitem, @costcode, @emcosttype, @posteddate, @actualdate, 
   		@source, @emtranstype, @description, @inusebatchid, 
   		@offsetglco, @gltransacct, @gloffsetacct, @reversalstatus, 
   		@prco, @premployee, @apco, @aptrans, @apline, @vendorgrp,
   		@apvendor, @apref, @matlgroup, @inco, @inlocation, 
   		@material, @serialno, @um, @units, @dollars, @unitprice,
   		@perecm, @totalcost, @alloccode, @taxcode, @taxgroup,
   		@taxbasis, @taxrate, @taxamount, @currenthourmeter,
   		@currenttotalhourmeter, @currentodometer,
   		@currenttotalodometer
   	if @@fetch_status = 0
   		goto insert_check
   	else
   		begin
   		close bEMCD_insert
   		deallocate bEMCD_insert
   		end
   	end
   
   
   
   Return
   
   
   
   
    
   error:
   	select @errmsg = @errmsg + ' - cannot insert Cost Detail Trans # ' + isnull(convert(varchar(12),@emtrans),'')
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    trigger [dbo].[btEMCDu] on [dbo].[bEMCD] for Update as

/**************************************************************
* Created: 5/6/99 RWH
* Modified:		bc  09/01/99  	added the update to emem fuel
*				ae  09/07/99      fixed for emalloc
*				ae  02/02/00     Changed type from EMAlloc to Alloc
*				ae  03/10/00  Changed type from EMDepr to Depn
*				danf 04/06/00 Added source EMTime
*				GG 11/27/00 - changed datatype from bAPRef to bAPReference
*				GG 04/10/01 - changed GL Account validation to use bspGLACfPostable
*				GG 06/20/01 - set bEMEM.UpdateYN = 'N' to avoid HQ auditing when updating fuel info
*				TJL 08/15/01 - Added 'AR' to EM TransType and Source validation
*				bc 09/04/01 - Issue # 14521
*				GG 10/04/01 - #14814 - Offset GL Account validation - if usage, allow 'E' subtype 
*				JM 12/12/01 - Ref Issue 15267 - Corrected variable in select statement from @units to 
*							@fuelunits in 'if @looped' in logic block for EMEM.FuelUsed update.
*				JM 1/29/02 - Reset UpdateYN to 'Y' - Ref GG 01/29/02 email.
*				GF 10/02/2002 - Issue #18707 - validation overkill. Remmed out offset account validation.
*				JM 10-07-02 - Corrected Depn and Alloc Sources to EMDepr and EMAlloc
*				GF 02/06/2003 - Issue #19315 - using @equipment when getting old equipment causing
*							  pseudo cursor to get stuck in loop.
*				bc 02/17/03 - Issue # 20436 - old amounts not handled correctly in EMMC update and EMEM.FuelUsed update.
*                          Removed Equipment out of the Psuedo Cursor.
*				GF 02/26/2003 - issue #20531 - not validating fuel cap um as the validation procedure is. This can
*								result in a trigger error during posting.
*				 TV 11/26/03 - issue 23080- We now skip the trigger is InUseBatch is being updates to null.
*				 TV 02/11/04 - 23061 added isnulls
*				TV 06/28/05 -29080 Might be null
*				TJL 04/21/08 - Issue #124391, Equipment, Component Status must be A or D
*				GP 10/29/08 - 130814, added a cursor for bEMCD, commented out to be used later.
*			    JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
*				JVH 1/28/10	- Issue 137693 - Skip updating fuel used if fueltype is none
  *				TRL 02/04/2010 Issue 137916  change @description to 60 characters 
*				GF 05/05/2013 TFS-49039
*
*  This trigger rejects insert in bEMCD (EM Cost Detail)*
*   if the following error condition exists:
*
*      invalid Cost Code or Cost Type
*      invalid GLTransAcct
*      invalid GLOffsetAcct
*
*      Updates corresponding fields in EMMC.
*      note
*
*  This trigger does not use a cursor, rather it iterates througt the inserted
*      table using @KeyCo, @KeyMonth & @Trans
**************************************************************/
   
   declare @errmsg varchar(255), @validcnt int, @validcnt2 int,@errno int, @numrows int, @nullcnt int,@rcode int,
   		@subtype char (1), @cxum bUM, @actualdate bDate, @alloccode tinyint, @apco bCompany, @apline int,
   		@apref bAPReference, @aptrans bTrans, @apvendor bVendor, @asset varchar (20), @batchid bBatchID, 
   		@component bEquip, @componenttypecode varchar (10), @conversion bUnits, @convunits bUnits,
    		@costcode bCostCode, @currenthourmeter bHrs, @currentodometer bHrs, @currenttotalhourmeter bHrs,
   		@currenttotalodometer bHrs, @description bItemDesc /*137916*/, @dollars bDollar, @emco bCompany, @emcosttype bEMCType,
   		@ememdate bDate, @emgroup bGroup, @emtrans bTrans, @emtranstype varchar(10), @equipment bEquip,
   		@fuelcapum bUM, @fuelmatlcode bMatl, @fuelunits bUnits, @glco bCompany, @gloffsetacct bGLAcct,
    		@gltransacct bGLAcct, @inco bCompany, @inlocation bLoc, @inusebatchid bBatchID, @looped bYN,
   		@material bMatl, @matlgroup bGroup, @mth bMonth, @offsetglco bCompany, @perecm bECM, @posteddate bDate,
   		@prco bCompany, @premployee bEmployee, @reversalstatus tinyint, @serialno varchar(20), @source bSource,
   		@stdum bUM, @taxamount bDollar, @taxbasis bDollar, @taxcode bTaxCode, @taxgroup bGroup, @taxrate bRate,
   		@totalcost bDollar, @um bUM, @unitprice bUnitCost, @units bUnits, @vendorgrp bGroup, @woitem bItem,
   		@workorder bWO, @umconv bUnitCost, @emumconv bUnitCost, @emmcunits bUnits
 
   
   declare @oldequipment bEquip, @oldemgroup bGroup, @oldcostcode bCostCode, @oldemcosttype bEMCType, @oldum bUM, 
   		@oldunits bUnits, @olddollars bDollar, @oldmaterial bMatl, @fuelmaterial bMatl, @fuelEquip bEquip,
   		@fuelUM bUM, @fueltype char(1)
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on   		 
            
    --If the only column that changed was UniqueAttachID, then skip validation.        
	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bEMCD', 'UniqueAttchID') = 1
	BEGIN 
		goto Trigger_Skip
	END      
   
   --if we are setting the InuseBatchID to null, skip trigger
   if Update(InUseBatchID) 
       begin
       select @validcnt = count(*) from inserted i where InUseBatchID is null 
       if @validcnt = @numrows
    		begin
    		goTo Trigger_Skip
    		End
    	End
 
----TFS-49039  
SELECT @validcnt = COUNT(*) FROM dbo.bEMEM EMEM JOIN inserted i ON i.EMCo = EMEM.EMCo AND i.Equipment = EMEM.Equipment and EMEM.ChangeInProgress = 'Y'
IF @validcnt = @numrows GOTO Trigger_Skip



   -- see if any fields have changed that is not allowed
   if Update(Mth) or Update(EMTrans)
    	begin
    	select @validcnt = count(*) from inserted i JOIN deleted d ON d.EMCo = i.EMCo and d.Mth=i.Mth and d.EMTrans=i.EMTrans
    	if @validcnt <> @numrows
    		begin
    		select @errmsg = 'Primary key fields may not be changed'
    		GoTo error
    		End
    	End
    
    
   
-- Validate Equipment
If Update(Equipment)
	BEGIN
	select @validcnt = count(*) from bEMEM r JOIN inserted i ON i.EMCo = r.EMCo and i.Equipment = r.Equipment and r.Status in ('A', 'D')
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Equipment is Invalid '
		goto error
		end
	END
   

   
   -- Validate cost Code/ Type combination
   select @validcnt = count(*) from bEMCX r JOIN inserted i ON i.EMGroup = r.EMGroup and i.CostCode=r.CostCode and i.EMCostType = r.CostType
   if @validcnt<> @numrows
   	 begin
   	 select @errmsg = 'Cost Code/Cost Type combination is Invalid '
   	 goto error
   	 end
   


	----------------
	-- CURSOR END --
	----------------  

   -- cycle trough each record - start at the first company
   select @emco=MIN(EMCo) from inserted
   while @emco is not null
   begin
   	--retrieve GLCo based on mBtkForm.FormCo
    	select @glco = GLCo from bEMCO with (nolock) where EMCo = @emco
   
   	-- for each company start at the first Month
   	select @mth=Min(Mth) from inserted where EMCo=@emco
   	While @mth is not null
   	begin
   		-- get first trans for this EMCo & Month
   		select @emtrans=Min(EMTrans) from inserted where EMCo=@emco and Mth=@mth
   
   		while @emtrans is not null
   		begin
   	 
   	 		select @batchid=BatchId,@emgroup=EMGroup,@equipment = Equipment,
   	 			   @component=Component,@componenttypecode=ComponentTypeCode,
   	 			   @asset=Asset,@workorder=WorkOrder,@woitem=WOItem,@costcode=CostCode,
   	 			   @emcosttype=EMCostType,@posteddate=PostedDate,@actualdate=ActualDate,@source=Source,
   	 			   @emtranstype=EMTransType,@description=Description,@inusebatchid=InUseBatchID,
   	 			   @offsetglco=GLCo,@gltransacct=GLTransAcct,@gloffsetacct=GLOffsetAcct,@reversalstatus=ReversalStatus,
   	 			   @prco=PRCo,@premployee=PREmployee,@apco=APCo,@aptrans=APTrans,@apline=APLine,
   	 			   @vendorgrp=VendorGrp,@apvendor=APVendor,@apref=APRef,@matlgroup=MatlGroup,@inco=INCo,
   	 			   @inlocation=INLocation,@material=Material,@serialno=SerialNo,@um=UM,@units=Units,
   	 			   @dollars=Dollars,@unitprice=UnitPrice,@perecm=PerECM,@totalcost=TotalCost,@alloccode=AllocCode,
   	 			   @taxcode=TaxCode,@taxgroup=TaxGroup,@taxbasis=TaxBasis,@taxrate=TaxRate,@taxamount=TaxAmount,
   	 			   @currenthourmeter=CurrentHourMeter,@currenttotalhourmeter=CurrentTotalHourMeter,
   	 			   @currentodometer=CurrentOdometer,@currenttotalodometer=CurrentTotalOdometer
   	 		From inserted where EMCo=@emco and Mth=@mth and EMTrans=@emtrans
   
   	 		-- handle back out of deleted
   	 		select @oldemgroup = EMGroup, @oldequipment=Equipment, @oldcostcode=CostCode, 
                      @oldemcosttype=EMCostType, @oldum=UM, @oldunits=isnull(Units,0), @olddollars=isnull(Dollars,0),
                      @oldmaterial = Material 
   	 		From deleted where EMCo=@emco and Mth=@mth and EMTrans=@emtrans
   
    			
   	 		---- Validate EM Trans Type
   	 		--if @emtranstype not in ('Equip','WO','Depn','Fuel','Parts','Alloc','Usage', 'AR')
   	 		--	begin
   	 		--	select @errmsg = 'Invalid Trans Type.'
   	 		--	GoTo error
   	 		--	End
   	 
   	 		---- validate Source
   	 		--if @source not in  ('EMAdj', 'EMRev', 'EMFuel', 'EMDepr', 'EMAlloc', 'EMParts', 'EMTime', 'PR', 'AP', 'AR Receipt')
   	 		--	begin
   	 		--	select @errmsg = 'Invalid Source.'
   	 		--	GoTo error
   	 		--	End
   	 
   	 		---- reversal status
   	 		--if @reversalstatus not in (0,1,2,3,4)
   	 		--	begin
   	 		--	select @errmsg = 'Reversal Status '+ isnull(convert(varchar(2),@reversalstatus),'') + ' is invalid'
   	 		--	GoTo error
   	 		--	End
   	 
   	 			
   	 		-- check GL TransAcct
   	 		-- Revised 4-23-02 JM - To match cost validation bsp
   	 		if @gltransacct is not null
   	 			begin
   	 			if  @source = 'EMAdj' and @emtranstype = 'Fuel' or (@source = 'EMParts' and @emtranstype = 'Parts' ) or @source = 'EMFuel' 	
   	 				begin
   	 				exec @rcode = bspEMGLTransAcctValForFuelPosting @emco, @gltransacct, @errmsg output
   	 				if @rcode <> 0 goto error
   	 				end	
   	 			else
   	 				begin
   	 				exec @rcode = bspEMGLTransAcctVal @glco, @gltransacct, 'E', @errmsg output
   	 				if @rcode <> 0 goto error
   	 				end
   	 			end
   	 			
   	 		-- validate HQUM
   	 		IF @um is not null and not exists(select * from bHQUM with (nolock) where UM=@um)
   				begin				
   		 		select @errmsg = 'Unit of Measure ' + @um + ' is invalid '
   		 		GoTo error
   		 		End
   	 
   	 		-- Create EMCH record if it doesn't exist
   	 		-- lookup cost Code/ Type combination
   	 		select @cxum=UM from bEMCX with (nolock) where EMGroup=@emgroup and CostCode=@costcode and CostType=@emcosttype
   	 		if (select count(*) from bEMCH where EMCo=@emco and Equipment=@equipment and EMGroup=@emgroup and CostCode=@costcode and CostType=@emcosttype)=0
   	 				insert into bEMCH (EMCo,Equipment, EMGroup, CostCode, CostType,UM) select @emco,@equipment,@emgroup,@costcode,@emcosttype ,@cxum
   	 
   	 		-- insert EMMC record if it doesnt exist
   	 		if (select count(*) from bEMMC where EMCo=@emco and Equipment=@equipment and EMGroup=@emgroup and CostCode=@costcode and CostType=@emcosttype and Month=@mth)=0
   	 				insert into bEMMC (EMCo,Equipment, EMGroup, CostCode, CostType, Month,ActUnits,ActCost,EstUnits,EstCost) 
   	 				select @emco,@equipment,@emgroup,@costcode,@emcosttype ,@mth,0,0,0,0
   	 
   	 		-- if UM is not the same as the std CT UM don't update units
   			if @um = @cxum
   				select @emmcunits = @units
   			else
   				select @emmcunits = 0
   
   			-- update EMMC with units and dollars
   	 		Update bEMMC set ActUnits = ActUnits + @emmcunits, ActCost = ActCost + @dollars 
   	 		where EMCo=@emco and Equipment=@equipment and EMGroup=@emgroup and CostCode=@costcode and CostType=@emcosttype and Month=@mth
   	 
   
   	 		-- Back out old info
   	 		select @cxum=UM from bEMCX with (nolock)
               where EMGroup=@oldemgroup and CostCode=@oldcostcode and CostType=@oldemcosttype
   
   			-- if UM is not the same as the std CT UM don't update units
   	 		if @oldum = @cxum
   				select @emmcunits = @oldunits
   			else
   				select @emmcunits = 0
   
   			-- update EMMC - back out old units and dollars 
               Update bEMMC set ActUnits = ActUnits - @emmcunits, ActCost = ActCost - @olddollars 
   	 		where EMCo=@emco and Month=@mth and EMGroup=@oldemgroup and Equipment=@oldequipment and CostCode=@oldcostcode and CostType=@oldemcosttype 
   	 			
   	 		/********************************************************
   	 		 * when not looped, add new records to tertiary tables. *
   	 		 * when looped, back out the old records                *
   	 		 ********************************************************/
   	 		select @looped = 'N'
   	 			
   	 		updateloop:
   
               if @looped = 'N'
   	 			select @fuelmaterial = @material, @fuelunits = @units, @fuelEquip = @equipment, @fuelUM = @um 
               else
                   select @fuelmaterial = @oldmaterial, @fuelunits = @oldunits, @fuelEquip = @oldequipment, @fuelUM = @oldum
   
   	 		-- skip if no material
   			if @fuelmaterial is null goto EMBF_Old_Values
   
   			-- update EMEM FuelUsed
   	 		select @fuelmatlcode = FuelMatlCode, @fuelcapum = FuelCapUM, @ememdate = LastFuelDate, @fueltype = FuelType
   			from bEMEM with (nolock) where EMCo = @emco and Equipment = @fuelEquip
   			-- skip if @fuelmatlcode <> @fuelmaterial TV 06/28/05 -29080 Might be null
   			if isnull(@fuelmatlcode,'') <> isnull(@fuelmaterial,'') goto EMBF_Old_Values
   
  	 		-- EMEM is only updated if the material being posted into EMCD is equal to the fuel material code in EMEM
 			-- get conversion for posted unit of measure
 			exec @rcode = bspHQStdUMGet @matlgroup, @fuelmaterial, @fuelUM, @umconv output, @stdum output, @errmsg output
 			if @rcode <> 0 goto error
   
      	 	-- skip if fueltype is set to none 137693
   	 		if @fueltype <> 'N'
   	 			begin  
   
      	 		-- get conversion for EM unit of measure
   	 			exec @rcode = bspHQStdUMGet @matlgroup, @fuelmaterial, @fuelcapum, @emumconv output, @stdum output, @errmsg output
   	 			if @rcode <> 0 goto error

   				if @emumconv <> 0 
   					select @convunits = @fuelunits * (@umconv / @emumconv)
   				else
   					select @convunits = 0
	   
   	 			if @looped = 'Y' select @convunits=  @convunits * -1
   	 			-- select @ememdate = LastFuelDate from EMEM where EMCo = @emco and Equipment = @equipment
	   
   	 			if @actualdate > @ememdate or @ememdate is null select @ememdate = @actualdate

   	 			-- convert the units and update the table
   	 			update bEMEM set FuelUsed = FuelUsed + @convunits, LastFuelDate = @ememdate, UpdateYN = 'N' -- avoid HQ auditing
   	 			where EMCo = @emco and Equipment = @fuelEquip
   	 			if @@rowcount = 0
   	 				begin
   	 				select @errmsg = 'Error updating fuel in equipment master '
   	 				goto error
   	 				end
	   	 
   				-- Reset UpdateYN to 'Y' - Ref GG 01/29/02 email.
   	 			update bEMEM set UpdateYN = 'Y' where EMCo = @emco and Equipment = @fuelEquip
   	 			end
   
   			EMBF_Old_Values:
   	 		-- back out old values
   	 		if @looped = 'N'
   	 			begin
   				select @looped = 'Y'
   	 			goto updateloop
   	 			end
   	 		
   			
   
   	 		-- get next transaction
   	 		select @emtrans=MIN(EMTrans) from inserted where EMCo=@emco and Mth=@mth and EMTrans>@emtrans
   	 		if @@rowcount=0 select @emtrans=null
   	 		end
   	 
   	 	-- get next month
   	 	select @mth=MIN(Mth) from inserted where EMCo=@emco and Mth>@mth
   	 	if @@rowcount=0 select @mth=null
   	 	end
   	 
   -- Get next EMCo
   select @emco=MIN(EMCo) from inserted where EMCo>@emco
   
   if @@rowcount=0 select @emco=null
   end
    
   Trigger_Skip:
    
   Return
   
    
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update Cost Detail Trans # ' + isnull(convert(varchar(12),@emtrans),'')
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [CK_bEMCD_EMTransType] CHECK (([EMTransType]='AR' OR [EMTransType]='PO Receipt' OR [EMTransType]='PR Entry' OR [EMTransType]='AP' OR [EMTransType]='Usage' OR [EMTransType]='Depn' OR [EMTransType]='Fuel' OR [EMTransType]='Parts' OR [EMTransType]='Alloc' OR [EMTransType]='WO' OR [EMTransType]='Equip' OR [EMTransType] IS NULL))
GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [CK_bEMCD_INStkECM] CHECK (([INStkECM]='M' OR [INStkECM]='C' OR [INStkECM]='E' OR [INStkECM] IS NULL))
GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [CK_bEMCD_PerECM] CHECK (([PerECM]='M' OR [PerECM]='C' OR [PerECM]='E' OR [PerECM] IS NULL))
GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [CK_bEMCD_ReversalStatus] CHECK (([ReversalStatus]=(4) OR [ReversalStatus]=(3) OR [ReversalStatus]=(2) OR [ReversalStatus]=(1) OR [ReversalStatus]=(0) OR [ReversalStatus] IS NULL))
GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [CK_bEMCD_Source] CHECK (([Source]='AR Receipt' OR [Source]='PO' OR [Source]='AP' OR [Source]='PR' OR [Source]='EMTime' OR [Source]='EMParts' OR [Source]='EMAlloc' OR [Source]='EMDepr' OR [Source]='EMFuel' OR [Source]='EMRev' OR [Source]='EMAdj' OR [Source] IS NULL))
GO
CREATE UNIQUE CLUSTERED INDEX [biEMCD] ON [dbo].[bEMCD] ([EMCo], [Equipment], [Mth], [EMTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biEMCDEMTrans] ON [dbo].[bEMCD] ([EMCo], [Mth], [EMTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biEMCDWorkOrderDelete] ON [dbo].[bEMCD] ([EMCo], [WorkOrder], [WOItem]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biEMCDCostCodeCT] ON [dbo].[bEMCD] ([EMGroup], [CostCode], [EMCostType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMCD] ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biEMCDAttchID] ON [dbo].[bEMCD] ([UniqueAttchID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [FK_bEMCD_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [FK_bEMCD_bEMAH_AllocCode] FOREIGN KEY ([EMCo], [AllocCode]) REFERENCES [dbo].[bEMAH] ([EMCo], [AllocCode])
GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [FK_bEMCD_bEMEM_Component] FOREIGN KEY ([EMCo], [Component]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment])
GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [FK_bEMCD_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [FK_bEMCD_bEMWH_WorkOrder] FOREIGN KEY ([EMCo], [WorkOrder]) REFERENCES [dbo].[bEMWH] ([EMCo], [WorkOrder])
GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [FK_bEMCD_bEMWI_WOItem] FOREIGN KEY ([EMCo], [WorkOrder], [WOItem]) REFERENCES [dbo].[bEMWI] ([EMCo], [WorkOrder], [WOItem])
GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [FK_bEMCD_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [FK_bEMCD_bEMTY_ComponentTypeCode] FOREIGN KEY ([EMGroup], [ComponentTypeCode]) REFERENCES [dbo].[bEMTY] ([EMGroup], [ComponentTypeCode])
GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [FK_bEMCD_bEMCC_CostCode] FOREIGN KEY ([EMGroup], [CostCode]) REFERENCES [dbo].[bEMCC] ([EMGroup], [CostCode])
GO
ALTER TABLE [dbo].[bEMCD] WITH NOCHECK ADD CONSTRAINT [FK_bEMCD_bEMCT_EMCostType] FOREIGN KEY ([EMGroup], [EMCostType]) REFERENCES [dbo].[bEMCT] ([EMGroup], [CostType])
GO
ALTER TABLE [dbo].[bEMCD] NOCHECK CONSTRAINT [FK_bEMCD_bEMCO_EMCo]
GO
ALTER TABLE [dbo].[bEMCD] NOCHECK CONSTRAINT [FK_bEMCD_bEMAH_AllocCode]
GO
ALTER TABLE [dbo].[bEMCD] NOCHECK CONSTRAINT [FK_bEMCD_bEMEM_Component]
GO
ALTER TABLE [dbo].[bEMCD] NOCHECK CONSTRAINT [FK_bEMCD_bEMEM_Equipment]
GO
ALTER TABLE [dbo].[bEMCD] NOCHECK CONSTRAINT [FK_bEMCD_bEMWH_WorkOrder]
GO
ALTER TABLE [dbo].[bEMCD] NOCHECK CONSTRAINT [FK_bEMCD_bEMWI_WOItem]
GO
ALTER TABLE [dbo].[bEMCD] NOCHECK CONSTRAINT [FK_bEMCD_bHQGP_EMGroup]
GO
ALTER TABLE [dbo].[bEMCD] NOCHECK CONSTRAINT [FK_bEMCD_bEMTY_ComponentTypeCode]
GO
ALTER TABLE [dbo].[bEMCD] NOCHECK CONSTRAINT [FK_bEMCD_bEMCC_CostCode]
GO
ALTER TABLE [dbo].[bEMCD] NOCHECK CONSTRAINT [FK_bEMCD_bEMCT_EMCostType]
GO
