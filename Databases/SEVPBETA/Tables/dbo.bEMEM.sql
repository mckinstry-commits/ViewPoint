CREATE TABLE [dbo].[bEMEM]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[Location] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Department] [dbo].[bDept] NULL,
[Category] [dbo].[bCat] NULL,
[Manufacturer] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Model] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ModelYr] [char] (6) COLLATE Latin1_General_BIN NULL,
[VINNumber] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bItemDesc] NULL,
[Status] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[OdoReading] [dbo].[bHrs] NOT NULL,
[OdoDate] [dbo].[bDate] NULL,
[ReplacedOdoReading] [dbo].[bHrs] NOT NULL,
[ReplacedOdoDate] [dbo].[bDate] NULL,
[HourReading] [dbo].[bHrs] NOT NULL,
[HourDate] [dbo].[bDate] NULL,
[ReplacedHourReading] [dbo].[bHrs] NOT NULL,
[ReplacedHourDate] [dbo].[bDate] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[FuelMatlCode] [dbo].[bMatl] NULL,
[FuelCapacity] [dbo].[bHrs] NOT NULL,
[FuelCapUM] [dbo].[bUM] NULL,
[FuelUsed] [dbo].[bUnits] NOT NULL,
[EMGroup] [dbo].[bGroup] NULL,
[FuelCostCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[FuelCostType] [tinyint] NULL,
[LastFuelDate] [dbo].[bDate] NULL,
[AttachToEquip] [dbo].[bEquip] NULL,
[AttachPostRevenue] [dbo].[bYN] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGrp] [dbo].[bGroup] NULL,
[UsageCostType] [dbo].[bJCCType] NULL,
[WeightUM] [dbo].[bUM] NULL,
[WeightCapacity] [dbo].[bHrs] NOT NULL,
[VolumeUM] [dbo].[bUM] NULL,
[VolumeCapacity] [dbo].[bHrs] NOT NULL,
[Capitalized] [dbo].[bYN] NULL,
[LicensePlateNo] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[LicensePlateState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[LicensePlateExpDate] [dbo].[bDate] NULL,
[IRPFleet] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CompOfEquip] [dbo].[bEquip] NULL,
[ComponentTypeCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CompUpdateHrs] [dbo].[bYN] NULL,
[CompUpdateMiles] [dbo].[bYN] NULL,
[CompUpdateFuel] [dbo].[bYN] NULL,
[PostCostToComp] [dbo].[bYN] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Operator] [dbo].[bEmployee] NULL,
[Shop] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[GrossVehicleWeight] [dbo].[bHrs] NOT NULL,
[TareWeight] [dbo].[bUnits] NOT NULL,
[Height] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Wheelbase] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[NoAxles] [tinyint] NOT NULL,
[Width] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OverallLength] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[HorsePower] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[TireSize] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OwnershipStatus] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[InServiceDate] [dbo].[bDate] NULL,
[ExpLife] [smallint] NOT NULL,
[ReplCost] [dbo].[bDollar] NOT NULL,
[CurrentAppraisal] [dbo].[bDollar] NOT NULL,
[SoldDate] [dbo].[bDate] NULL,
[SalePrice] [dbo].[bDollar] NOT NULL,
[PurchasedFrom] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PurchasePrice] [dbo].[bDollar] NOT NULL,
[PurchDate] [dbo].[bDate] NULL,
[APCo] [dbo].[bCompany] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[LeasedFrom] [dbo].[bVendor] NULL,
[LeaseStartDate] [dbo].[bDate] NULL,
[LeaseEndDate] [dbo].[bDate] NULL,
[LeasePayment] [dbo].[bDollar] NOT NULL,
[LeaseResidualValue] [dbo].[bDollar] NOT NULL,
[ARCo] [dbo].[bCompany] NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[CustEquipNo] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[MSTruckType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[RevenueCode] [dbo].[bRevCode] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[MechanicNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[JobDate] [dbo].[bDate] NULL,
[FuelType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[UpdateYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMEM_UpdateYN] DEFAULT ('N'),
[ShopGroup] [dbo].[bGroup] NOT NULL,
[IFTAState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[LastUsedDate] [dbo].[bDate] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ChangeInProgress] [dbo].[bYN] NULL,
[LastUsedEquipmentCode] [dbo].[bEquip] NULL,
[LastEquipmentChangeDate] [dbo].[bDate] NULL,
[LastEquipmentChangeUser] [dbo].[bVPUserName] NULL,
[EquipmentCodeChanges] [int] NULL,
[OriginalEquipmentCode] [dbo].[bEquip] NULL,
[ExpLifeTimeFrame] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bEMEM_ExpLifeTimeFrame] DEFAULT ('Y'),
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
   
   
   
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMEMd    Script Date: 2/8/2002 4:56:18 PM ******/
   CREATE       trigger [dbo].[btEMEMd] on [dbo].[bEMEM] for delete as
   

/*--------------------------------------------------------------
   *
   * Delete trigger for EMEM
   *  Created By: bc  	04/15/99
   * Modified by: JM  	02-08-02 - Delete Component History in bEMHC if bEMEM.Type = 'C'
   *              DANF 03/12/02 Use table instead of view in from clause
   *              TV 	12/18/03 23239 - allowed delete of equipment when meter history exists
   *			   GWC	03/18/04 23385 - added Delete validation stored procedure to check for equipment 
   *									 orphans being left in other tables.
   *			  TRL 08/12/08	126196 - EM Equipment Change, Item can't be deleted if Equipment code is being changed.
   **			GF 01/08/2013 TK-20666 change to use exists from is null to handle more than one row
   *
   *--------------------------------------------------------------*/
   
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @rcode int,
   	@emco bCompany, @equip bEquip, @attachment bEquip
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on

   
	--Issue 126196
	----TK-20666
	If EXISTS(SELECT 1 FROM deleted WHERE ChangeInProgress = 'Y') ----(select IsNull(ChangeInProgress,'N') from deleted ) = 'Y' 
		BEGIN
		SELECT @errmsg = 'Equipment code change in progess! Equipment cannot be deleted' 
        GOTO error
		END

   -- change any attachments assinged to this equipment into primary equipment 
   select @emco = min(EMCo) from deleted
   while @emco is not null
   	begin
   	select @equip = min(Equipment) from deleted where EMCo = @emco
   	while @equip is not null
     		begin
     		
   		--Verify that deleting Equipment does not leave Equipment record orphans in other tables.
   		exec @rcode = bspEMEquipmentDeleteVal @emco, @equip, @errmsg output
   		--If anything other than a success if returned, goto the error handler
   		IF @rcode <> 0 
   			begin
   			goto error
   			end
   
   		select @attachment = min(Equipment) from bEMEM where EMCo = @emco and AttachToEquip = @equip
   		while @attachment is not null
       		begin
       		update bEMEM set AttachToEquip = null where EMCo = @emco and Equipment = @attachment
       		select @attachment = min(Equipment)from bEMEM where EMCo = @emco and AttachToEquip = @equip
       		end
   
     		select @equip = min(Equipment)from deleted where EMCo = @emco and Equipment > @equip
     		end
   	select @emco = min(EMCo)from deleted where EMCo > @emco
   	end
   
   -- Delete Meter reading History (moved from portion of commented out code above)
   delete bEMMR 
   from bEMMR e join deleted d on e.EMCo=d.EMCo and e.Equipment=d.Equipment 
   where e.Source = 'EMEM Init' 
   
   ----TK-20666
   -- Delete Component History in bEMHC if bEMEM.Type = 'C' 
   DELETE bEMHC
   FROM bEMHC h JOIN deleted d ON d.EMCo=h.EMCo AND d.Equipment=h.Component
   WHERE d.Type = 'C'
   --select @type = Type, @emco = EMCo, @component = Equipment from deleted
   --if @type = 'C'
   --delete bEMHC where EMCo = @emco and Component = @component
   
       
   -- Audit inserts 
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bEMEM','EM Company: ' + convert(char(3), d.EMCo) + ' Equipment: ' + d.Equipment, d.EMCo, 'D',
   		null, null, null, getdate(), SUSER_SNAME()
   from deleted d, bEMCO e
   where d.EMCo = e.EMCo and e.AuditEquipment = 'Y'
   
   
   return
   
   error:
    select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMEM'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


   
CREATE trigger [dbo].[btEMEMi] on [dbo].[bEMEM] for insert as
/*--------------------------------------------------------------
*
*  Insert trigger for EMEM
*  Created By:    bc  04/12/99
*  Modified by:   rh  05/13/99 - Added update to EMMR
*		            bc  06/30/99 - changed EMMR section to loop through all inserted equipment
*                 bc  06/23/00 - made sure EMMR does not get written to unless the initial Hours or Miles are not equal to zero.
* 		    	TV  08/03/01 - Change null FuelType to 'N'
*                 bc 11/21/01 - Make sure that EMGroup cannot be imported as Null
*					RM 12/03/01 - Added ShopGroup to shop validation.
*		JM 2-8-02 - Adds initial history record for Component to bEMHC.
*		JM 3-5-02 - Corrected code adding initial history record to bEMHC to run from a single statement
*		rather than a cursor. Ref Issue 16471.
*		JM 5-8-02 Added checks to verify Component recs have valid CompOfEquip and ComponentTypeCode;
*		and Equip recs have nulls
*        TV 03/12/03 - Added FuelType 'O'
*        TV 11/18/03 - altered date format - no issue
*        TV 11/18/03 23032 - Changed Insert into EMMR to include Date and Previous.
*		  TV 02/11/04 - 23061 added isnulls
*		 TV 4/17/04 24504 - Added 'L' (leased to OwnershipType)
*			TV 08/02/05 29442 - Error in btEMDCi causing AP Batch to Hang - Missing fuelcapum in EMEM 
*		TRL 02/08/06 126360 - Return Error if EMGroup is Null
*		TRL 08/12/08 126196 - Check for OriginialEquipmentCode for EM Equipment Change
*			GF 01/15/2010 - issue #137547 license plate state validation
*			GF 02/01/2010 - issue #132064 set previous hour meter and previous odometer to zero.
*			GF 11/21/2010 - issue #141031
*			GF 01/08/2013 TK-20666 change to use exists from is null to handle more than one row
*	
*--------------------------------------------------------------*/
/***  basic declares for SQL Triggers ****/

declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
		@errno tinyint, @audit bYN, @validcnt int, @nullcnt int, @msg varchar(255),
		@rcode int, @mth bMonth, @trans bTrans, @emco bCompany, @equip bEquip,
		@readingdate bMonth
     
       select @numrows = @@rowcount
       if @numrows = 0 return
       set nocount on
    
      -- Validate EMCo
      select @validcnt = count(*) from bEMCO r with (nolock) JOIN inserted i ON i.EMCo = r.EMCo
      if @validcnt <> @numrows
         begin
         select @errmsg = 'EM Company is Invalid '
         goto error
         end
    
      -- Validate EM Group
      select @validcnt = count(*) from bHQGP r with (nolock) JOIN inserted i ON i.EMGroup = r.Grp
      select @nullcnt = count(*) from inserted i Where i.EMGroup is null

	  --Issue 126360
	  if IsNull(@nullcnt,0)>=1
      begin
         select @errmsg = 'Missing EM Group'
         goto error
      end

      if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'EM Group is Invalid '
         goto error
         end
    
      -- Validate Equipment Status
      select @validcnt = count(*) from inserted i where i.Status in ('A','I','D')
       if @validcnt <> @numrows
         begin
         select @errmsg = 'Equipment Status is Invalid '
         goto error
         end
     
	
	-- Issue 126196
	---- TK-20666 change to exists from is null
IF EXISTS(select top 1 1  from inserted where isnull(Equipment,'')!= isnull(OriginalEquipmentCode,''))
	begin
	select @errmsg = 'Original Equipment Code must equal Equipment code when record is added!'
	goto error
	end  


      -- Validate Equipment type
      select @validcnt = count(*) from inserted i where i.Type in ('E','C')
       if @validcnt <> @numrows
         begin
         select @errmsg = 'Equipment Type is Invalid '
         goto error
         end
    
    -- Verify that Components with Type = 'C' have a valid CompOfEquip and a valid ComponentTypeCode
    select @nullcnt = count(*) from inserted i where i.Type = 'E'
    select @validcnt = count(*) from bEMEM e with (nolock) 
    JOIN inserted i ON i.EMCo = e.EMCo and e.Equipment = i.CompOfEquip where e.Type = 'E'
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'CompOfEquip is null or invalid for Component entry '
         goto error
         end
    
    select @validcnt = count(*) from bEMTY r with (nolock) 
    JOIN inserted i ON i.EMGroup = r.EMGroup and i.ComponentTypeCode = r.ComponentTypeCode
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'ComponentTypeCode is null or invalid for Component entry'
         goto error
         end
    
    -- Verify that Equipments with Type = 'E' have no CompOfEquip and no ComponentTypeCode
     select @nullcnt = count(*) from inserted i where i.Type = 'C'
     select @validcnt = count(*) from inserted i where  i.Type = 'E' and i.CompOfEquip is null
       if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'CompOfEquip must be null for Equipment entry '
         goto error
         end
    
     select @validcnt = count(*) from inserted i where  i.Type = 'E' and i.ComponentTypeCode is null
       if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'ComponentTypeCode must be null for Equipment entry '
         goto error
         end
     
    -- Validate Department 
    select @validcnt = count(*) from bEMDM r with (nolock) 
    JOIN inserted i ON i.EMCo = r.EMCo and i.Department = r.Department
    select @nullcnt = count(*) from inserted i Where i.Type = 'C'
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Department is Invalid '
         goto error
         end
    
    -- Validate Category 
    select @validcnt = count(*) from bEMCM r with (nolock) JOIN inserted i ON i.EMCo = r.EMCo and i.Category = r.Category
    select @nullcnt = count(*) from inserted i Where i.Type = 'C'
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Category is Invalid '
         goto error
         end
    
    -- Validate Location
    select @validcnt = count(*) from bEMLM r with (nolock) JOIN inserted i ON i.EMCo = r.EMCo and i.Location = r.EMLoc
    select @nullcnt = count(*) from inserted i Where i.Location is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Location is Invalid '
         goto error
         end
    
    -- Validate Shop
    select @validcnt = count(*) from bEMSX r with (nolock) JOIN inserted i ON i.Shop = r.Shop and i.ShopGroup = r.ShopGroup
    select @nullcnt = count(*) from inserted i Where i.Shop is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Shop is Invalid '
         goto error
         end
    
    -- Validate RevCode
    select @validcnt = count(*) from bEMRC r with (nolock) JOIN inserted i ON i.EMGroup = r.EMGroup and i.RevenueCode = r.RevCode
    select @nullcnt = count(*) from inserted i Where i.RevenueCode is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Revenue Code is Invalid '
         goto error
         end
    
    -- Validate PRCo
    select @validcnt = count(*) from bPRCO r with (nolock) JOIN inserted i ON i.PRCo = r.PRCo
    select @nullcnt = count(*) from inserted i Where i.PRCo is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'PR Company is Invalid '
         goto error
         end
    
    -- Validate Operator
    select @validcnt = count(*) from bPREH r with (nolock) JOIN inserted i ON i.PRCo = r.PRCo and i.Operator = r.Employee
    select @nullcnt = count(*) from inserted i Where i.Operator is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Operator is Invalid '
         goto error
         end
    
    -- Validate JCCo
    select @validcnt = count(*) from bJCCO r with (nolock) JOIN inserted i ON i.JCCo = r.JCCo
    select @nullcnt = count(*) from inserted i Where i.JCCo is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'JC Company is Invalid '
         goto error
         end
    
    -- Validate Phase Group
    select @validcnt = count(*) from bHQGP r with (nolock) JOIN inserted i ON i.PhaseGrp = r.Grp
    select @nullcnt = count(*) from inserted i Where i.PhaseGrp is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Phase Group is Invalid '
         goto error
         end
    
    -- Validate Job
    select @validcnt = count(*) from bJCJM r with (nolock) JOIN inserted i ON i.JCCo = r.JCCo and i.Job = r.Job
    select @nullcnt = count(*) from inserted i Where i.Job is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'JC Job is Invalid '
         goto error
         end
    
    -- Validate Cost Type
    select @validcnt = count(*) from bJCCT r with (nolock) JOIN inserted i ON i.PhaseGrp = r.PhaseGroup and i.UsageCostType = r.CostType
    select @nullcnt = count(*) from inserted i Where i.UsageCostType is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'JC Cost Type is Invalid '
         goto error
         end
    
	-- validate State - all State values must exist in bHQST #137547
	if exists(select top 1 1 from inserted i where [LicensePlateState] not in(select [State] from dbo.bHQST))
		begin
		select @errmsg = 'License plate state is Invalid '
		goto error
		end
    
    -- Validate FuelMatlCode
    select @validcnt = count(*) from bHQMT r with (nolock) JOIN inserted i ON i.MatlGroup = r.MatlGroup and i.FuelMatlCode = r.Material
    select @nullcnt = count(*) from inserted i Where i.FuelMatlCode is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Fuel material code is Invalid '
         goto error
         end
    
    -- Validate FuelCostCode
    select @validcnt = count(*) from bEMCC r with (nolock) JOIN inserted i ON i.EMGroup = r.EMGroup and i.FuelCostCode = r.CostCode
    select @nullcnt = count(*) from inserted i Where i.FuelCostCode is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Fuel cost code is Invalid '
         goto error
         end
    
    -- Validate FuelCostType
    select @validcnt = count(*) from bEMCT r with (nolock) JOIN inserted i ON i.EMGroup = r.EMGroup and i.FuelCostType = r.CostType
    select @nullcnt = count(*) from inserted i Where i.FuelCostType is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Fuel cost type is Invalid '
         goto error
         end
    
    -- Validate FuelCapUM
    select @validcnt = count(*) from bHQUM r with (nolock) JOIN inserted i ON i.FuelCapUM = r.UM
    select @nullcnt = count(*) from inserted i Where i.FuelCapUM is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Fuel capacity UM is Invalid '
         goto error
         end
   
    -- TV 08/02/05 29442 - Error in btEMDCi causing AP Batch to Hang - Missing fuelcapum in EMEM 
    if exists(select top 1 1 from inserted where FuelType <> 'N' and isnull(FuelCapUM,'') = '')
   		begin
      	select @errmsg = 'Fuel Capacity UM required '
      	goto error
      	end
   
    -- Validate WeightUM
    select @validcnt = count(*) from bHQUM r with (nolock) JOIN inserted i ON i.WeightUM = r.UM
    select @nullcnt = count(*) from inserted i Where i.WeightUM is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Weight UM is Invalid '
         goto error
         end
    
    -- Validate VolumeUM
    select @validcnt = count(*) from bHQUM r with (nolock) JOIN inserted i ON i.VolumeUM = r.UM
    select @nullcnt = count(*) from inserted i Where i.VolumeUM is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Volume capacity UM is Invalid '
         goto error
         end
    
    -- Ownership Status
    select @validcnt = count(*) from inserted i where i.OwnershipStatus in ('O','R','C','L')
    if @validcnt <> @numrows
         begin
         select @errmsg = 'Ownership Status is Invalid '
         goto error
         end
    
    -- Validate APCo
    select @validcnt = count(*) from bAPCO r with (nolock) JOIN inserted i ON i.APCo = r.APCo
    select @nullcnt = count(*) from inserted i Where i.APCo is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'AP Company is Invalid '
         goto error
         end
    
    -- Validate Vendor Group
    select @validcnt = count(*) from bHQGP r with (nolock) JOIN inserted i ON i.VendorGroup = r.Grp
    select @nullcnt = count(*) from inserted i Where i.VendorGroup is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Vendor Group is Invalid '
         goto error
         end
    
    -- Validate Vendor
    select @validcnt = count(*) from bAPVM r with (nolock) JOIN inserted i ON i.VendorGroup = r.VendorGroup and i.LeasedFrom = r.Vendor
    select @nullcnt = count(*) from inserted i Where i.LeasedFrom is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Vendor is Invalid '
         goto error
         end
    
    -- Validate ARCo
    select @validcnt = count(*) from bARCO r with (nolock) JOIN inserted i ON i.ARCo = r.ARCo
    select @nullcnt = count(*) from inserted i Where i.ARCo is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'AR Company is Invalid '
         goto error
         end
    
    -- Validate Customer Group
    select @validcnt = count(*) from bHQGP r with (nolock) JOIN inserted i ON i.CustGroup = r.Grp
    select @nullcnt = count(*) from inserted i Where i.CustGroup is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Customer Group is Invalid '
         goto error
         end
    
    -- Validate Customer
    select @validcnt = count(*) from bARCM r with (nolock) JOIN inserted i ON i.CustGroup = r.CustGroup and i.Customer = r.Customer
    select @nullcnt = count(*) from inserted i Where i.Customer is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Customer is Invalid '
         goto error
         end
    
    /*
    -- Capitalized Status
    select @validcnt = count(*) from inserted i where i.Capitalized in ('Y','N')
    if @validcnt <> @numrows
         begin
         select @errmsg = 'Capitalized flag is Invalid '
         goto error
         end*/
    
    
    -- Validate Attached To equipment
    select @validcnt = count(*) from bEMEM r with (nolock) JOIN inserted i ON i.EMCo = r.EMCo and i.AttachToEquip = r.Equipment
    select @nullcnt = count(*) from inserted i Where i.AttachToEquip is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Attached To Equipment is Invalid '
         goto error
         end
    
    -- AttachPostRevenue Status
    select @validcnt = count(*) from inserted i where i.AttachPostRevenue in ('Y','N')
    if @validcnt <> @numrows
         begin
         select @errmsg = 'AttachPostRevenue is Invalid '
         goto error
         end
    
    -- Validate Component of Equipment
    select @validcnt = count(*) from bEMEM r with (nolock) JOIN inserted i ON i.EMCo = r.EMCo and i.CompOfEquip = r.Equipment
    select @nullcnt = count(*) from inserted i Where i.CompOfEquip is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Component of Equipment is Invalid '
         goto error
         end
    
    -- Validate Component Type Code
    select @validcnt = count(*) from bEMTY r with (nolock) JOIN inserted i ON i.EMGroup = r.EMGroup and i.ComponentTypeCode = r.ComponentTypeCode
    select @nullcnt = count(*) from inserted i Where i.ComponentTypeCode is null
    if @validcnt + @nullcnt <> @numrows
         begin
         select @errmsg = 'Component type code is Invalid '
         goto error
         end
    
    -- Validate FuelType to 'N' if null
    select @validcnt = count(*) from inserted i where i.FuelType in ('D','G','N','O')
    if @validcnt <> @numrows
         	begin
         	select @errmsg = 'Fuel Type is Invalid '
         	goto error
         	end
     
    -- Create and initial entry in EMMR if there are hours or miles to record. Need to do this in a cursor since
    -- each record requires an incremented Trans.
     select @emco = min(EMCo) from inserted
     while @emco is not null
     	begin
     	select @equip = min(Equipment) from inserted
     	where EMCo = @emco and (HourReading <> 0 or ReplacedHourReading <> 0 or OdoReading <> 0 or ReplacedOdoReading <> 0)
     	while @equip is not null
     		begin
     		
     		select @mth = dbo.vfDateOnlyMonth() ----convert(smalldatetime,convert(varchar(2),Month(getdate())) + '/01/' + convert(varchar(4),year(getdate())))
   
            --Reading should be the most current date from EMEM (tv 11/18/03 23032)
            ---- #141031
            select @readingdate = isnull(case when isnull(HourDate,'01/01/1970') > isnull(OdoDate,'01/01/1970')
					then HourDate
					else OdoDate end,
					dbo.vfDateOnly())
            from inserted where EMCo = @emco and Equipment = @equip
   		 
     		exec @trans = dbo.bspHQTCNextTrans 'bEMMR', @emco, @mth, @msg output
     		if @trans = 0
     			begin
     			select @errmsg = @msg
     			goto error
     			end
     		
     		/* Make insertion into bEMMR */
     		insert into 
            bEMMR (EMCo, Mth, EMTrans, BatchId, Equipment, PostingDate, ReadingDate, Source, PreviousHourMeter,
     		       CurrentHourMeter, PreviousTotalHourMeter, CurrentTotalHourMeter, Hours, PreviousOdometer,
     		       CurrentOdometer, CurrentTotalOdometer, PreviousTotalOdometer, Miles, InUseBatchID)
			---- #132064 #141031
			select EMCo,@mth, @trans,null,Equipment, dbo.vfDateOnly(), @readingdate,'EMEM Init',
				0 /*isnull(HourReading,0)*/, ---previous hour meter
				isnull(HourReading,0),
				0 /*isnull(HourReading,0) + isnull(ReplacedHourReading,0)*/, ----previous total hour meter
				isnull(HourReading,0) + isnull(ReplacedHourReading,0), 0,
				0 /*isnull(OdoReading,0)*/, ----previous odometer
				isnull(OdoReading,0),
				isnull(OdoReading,0)+ isnull(ReplacedOdoReading,0),
				0 /*isnull(OdoReading,0)+ isnull(ReplacedOdoReading,0)*/, ----previous total odometer
				0,null
			from inserted i 
			where EMCo = @emco and Equipment = @equip
     		
     		select @equip = min(Equipment) from inserted where EMCo = @emco and Equipment > @equip
     		end
    
     	select @emco = min(EMCo) from inserted where EMCo > @emco
     	end
    
    
    -- Create initial record in bEMHC for Equipment with Type  'C'.
    -- Consolidated statement per Issue 16471.
    insert into bEMHC (EMCo, Component, Seq, ComponentOfEquip, DateXferOn, DateXferOff, 
     	MasterEquipHoursOn, MasterEquipHoursOff, 
     	MasterEquipMilesOn, MasterEquipMilesOff, 
     	MasterEquipFuelOn, MasterEquipFuelOff, 
     	ComponentHoursOn, ComponentHoursOff, 
     	ComponentMilesOn, ComponentMilesOff, 
     	ComponentFuelOn,ComponentFuelOff, 
     	Notes, Reason)
    select i.EMCo, i.Equipment, 1, i.CompOfEquip, dbo.vfDateOnly(), null, 
     	e.ReplacedOdoReading + e.HourReading, null, 
     	e.ReplacedOdoReading + e.OdoReading, null, 
     	e.FuelUsed, null, 
     	i.ReplacedHourReading + i.HourReading, null, 
     	i.ReplacedOdoReading + i.OdoReading, null, 
     	i.FuelUsed, null, 
     	null, null
    from inserted i join bEMEM e with (nolock) on e.EMCo = i.EMCo and e.Equipment = i.CompOfEquip
    where i.Type = 'C' 
    and not exists(select EMCo from bEMHC c with (nolock) where c.EMCo = i.EMCo and c.Component = i.Equipment)
     
    -- Audit inserts
    insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    select 'bEMEM','EM Company: ' + convert(char(3), i.EMCo) + ' Equipment: ' + i.Equipment, i.EMCo, 'A',
      		null, null, null, getdate(), SUSER_SNAME()
    from inserted i, EMCO e
    where i.EMCo = e.EMCo and e.AuditEquipment = 'Y'
    
    
    
    return
    
    
    
    error:
         select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMEM'
         RAISERROR(@errmsg, 11, -1);
         rollback transaction
    
    
    
    
   
   
   
   
   
   
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btEMEMu    Script Date: 8/28/99 9:37:17 AM ******/
CREATE trigger [dbo].[btEMEMu] on [dbo].[bEMEM] for update as
     

/*--------------------------------------------------------------
 * Created:  bc  04/14/99
 * Modified: TV 08/03/01 Validate Fuel Type
 *           bc 10/22/01 - added Component update code
 *			RM 12/03/01 - Validate ShopGroup with Shop
 *			JM 2/11/02 - Added initialization of record to EMHC if Type changed to 'C' for component.
 *			JM 3/5/02 - Removed initialization of record to EMHC.
 *    		DANF Changed Audit selecttion to use table bEMCO instead of the view EMCO
 *			JM 5-8-02 Added checks to verify Component recs have valid CompOfEquip and ComponentTypeCode;
 *				and Equip recs have nulls
 *			GG 05/21/02 - #17372 - changed component update logic to reduce number of updates to EMEM,
 *				corrected Department and Category validation, corrected HQMA updates
 *           TV 03/12/03 - Added FuelType 'O'
 *           TV 11/18/03 23032 - Changed Insert into EMMR to include Date and Previous. 
 *			 TV 02/11/04 - 23061 added isnulls
 *			TV 04/12/04 24322 - Equip was a comp
 *			TV 4/17/04 24504 - Added 'L' (leased to OwnershipType)
 *			TV 08/09/04 25332 no no no!! POST BETA 3- Add new Equip, save, then add meter info, all equip updated 
 *			TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
 *			TV 08/02/05 29442 - Error in btEMDCi causing AP Batch to Hang - Missing fuelcapum in EMEM 
 *			TJL 05/24/07 - Issue #123919, Generate correct Mth value for Update to EMMR.Mth field
 *			TRL 08/12/08 - Issue 126196, EM EuipmentChange Update, Add auditing
 *			DAN SO 06/18/09 - Issue #132538 - Add ExpectedLifeTimeFrame auditing
 *			GF 01/15/20010 - issue #137547 license plate state validation
*			TRL 03/31/10 - Issue 132064, changed update to EMMR Previous Meter Columns 
*			GF 11/21/2010 - issue #141031
 *
 *			
 *  Insert trigger for EM Equipment Master
 *
 *--------------------------------------------------------------*/
     declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @rcode int,
     		@emco bCompany, @equip bEquip, @odoreading bHrs, @hourreading bHrs, @old_odoreading bHrs,
         	@old_hourreading bHrs, @ododate bDate, @hourdate bDate, @old_ododate bDate, @old_hourdate bDate,
         	@component bEquip, @fuelused bUnits, @old_fuelused bUnits, @fueldate bDate, @readingdate bMonth, 
             @trans bTrans, @mth bMonth, @equipcodechangeinprogressYN bYN,@msg varchar(255),
            /*Issue 132064*/
            @replacedodoreading bHrs, @replacedhourreading bHrs, @replacedododate bDate, @replacedhourdate bDate,
            @source varchar(10)
     
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
     
	select @equipcodechangeinprogressYN = IsNull(ChangeInProgress,'N') from inserted
	If @equipcodechangeinprogressYN = 'N'
	begin
     -- see if any fields have changed that is not allowed
     if update(EMCo) or Update(Equipment)
         begin
         select @validcnt = count(*) from inserted i
         JOIN deleted d ON d.EMCo = i.EMCo and d.Equipment=i.Equipment
         if @validcnt <> @numrows
             begin
             select @errmsg = 'Primary key fields may not be changed'
             GoTo error
             End
         End
     end


     -- Validate EM Group
     if update(EMGroup)
     	begin
     	select @validcnt = count(*) from bHQGP r with (nolock) JOIN inserted i ON i.EMGroup = r.Grp
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'EM Group is Invalid '
     		goto error
     		end
     	end
     
     -- Validate Equipment Status
     if update(Status)
     	begin
     	select @validcnt = count(*) from inserted i where i.Status in ('A','I','D')
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'Equipment Status is Invalid '
     		goto error
     		end
     	end
     
     -- Validate Equipment type
     if update(Type)
     	begin
     	select @validcnt = count(*) from inserted i where i.Type in ('E','C')
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'Equipment Type is Invalid '
     		goto error
     		end
     
     	-- Verify that Components with Type = 'C' have a valid CompOfEquip and a valid ComponentTypeCode
     	select @nullcnt = count(*) from inserted i where i.Type = 'E'
     	select @validcnt = count(*) from bEMEM e with (nolock)
     	JOIN inserted i ON i.EMCo = e.EMCo and e.Equipment = i.CompOfEquip and e.Type = 'E'
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'CompOfEquip is null or invalid for Component entry '
     		goto error
     		end
  
     
     	select @validcnt = count(*) from bEMTY r with (nolock) 
     	JOIN inserted i ON i.EMGroup = r.EMGroup and i.ComponentTypeCode = r.ComponentTypeCode
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'ComponentTypeCode is null or invalid for Component entry'
     		goto error
     		end
     
     	-- Verify that Equipments with Type = 'E' have no CompOfEquip and no ComponentTypeCode
     	select @nullcnt = count(*) from inserted i where i.Type = 'C'
     	select @validcnt = count(*) from inserted i where  i.Type = 'E' and i.CompOfEquip is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'CompOfEquip must be null for Equipment entry '
     		goto error
     		end
     
     	select @validcnt = count(*) from inserted i where i.Type = 'E' and i.ComponentTypeCode is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'ComponentTypeCode must be null for Equipment entry '
     		goto error
     		end
     	end
     
     -- Validate Department
     if update(Department)
     	begin
     	select @validcnt = count(*) from bEMDM r with (nolock) 
     	JOIN inserted i ON  i.EMCo = r.EMCo  and i.Department = r.Department
     	select @nullcnt = count(*) from inserted i Where i.Type = 'C'--Added TV 04/12/04 24322 - Equip was a comp
       if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Department is Invalid '
     		goto error
     		end
     	end
     
     -- Validate Category
     if update(Category)
     	begin
     	select @validcnt = count(*) from bEMCM r with (nolock) 
     	JOIN inserted i ON i.EMCo = r.EMCo  and i.Category = r.Category
     	select @nullcnt = count(*) from inserted i Where i.Type = 'C'--Added TV 04/12/04 24322 - Equip was a comp
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Category is Invalid '
     		goto error
     		end
     	end
     
     -- Validate Location
     if update(Location)
     	begin
     	select @validcnt = count(*) from bEMLM r with (nolock)
     	JOIN inserted i ON  i.EMCo = r.EMCo  and i.Location = r.EMLoc
     	select @nullcnt = count(*) from inserted i Where  i.Location is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Location is Invalid '
     		goto error
     		end
     	end
     
     -- Validate Shop
     if update(Shop)
     	begin
     	select @validcnt = count(*) from bEMSX r with (nolock)
     	JOIN inserted i ON  i.Shop = r.Shop and i.ShopGroup = r.ShopGroup
     	select @nullcnt = count(*) from inserted i Where  i.Shop is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Shop is Invalid '
     		goto error
     		end
     	end
     
     -- Validate RevCode
     if update(RevenueCode)
     	begin
     	select @validcnt = count(*) from bEMRC r with (nolock)
     	JOIN inserted i ON i.EMGroup = r.EMGroup  and i.RevenueCode = r.RevCode
     	select @nullcnt = count(*) from inserted i Where i.RevenueCode is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Revenue Code is Invalid '
     		goto error
     		end
     	end
     
     -- Validate PRCo
     if update(PRCo)
     	begin
     	select @validcnt = count(*) from bPRCO r with (nolock)
     	JOIN inserted i ON i.PRCo = r.PRCo
     	select @nullcnt = count(*) from inserted i Where i.PRCo is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'PR Company is Invalid '
     		goto error
     		end
     	end
     
     -- Validate Operator
     if update(Operator)
     	begin
     	select @validcnt = count(*) from bPREH r with (nolock)
     	JOIN inserted i ON i.PRCo = r.PRCo and i.Operator = r.Employee
     	select @nullcnt = count(*) from inserted i Where i.Operator is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Operator is Invalid '
     		goto error
     		end
     	end
     
     -- Validate JCCo
     if update(JCCo)
     	begin
     	select @validcnt = count(*) from bJCCO r with (nolock)
     	JOIN inserted i ON i.JCCo = r.JCCo
     	select @nullcnt = count(*) from inserted i Where i.JCCo is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'JC Company is Invalid '
     		goto error
     		end
     	end
     
     -- Validate Phase Group
   
     if update(PhaseGrp)
     	begin
     	select @validcnt = count(*) from bHQGP r with (nolock)
     	JOIN inserted i ON i.PhaseGrp = r.Grp
     	select @nullcnt = count(*) from inserted i Where i.PhaseGrp is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Phase Group is Invalid '
     		goto error
     		end
     	end
     
     -- Validate Job
     if update(Job)
     	begin
     	select @validcnt = count(*) from bJCJM r with (nolock)
     	JOIN inserted i ON i.JCCo = r.JCCo and i.Job = r.Job
     	select @nullcnt = count(*) from inserted i Where i.Job is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'JC Job is Invalid '
     		goto error
     		end
     	end
     
     -- Validate UsageCostType
     if update(UsageCostType)
     	begin
     	select @validcnt = count(*) from bJCCT r with (nolock)
     	JOIN inserted i ON i.PhaseGrp = r.PhaseGroup and i.UsageCostType = r.CostType
     	select @nullcnt = count(*) from inserted i Where i.UsageCostType is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'JC Cost Type is Invalid '
     		goto error
     		end
     	end
     
     -- Validate State
     if update(LicensePlateState)
     	begin
		-- validate State - all State values must exist in bHQST 137547
		if exists(select top 1 1 from inserted i where [LicensePlateState] not in(select [State] from dbo.bHQST))
			begin
			select @errmsg = 'License plate state is Invalid '
			goto error
			end
		end
     
     -- Validate FuelMatlCode
     if update(FuelMatlCode)
     	begin
     	select @validcnt = count(*) from bHQMT r with (nolock)
     	JOIN inserted i ON i.MatlGroup = r.MatlGroup and i.FuelMatlCode = r.Material
     	select @nullcnt = count(*) from inserted i Where i.FuelMatlCode is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Fuel material code is Invalid '
     		goto error
     		end
     	end
     
     -- Validate FuelCostCode
     if update(FuelCostCode)
     	begin
     	select @validcnt = count(*) from bEMCC r with (nolock)
     	JOIN inserted i ON i.EMGroup = r.EMGroup and i.FuelCostCode = r.CostCode
     	select @nullcnt = count(*) from inserted i Where i.FuelCostCode is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Fuel cost code is Invalid '
     		goto error
     		end
     	end
     
     -- Validate FuelCostType
     if update(FuelCostType)
     	begin
     	select @validcnt = count(*) from bEMCT r with (nolock)
     	JOIN inserted i ON i.EMGroup = r.EMGroup and i.FuelCostType = r.CostType
     	select @nullcnt = count(*) from inserted i Where i.FuelCostType is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Fuel cost type is Invalid '
     		goto error
     		end
     	end
     
     -- Validate FuelCapUM
     if update(FuelCapUM)
     	begin
     	select @validcnt = count(*) from bHQUM r with (nolock)
     	JOIN inserted i ON i.FuelCapUM = r.UM
     	select @nullcnt = count(*) from inserted i Where i.FuelCapUM is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Fuel capacity UM is Invalid '
     		goto error
     		end
     	end
     
     -- Validate WeightUM
     if update(WeightUM)
     	begin
     	select @validcnt = count(*) from bHQUM r with (nolock)
 
     	JOIN inserted i ON i.WeightUM = r.UM
     	select @nullcnt = count(*) from inserted i Where i.WeightUM is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Weight UM is Invalid '
     		goto error
     		end
     	end
     
     -- Validate VolumeUM
     if update(VolumeUM)
     	begin
     	select @validcnt = count(*) from bHQUM r with (nolock)
     	JOIN inserted i ON i.VolumeUM = r.UM
     	select @nullcnt = count(*) from inserted i Where i.VolumeUM is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Volume capacity UM is Invalid '
     		goto error
     		end
     	end
     
     -- Ownership Status
     if update(OwnershipStatus)
     	begin
     	select @validcnt = count(*) from inserted i where i.OwnershipStatus in ('O','R','C','L')
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'Ownership Status is Invalid '
     		goto error
     		end
     	end
     
     -- Validate APCo
     if update(APCo)
     	begin
     	select @validcnt = count(*) from bAPCO r with (nolock) 
     	JOIN inserted i ON i.APCo = r.APCo
     	select @nullcnt = count(*) from inserted i Where i.APCo is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'AP Company is Invalid '
     		goto error
     		end
     	end
     
     -- Validate Vendor Group
     if update(VendorGroup)
     	begin
     	select @validcnt = count(*) from bHQGP r with (nolock)
     	JOIN inserted i ON i.VendorGroup = r.Grp
     	select @nullcnt = count(*) from inserted i Where i.VendorGroup is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Vendor Group is Invalid '
     		goto error
     		end
     	end
     
     -- Validate Vendor
     if update(LeasedFrom)
     	begin
     	select @validcnt = count(*) from bAPVM r with (nolock)
     	JOIN inserted i ON i.VendorGroup = r.VendorGroup and i.LeasedFrom = r.Vendor
     	select @nullcnt = count(*) from inserted i Where i.LeasedFrom is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Vendor is Invalid '
     		goto error
     		end
     	end
     
     -- Validate ARCo
     if update(ARCo)
     	begin
     	select @validcnt = count(*) from bARCO r with (nolock)
     	JOIN inserted i ON i.ARCo = r.ARCo
     	select @nullcnt = count(*) from inserted i Where i.ARCo is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'AR Company is Invalid '
     		goto error
     		end
     	end
     
     -- Validate Customer Group
     if update(CustGroup)
     	begin
     	select @validcnt = count(*) from bHQGP r with (nolock)
     	JOIN inserted i ON i.CustGroup = r.Grp
     	select @nullcnt = count(*) from inserted i Where i.CustGroup is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Customer Group is Invalid '
     
     		goto error
     		end
     	end
     
     -- Validate Customer
     if update(Customer)
     	begin
     	select @validcnt = count(*) from bARCM r with (nolock)
     	JOIN inserted i ON i.CustGroup = r.CustGroup and i.Customer = r.Customer
     	select @nullcnt = count(*) from inserted i Where i.Customer is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Customer is Invalid '
     		goto error
     		end
     	end
     
     -- Validate Attached To equipment
     if update(AttachToEquip)
     	begin
     	select @validcnt = count(*) from bEMEM r with (nolock)
     	JOIN inserted i ON i.EMCo = r.EMCo and i.AttachToEquip = r.Equipment
     	select @nullcnt = count(*) from inserted i Where i.AttachToEquip is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Attached To Equipment is Invalid '
     		goto error
     		end
     	end
     
     /* table constraint don't need to validate
     -- AttachPostRevenue Status
     if update(AttachPostRevenue)
     	begin
     	select @validcnt = count(*) from inserted i where i.AttachPostRevenue in ('Y','N')
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'AttachPostRevenue is Invalid '
     		goto error
     		end
     	end
     */
     
     -- Validate Component of Equipment
     if update(CompOfEquip)
     	begin
     	select @validcnt = count(*) from bEMEM r with (nolock)
     	JOIN inserted i ON i.EMCo = r.EMCo and i.CompOfEquip = r.Equipment
     	select @nullcnt = count(*) from inserted i Where i.CompOfEquip is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Component of Equipment is invalid '
     		goto error
     		end
     
     	-- Verify that Components with Type = 'C' have a valid CompOfEquip and a valid ComponentTypeCode
     	select @nullcnt = count(*) from inserted i where i.Type = 'E'
     	select @validcnt = count(*) from bEMEM e with (nolock)
     	JOIN inserted i ON i.EMCo = e.EMCo and e.Equipment = i.CompOfEquip and e.Type = 'E'
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'CompOfEquip is null or invalid for Component entry '
     		goto error
     		end
     
   
     	-- Verify that Equipments with Type = 'E' have no CompOfEquip and no ComponentTypeCode
     	select @nullcnt = count(*) from inserted i where i.Type = 'C'
     	select @validcnt = count(*) from inserted i where  i.Type = 'E' and i.CompOfEquip is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'CompOfEquip must be null for Equipment entry '
     		goto error
     		end
     	end
     
     -- Validate Component Type Code
     if update(ComponentTypeCode)
     	begin
     	select @validcnt = count(*) from bEMTY r with (nolock)
     	JOIN inserted i ON i.EMGroup = r.EMGroup and i.ComponentTypeCode = r.ComponentTypeCode
     	select @nullcnt = count(*) from inserted i Where i.ComponentTypeCode is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'Component type code is Invalid '
     		goto error
     		end
     
     	select @nullcnt = count(*) from inserted i where i.Type = 'E'
     	select @validcnt = count(*) from inserted i where i.Type = 'C' and i.ComponentTypeCode is not null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'ComponentTypeCode cannot be null for Component entry'
     		goto error
     		end
     
     	select @nullcnt = count(*) from inserted i where i.Type = 'C'
     	select @validcnt = count(*) from inserted i where  i.Type = 'E' and i.ComponentTypeCode is null
     	if @validcnt + @nullcnt <> @numrows
     		begin
     		select @errmsg = 'ComponentTypeCode must be null for Equipment entry '
     		goto error
     		end
     	end
     
     
     /*
     -- CompUpdateHrs Status
     if update(CompUpdateHrs)
     	begin
     	select @validcnt = count(*) from inserted i where i.CompUpdateHrs in ('Y','N')
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'Component Update Hours flag is Invalid '
     		goto error
     		end
     	end
     
     -- CompUpdateMiles Status
     if update(CompUpdateMiles)
     	begin
     	select @validcnt = count(*) from inserted i where i.CompUpdateMiles in ('Y','N')
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'Component Update Miles flag is Invalid '
     		goto error
     		end
     	end
     
     -- CompUpdateFuel Status
     if update(CompUpdateFuel)
     	begin
     	select @validcnt = count(*) from inserted i where i.CompUpdateFuel in ('Y','N')
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'Component Update Fuel flag is Invalid '
     		goto error
     		end
     	end
     
     -- PostCostToComp Status
     if update(PostCostToComp)
     	begin
     	select @validcnt = count(*) from inserted i where i.PostCostToComp in ('Y','N')
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'Post Costs To Component flag is Invalid '
     		goto error
     		end
     	end
     */
     
     -- FuelType Validation
     if update(FuelType)
     	begin
     	select @validcnt = count(*) from inserted i where i.FuelType in ('D','G','N','O')
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'Fuel Type is Invalid '
     		goto error
    		end
     	end
   
   	if update(FuelType) or update(FuelCapUM)
   		begin
   		-- TV 08/02/05 29442 - Error in btEMDCi causing AP Batch to Hang - Missing fuelcapum in EMEM 
   	 	if exists(select top 1 1 from inserted where FuelType <> 'N' and isnull(FuelCapUM,'') = '')
   			begin
   	   	select @errmsg = 'Fuel Capacity UM required '
   	   	goto error
   	   	end  
     		end
   
     /****************************************************************************
     * Update odometer, hour meter, fuel usage for components of this equipment *
     ****************************************************************************/
     if update(HourReading) or update(OdoReading) or update(HourDate) or update(OdoDate) or update(FuelUsed) or update(LastFuelDate)
     BEGIN
     
     	-- begin process
     	if @numrows = 1
     	 	select @emco=EMCo, @equip=Equipment, @hourreading = isnull(HourReading,0), @odoreading = isnull(OdoReading,0), 
     			   @hourdate = HourDate, @ododate = OdoDate, @fuelused = FuelUsed, @fueldate = LastFuelDate
     			   
     	    from inserted
     	else
     	    begin
     	 	-- use a cursor to process each updated row
     	 	declare bEMEM_update cursor local FAST_FORWARD
     		for select EMCo, Equipment, isnull(HourReading,0), isnull(OdoReading,0), HourDate, OdoDate, FuelUsed, LastFuelDate
     	    from inserted
     	
     	 	open bEMEM_update
     	
     		fetch next from bEMEM_update into @emco, @equip, @hourreading, @odoreading, @hourdate, @ododate, @fuelused, @fueldate
     	
     		if @@fetch_status <> 0
     	 		begin
     	 		select @errmsg = 'Cursor error'
     	 		goto error
     	 		end
     		end
                          
                select @mth = convert(smalldatetime,convert(varchar(2),Month(getdate())) + '/01/' + 
                convert(varchar(4),year(getdate())))
                           
         --Insert new EMMR record if No history  exists and updating Odo or Hours
         --TV 11/18/03 23032 - Changed Insert into EMMR to include Date and Previous.
        /*Issue Start 132064*/ 
         if not exists (select top 1 1 from bEMMR where EMCo = @emco and Equipment = @equip)
	   BEGIN
			----#141031
			select @source='EMEM Init', @readingdate = isnull(case when isnull(HourDate,'01/01/1900') > isnull(OdoDate,'01/01/1900')
							then HourDate
							else OdoDate end, 
							dbo.vfDateOnly())
			from inserted where EMCo = @emco and Equipment = @equip
				exec @trans = dbo.bspHQTCNextTrans 'bEMMR', @emco, @mth, @msg output
      			if @trans = 0
      			begin
      				select @errmsg = @msg
      				goto error
      			end
      		
      			/* Make insertion into bEMMR */
      			insert into bEMMR (EMCo, Mth, EMTrans, BatchId, Equipment, PostingDate, ReadingDate, Source, PreviousHourMeter,
      				CurrentHourMeter, PreviousTotalHourMeter, CurrentTotalHourMeter, Hours, PreviousOdometer,
      				CurrentOdometer, CurrentTotalOdometer, PreviousTotalOdometer, Miles, InUseBatchID)
      			/*132064*/	
      			select EMCo,@mth, @trans,null,Equipment, dbo.vfDateOnly(), @readingdate,'EMEM Init' ,
      				0/*isnull(HourReading,0)*/, ----previous hour meter
					isnull(HourReading,0),
					0/*isnull(HourReading,0)+ isnull(ReplacedHourReading,0)*/, ----previous total hour meter
                    isnull(HourReading,0) + isnull(ReplacedHourReading,0), 0,
                    0/*OdoReading*/, ----previous odometer
                    isnull(OdoReading,0),
                    isnull(OdoReading,0) + isnull(ReplacedOdoReading,0),
                    0, ---- previous total odometer
                    0 /*isnull(OdoReading,0)+ isnull(ReplacedOdoReading,0)*/,null
      			from inserted i 
				where EMCo = @emco and Equipment = @equip
      			-- TV 08/09/04 25332 no no no!! POST BETA 3- Add new Equip, save, then add meter info, all equip updated 
      			--select @equip = min(Equipment) from inserted where EMCo = @emco and Equipment > @equip
      	--end/*Issue 132064*/
		end 
     	update_check:
     	-- get old readings
     	select @old_hourreading = HourReading, @old_odoreading = OdoReading, @old_fuelused = FuelUsed
     	from deleted where EMCo = @emco and Equipment = @equip
     
     		-- spin through any and all of this equipment's components
     		select @component = null
     		select @component = min(Equipment) from bEMEM with (nolock) where EMCo = @emco and CompOfEquip = @equip
     		while @component is not null
     		begin
     	
     		-- update the component based on Component's flags
     		update bEMEM
     		set  HourReading = isnull(case when (CompUpdateHrs = 'Y' and (HourDate is null or HourDate <= @hourdate))
     										then HourReading + @hourreading - @old_hourreading
     										else HourReading end,0),
     			HourDate = case when (CompUpdateHrs = 'Y' and (HourDate is null or HourDate <= @hourdate))
     										then @hourdate else HourDate end,
     			OdoReading = isnull(case when (CompUpdateMiles = 'Y' and (OdoDate is null or OdoDate <= @ododate))
     										then OdoReading + @odoreading - @old_odoreading
     										else OdoReading end,0),
     			OdoDate = case when (CompUpdateMiles = 'Y' and (OdoDate is null or OdoDate <= @ododate))
     									then @ododate else OdoDate end,
     			FuelUsed = isnull(case when (CompUpdateFuel = 'Y' and (LastFuelDate is null or LastFuelDate <= @fueldate))
     								then FuelUsed + @fuelused - @old_fuelused
     								else FuelUsed end,0),
     			LastFuelDate = case when (CompUpdateFuel = 'Y' and (LastFuelDate is null or LastFuelDate <= @fueldate))
     									then @fueldate else LastFuelDate end
     									
     			where EMCo = @emco and Equipment = @component
     	
     		-- get next component
     		select @component = min(Equipment) from bEMEM with (nolock) where EMCo = @emco and CompOfEquip = @equip and Equipment > @component
     		if @@rowcount = 0 select @component = null
     		end
     
     
     -- finished with validation and updates (except HQ Audit)
     Valid_Finished:
     if @numrows > 1
     	begin
      	fetch next from bEMEM_update into @emco, @equip, @hourreading, @odoreading, @hourdate, @ododate, @fuelused, @fueldate
      	if @@fetch_status = 0
      		goto update_check
      	else
      		begin
      		close bEMEM_update
      		deallocate bEMEM_update
      		end
      	end
     END
     
    -- Issue 126196 OriginalEquipmentCode cannot be changed, column only updated 
	--Equipment is added
    if update(OriginalEquipmentCode)
    begin
		--Issue 126196  Audit before returning error message
		if update(OriginalEquipmentCode)
		begin
     		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		----#141031
			select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'OriginalEquipmentCode', d.OriginalEquipmentCode, i.OriginalEquipmentCode, dbo.vfDateOnly(), SUSER_SNAME()
     		from inserted i, deleted d, bEMCO e
     		where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     		and isnull(i.OriginalEquipmentCode,'') <> isnull(d.OriginalEquipmentCode,'') and e.EMCo = i.EMCo 
		end
   		select @errmsg = 'Original Equipment Code cannot be changed.'
   		goto error
    end
    
	--Issue 126196
	if update(ChangeInProgress)
	begin
       	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'ChangeInProgress', d.ChangeInProgress, i.ChangeInProgress, getdate(), SUSER_SNAME()
     	from inserted i, deleted d, bEMCO e
     	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	and isnull(i.ChangeInProgress,'') <> isnull(d.ChangeInProgress,'') and e.EMCo = i.EMCo 
	end
	if update(Equipment)
	begin
       	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Equipment', d.Equipment, i.Equipment, getdate(), SUSER_SNAME()
     	from inserted i, deleted d, bEMCO e
     	where i.EMCo = d.EMCo and i.Equipment = d.LastUsedEquipmentCode
     	and isnull(i.Equipment,'') <> isnull(d.Equipment,'') and e.EMCo = i.EMCo 
	end
    
	--Issue 126196
	if update(LastUsedEquipmentCode)
	begin
     	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     	select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'LastUsedEquipmentCode', d.LastUsedEquipmentCode, i.LastUsedEquipmentCode, getdate(), SUSER_SNAME()
     	from inserted i, deleted d, bEMCO e
     	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	and isnull(i.LastUsedEquipmentCode,'') <> isnull(d.LastUsedEquipmentCode,'') and e.EMCo = i.EMCo 
	end
	--Issue 126196
	begin
		if update(LastEquipmentChangeDate)
     	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     	select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'LastEquipmentChangeDate', d.LastEquipmentChangeDate, i.LastEquipmentChangeDate, getdate(), SUSER_SNAME()
     	from inserted i, deleted d, bEMCO e
     	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	and isnull(i.LastEquipmentChangeDate,'') <> isnull(d.LastEquipmentChangeDate,'') and e.EMCo = i.EMCo 
	end
	--Issue 126196
	if update(LastEquipmentChangeUser)
	begin
     	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     	select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'LastEquipmentChangeUser', d.LastEquipmentChangeUser, i.LastEquipmentChangeUser, getdate(), SUSER_SNAME()
     	from inserted i, deleted d, bEMCO e
     	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	and isnull(i.LastEquipmentChangeUser,'') <> isnull(d.LastEquipmentChangeUser,'') and e.EMCo = i.EMCo 
	end
	--Issue 126196
	if update(EquipmentCodeChanges)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	    select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)	
     	+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'EquipmentCodeChanges', d.EquipmentCodeChanges, i.EquipmentCodeChanges, getdate(), SUSER_SNAME()
     	from inserted i, deleted d, bEMCO e
     	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	and isnull(i.EquipmentCodeChanges,'') <> isnull(d.EquipmentCodeChanges,'') and e.EMCo = i.EMCo         	
	end

     -- Insert records into HQMA for changes made to audited fields
     if exists(select 1 from inserted i join bEMCO c on i.EMCo=c.EMCo where i.UpdateYN = 'Y' and c.AuditEquipment = 'Y')
     BEGIN
     	if update(EMGroup)
     		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     			+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'EMGroup', convert(char(3),d.EMGroup),
     			convert(char(3),i.EMGroup), getdate(), SUSER_SNAME()
     		from inserted i, deleted d, bEMCO e
     		where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     		and isnull(i.EMGroup,0) <> isnull(d.EMGroup,0) and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	
     	if update(VINNumber)
     		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     			+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'VINNumber', d.VINNumber, i.VINNumber, getdate(), SUSER_SNAME()
     		from inserted i, deleted d, bEMCO e
     		where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     		and isnull(i.VINNumber,'') <> isnull(d.VINNumber,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	
     	if update(Description)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   	and isnull(i.Description,'') <> isnull(d.Description,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     
     	if update(Manufacturer)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Manufacturer', d.Manufacturer, i.Manufacturer, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   	and isnull(i.Manufacturer,'') <> isnull(d.Manufacturer,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     
     	if update(Model)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Model', d.Model, i.Model, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.Model,'') <> isnull(d.Model,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(ModelYr)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'ModelYr', d.ModelYr, i.ModelYr, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.ModelYr,'') <> isnull(d.ModelYr,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	
     	if update(Status)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Status', d.Status, i.Status, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.Status <> d.Status and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(Type)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Type', d.Type, i.Type, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.Type <> d.Type and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(Department)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Department', d.Department, i.Department, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.Department,'') <> isnull(d.Department,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(Category)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Category', d.Category, i.Category, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.Category,'') <> isnull(d.Category,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(Location)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Location', d.Location, i.Location, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.Location,'') <> isnull(d.Location,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(Shop)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Shop', d.Shop, i.Shop, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.Shop,'') <> isnull(d.Shop,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(RevenueCode)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'RevenueCode', d.RevenueCode, i.RevenueCode, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.RevenueCode,'') <> isnull(d.RevenueCode,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(PRCo)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'PRCo', convert(char(3),d.PRCo), convert(char(3),i.PRCo), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.PRCo,0) <> isnull(d.PRCo,0) and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(Operator)
     	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Operator', convert(char(10),d.Operator), convert(char(10),i.Operator), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.Operator,0) <> isnull(d.Operator,0) and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(PhaseGrp)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Phase Group',
     	   	convert(char(3),d.PhaseGrp), convert(char(3),i.PhaseGrp), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.PhaseGrp,0) <> isnull(d.PhaseGrp,0) and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(JCCo)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'JCCo', convert(char(3),d.JCCo), convert(char(3),i.JCCo), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.JCCo,0) <> isnull(d.JCCo,0) and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(Job)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Job', d.Job, i.Job, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.Job,'') <> isnull(d.Job,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(UsageCostType)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'UsageCostType', convert(char(3),d.UsageCostType), convert(char(3),i.UsageCostType), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.UsageCostType,0) <> isnull(d.UsageCostType,0) and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(LicensePlateNo)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'LicensePlateNo', d.LicensePlateNo, i.LicensePlateNo, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.LicensePlateNo,'') <> isnull(d.LicensePlateNo,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(LicensePlateState)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'LicensePlateState', d.LicensePlateState, i.LicensePlateState, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.LicensePlateState,'') <> isnull(d.LicensePlateState,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(LicensePlateExpDate)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'LicensePlateExpDate', d.LicensePlateExpDate, i.LicensePlateExpDate, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.LicensePlateExpDate,'') <> isnull(d.LicensePlateExpDate,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(IRPFleet)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'IRPFleet', d.IRPFleet, i.IRPFleet, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.IRPFleet,'') <> isnull(d.IRPFleet,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(HourReading)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'HourReading', convert(char(12),d.HourReading), convert(char(12),i.HourReading), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.HourReading <> d.HourReading and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(HourDate)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'HourDate',	d.HourDate, i.HourDate, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.HourDate,'') <> isnull(d.HourDate,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(ReplacedHourReading)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'ReplacedHourReading',
     	   	convert(char(12),d.ReplacedHourReading), convert(char(12),i.ReplacedHourReading), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.ReplacedHourReading <> d.ReplacedHourReading and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(ReplacedHourDate)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'ReplacedHourDate',	d.ReplacedHourDate, i.ReplacedHourDate, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.ReplacedHourDate,'') <> isnull(d.ReplacedHourDate,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(OdoReading)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'OdoReading', convert(char(12),d.OdoReading), convert(char(12),i.OdoReading), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.OdoReading <> d.OdoReading and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(OdoDate)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'OdoDate',	d.OdoDate, i.OdoDate, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.OdoDate,'') <> isnull(d.OdoDate,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(ReplacedOdoReading)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'ReplacedOdoReading',
     	   		convert(char(12),d.ReplacedOdoReading), convert(char(12),i.ReplacedOdoReading), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.ReplacedOdoReading <> d.ReplacedOdoReading and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(ReplacedOdoDate)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'ReplacedOdoDate', d.ReplacedOdoDate, i.ReplacedOdoDate, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.ReplacedOdoDate,'') <> isnull(d.ReplacedOdoDate,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(FuelUsed)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'FuelUsed',
     	   		convert(char(12),d.FuelUsed), convert(char(12),i.FuelUsed), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.FuelUsed <> d.FuelUsed and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(LastFuelDate)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'LastFuelDate', d.LastFuelDate, i.LastFuelDate, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.LastFuelDate,'') <> isnull(d.LastFuelDate,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(MatlGroup)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	 		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'MatlGroup',
     	   	convert(char(12),d.MatlGroup), convert(char(12),i.MatlGroup), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.MatlGroup,0) <> isnull(d.MatlGroup,0) and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(FuelMatlCode)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'PartCode', d.FuelMatlCode, i.FuelMatlCode, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	  	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.FuelMatlCode,'') <> isnull(d.FuelMatlCode,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(FuelCostCode)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Cost Code', d.FuelCostCode, i.FuelCostCode, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.FuelCostCode,'') <> isnull(d.FuelCostCode,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(FuelCostType)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Fuel Cost Type',
     	   		convert(char(12),d.FuelCostType), convert(char(12),i.FuelCostType), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.FuelCostType,0) <> isnull(d.FuelCostType,0) and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(FuelCapUM)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Fuel Capacity UM', d.FuelCapUM, i.FuelCapUM, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.FuelCapUM,'') <> isnull(d.FuelCapUM,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(WeightUM)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Weight UM', d.WeightUM, i.WeightUM, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.WeightUM,'') <> isnull(d.WeightUM,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(WeightCapacity)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Weight Capacity',
     	   		convert(char(12),d.WeightCapacity), convert(char(12),i.WeightCapacity), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.WeightCapacity <> d.WeightCapacity and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(VolumeUM)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Volume UM', d.VolumeUM, i.VolumeUM, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.VolumeUM,'') <> isnull(d.VolumeUM,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(VolumeCapacity)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Volume Capacity',
     	   		convert(char(12),d.VolumeCapacity), convert(char(12),i.VolumeCapacity), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.VolumeCapacity <> d.VolumeCapacity and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(TareWeight)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Tare Weight',
     	   		convert(char(12),d.TareWeight), convert(char(12),i.TareWeight), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.TareWeight <> d.TareWeight and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(GrossVehicleWeight)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Gross Vehicle Weight',
     	   		convert(char(12),d.GrossVehicleWeight), convert(char(12),i.GrossVehicleWeight), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.GrossVehicleWeight <> d.GrossVehicleWeight and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(Height)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Height', d.Height, i.Height, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.Height,'') <> isnull(d.Height,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(Wheelbase)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Wheel Base', d.Wheelbase, i.Wheelbase, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.Wheelbase,'') <> isnull(d.Wheelbase,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(NoAxles)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', '# of Axles',
     	   		convert(char(12),d.NoAxles), convert(char(12),i.NoAxles), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.NoAxles <> d.NoAxles and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(Width)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Width', d.Width, i.Width, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.Width,'') <> isnull(d.Width,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(OverallLength)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Overall length', d.OverallLength, i.OverallLength, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.OverallLength,'') <> isnull(d.OverallLength,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(HorsePower)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Horse Power', d.HorsePower, i.HorsePower, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, EMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.HorsePower,'') <> isnull(d.HorsePower,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(TireSize)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Tire size', d.TireSize, i.TireSize, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.TireSize,'') <> isnull(d.TireSize,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(OwnershipStatus)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'OwnershipStatus', d.OwnershipStatus, i.OwnershipStatus, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.OwnershipStatus,'') <> isnull(d.OwnershipStatus,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(PurchasedFrom)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'PurchasedFrom', d.PurchasedFrom, i.PurchasedFrom, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.PurchasedFrom,'') <> isnull(d.PurchasedFrom,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(PurchDate)
     	  	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Purchase Date', d.PurchDate, i.PurchDate, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.PurchDate,'') <> isnull(d.PurchDate,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(PurchasePrice)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Purchase Price',
     	   	convert(char(12),d.PurchasePrice), convert(char(12),i.PurchasePrice), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.PurchasePrice <> d.PurchasePrice and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(APCo)
     	   insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'APCo', convert(varchar(3),d.APCo), convert(varchar(3),i.APCo), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.APCo,0) <> isnull(d.APCo,0) and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(VendorGroup)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Vendor Group', convert(varchar(3),d.VendorGroup), convert(varchar(3),i.VendorGroup), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.VendorGroup,0) <> isnull(d.VendorGroup,0) and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(LeasedFrom)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Leased From', convert(varchar(10),d.LeasedFrom), convert(varchar(10),i.LeasedFrom), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.LeasedFrom,0) <> isnull(d.LeasedFrom,0) and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(LeaseStartDate)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Leased Start Date', d.LeaseStartDate, i.LeaseStartDate, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.LeaseStartDate,'') <> isnull(d.LeaseStartDate,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(LeaseEndDate)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Leased End Date', d.LeaseEndDate, i.LeaseEndDate, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.LeaseEndDate,'') <> isnull(d.LeaseEndDate,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(LeasePayment)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Lease Payment',
     	   	convert(char(12),d.LeasePayment), convert(char(12),i.LeasePayment), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.LeasePayment <> d.LeasePayment and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(LeaseResidualValue)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Lease Residual value',
     	   		convert(char(12),d.LeaseResidualValue), convert(char(12),i.LeaseResidualValue), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.LeaseResidualValue <> d.LeaseResidualValue and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(ARCo)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'ARCo',
     	   		convert(varchar(3),d.ARCo), convert(varchar(3),i.ARCo), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.ARCo,0) <> isnull(d.ARCo,0) and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(Customer)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Customer',
     	   	convert(varchar(12),d.Customer), convert(varchar(12),i.Customer), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.Customer,0) <> isnull(d.Customer,0) and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(CustGroup)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Customer Group',
     	   		convert(varchar(12),d.CustGroup), convert(varchar(12),i.CustGroup), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.CustGroup,0) <> isnull(d.CustGroup,0) and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(CustEquipNo)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Customer Equipment #', d.CustEquipNo, i.CustEquipNo, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.CustEquipNo,'') <> isnull(d.CustEquipNo,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(InServiceDate)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'In Service Date', d.InServiceDate, i.InServiceDate, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.InServiceDate,'') <> isnull(d.InServiceDate,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(ExpLife)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Expected Life', convert(varchar(10),d.ExpLife), convert(varchar(10),i.ExpLife), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.ExpLife <> d.ExpLife and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y' 	
      	if update(ExpLifeTimeFrame) --#132538
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Expected Life Time Frame', d.ExpLifeTimeFrame, i.ExpLifeTimeFrame, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.ExpLifeTimeFrame <> d.ExpLifeTimeFrame and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(ReplCost)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Replacement Cost',
     	   		convert(varchar(12),d.ReplCost), convert(varchar(12),i.ReplCost), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.ReplCost <> d.ReplCost and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(CurrentAppraisal)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Current Appraisal',
     	   	convert(varchar(12),d.CurrentAppraisal), convert(varchar(12),i.CurrentAppraisal), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.CurrentAppraisal <> d.CurrentAppraisal and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(SalePrice)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Sale Price',
     	   		convert(varchar(12),d.SalePrice), convert(varchar(12),i.SalePrice), getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and i.SalePrice <> d.SalePrice and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(SoldDate)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Sold Date', d.SoldDate, i.SoldDate, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   		and isnull(i.SoldDate,'') <> isnull(d.SoldDate,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	if update(Capitalized)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Capitalized', d.Capitalized, i.Capitalized, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   	and isnull(i.Capitalized,'') <> isnull(d.Capitalized,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     
     	if update(AttachToEquip)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Attached To Equipment', d.AttachToEquip, i.AttachToEquip, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   	and isnull(i.AttachToEquip,'') <> isnull(d.AttachToEquip,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     
     	if update(AttachPostRevenue)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Attachment Post Revenue', d.AttachPostRevenue, i.AttachPostRevenue, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   	and isnull(i.AttachPostRevenue,'') <> isnull(d.AttachPostRevenue,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     
     	if update(CompOfEquip)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Component of Equipment', d.CompOfEquip, i.CompOfEquip, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   	and isnull(i.CompOfEquip,'') <> isnull(d.CompOfEquip,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     
     	if update(ComponentTypeCode)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Component Type Code', d.ComponentTypeCode, i.ComponentTypeCode, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   	and isnull(i.ComponentTypeCode,'') <> isnull(d.ComponentTypeCode,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     
     	if update(CompUpdateHrs)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Component Update Hours', d.CompUpdateHrs, i.CompUpdateHrs, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   	and isnull(i.CompUpdateHrs,'') <> isnull(d.CompUpdateHrs,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     
     	if update(CompUpdateMiles)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Component Update Miles', d.CompUpdateMiles, i.CompUpdateMiles, getdate(), SUSER_SNAME()
     
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   	and isnull(i.CompUpdateMiles,'') <> isnull(d.CompUpdateMiles,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     
     	if update(CompUpdateFuel)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Component Update Fuel', d.CompUpdateFuel, i.CompUpdateFuel, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   	and isnull(i.CompUpdateFuel,'') <> isnull(d.CompUpdateFuel,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     
     	if update(PostCostToComp)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Post Cost to Components', d.PostCostToComp, i.PostCostToComp, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   	and isnull(i.PostCostToComp,'') <> isnull(d.PostCostToComp,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     
     	if update(JobDate)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'Job Date', d.JobDate, i.JobDate, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   	and isnull(i.JobDate,'') <> isnull(d.JobDate,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
     	
     	if update(MSTruckType)
     	   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select 'bEMEM', 'EM Company: ' + convert(char(3),i.EMCo)
     	   		+ 'Equipment: ' + i.Equipment, i.EMCo, 'C', 'MS Truck Type', d.MSTruckType, i.MSTruckType, getdate(), SUSER_SNAME()
     	   	from inserted i, deleted d, bEMCO e
     	   	where i.EMCo = d.EMCo and i.Equipment = d.Equipment
     	   	and isnull(i.MSTruckType,'') <> isnull(d.MSTruckType,'') and e.EMCo = i.EMCo and e.AuditEquipment = 'Y' and i.UpdateYN = 'Y'
    END
     
     return
     
         
     
     error:
     	select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Equipment Master!'
         RAISERROR(@errmsg, 11, -1);
         rollback transaction
     
     
     
     
     
    
    
    
    
    
    
    
   
   
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMEM] ON [dbo].[bEMEM] ([EMCo], [Equipment]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMEM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMEM].[AttachPostRevenue]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMEM].[Capitalized]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMEM].[CompUpdateHrs]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMEM].[CompUpdateMiles]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMEM].[CompUpdateFuel]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMEM].[PostCostToComp]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMEM].[UpdateYN]'
GO
