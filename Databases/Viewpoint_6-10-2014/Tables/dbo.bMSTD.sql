CREATE TABLE [dbo].[bMSTD]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[MSTrans] [dbo].[bTrans] NOT NULL,
[HaulTrans] [dbo].[bTrans] NULL,
[SaleDate] [dbo].[bDate] NOT NULL,
[Ticket] [dbo].[bTic] NULL,
[FromLoc] [dbo].[bLoc] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[MatlVendor] [dbo].[bVendor] NULL,
[SaleType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[PaymentType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[CheckNo] [dbo].[bCMRef] NULL,
[Hold] [dbo].[bYN] NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[INCo] [dbo].[bCompany] NULL,
[ToLoc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[MatlPhase] [dbo].[bPhase] NULL,
[MatlJCCType] [dbo].[bJCCType] NULL,
[GrossWght] [dbo].[bUnits] NOT NULL,
[TareWght] [dbo].[bUnits] NOT NULL,
[WghtUM] [dbo].[bUM] NULL,
[MatlUnits] [dbo].[bUnits] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[MatlTotal] [dbo].[bDollar] NOT NULL,
[MatlCost] [dbo].[bDollar] NOT NULL,
[HaulerType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[HaulVendor] [dbo].[bVendor] NULL,
[Truck] [dbo].[bTruck] NULL,
[Driver] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[TruckType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[StartTime] [smalldatetime] NULL,
[StopTime] [smalldatetime] NULL,
[Loads] [smallint] NOT NULL,
[Miles] [dbo].[bUnits] NOT NULL,
[Hours] [dbo].[bHrs] NOT NULL,
[Zone] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[HaulCode] [dbo].[bHaulCode] NULL,
[HaulPhase] [dbo].[bPhase] NULL,
[HaulJCCType] [dbo].[bJCCType] NULL,
[HaulBasis] [dbo].[bUnits] NOT NULL,
[HaulRate] [dbo].[bUnitCost] NOT NULL,
[HaulTotal] [dbo].[bDollar] NOT NULL,
[PayCode] [dbo].[bPayCode] NULL,
[PayBasis] [dbo].[bUnits] NOT NULL,
[PayRate] [dbo].[bUnitCost] NOT NULL,
[PayTotal] [dbo].[bDollar] NOT NULL,
[RevCode] [dbo].[bRevCode] NULL,
[RevBasis] [dbo].[bUnits] NOT NULL,
[RevRate] [dbo].[bUnitCost] NOT NULL,
[RevTotal] [dbo].[bDollar] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxTotal] [dbo].[bDollar] NOT NULL,
[DiscBasis] [dbo].[bUnits] NOT NULL,
[DiscRate] [dbo].[bUnitCost] NOT NULL,
[DiscOff] [dbo].[bDollar] NOT NULL,
[TaxDisc] [dbo].[bDollar] NOT NULL,
[Void] [dbo].[bYN] NOT NULL,
[MSInv] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[APRef] [dbo].[bAPReference] NULL,
[VerifyHaul] [dbo].[bYN] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[AuditYN] [dbo].[bYN] NOT NULL,
[Purge] [dbo].[bYN] NOT NULL,
[Changed] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSTD_Changed] DEFAULT ('N'),
[ReasonCode] [dbo].[bReasonCode] NULL,
[ShipAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[APCo] [dbo].[bCompany] NULL,
[APMth] [dbo].[bMonth] NULL,
[MatlAPCo] [dbo].[bCompany] NULL,
[MatlAPMth] [dbo].[bMonth] NULL,
[MatlAPRef] [dbo].[bAPReference] NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SurchargeKeyID] [bigint] NULL,
[SurchargeCode] [smallint] NULL,
[HaulPayTaxCode] [dbo].[bTaxCode] NULL,
[HaulPayTaxRate] [dbo].[bUnitCost] NULL,
[HaulPayTaxAmt] [dbo].[bDollar] NULL,
[HaulPayTaxType] [tinyint] NULL,
[HaulAPTLKeyID] [bigint] NULL,
[MatlAPTLKeyID] [bigint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE trigger [dbo].[btMSTDd] on [dbo].[bMSTD] for DELETE as
/*-----------------------------------------------------------------
* Created:		GG 10/26/00
* Modified:		RM 03/05/01 - Added code to save deleted tickets based on MSCompany SaveDeleted flag.
*				GF 10/08/01 - Cursor label is bMSTD_delete, but in fetch next was being called bMSTD_Update.
*				GH 12/11/01 - Changed datatype bAPRef to use bAPReference Issue #15570
*				GF 06/20/03 - issue #20785 - added APCo, APMth to bMSTX. added to insert.
*				GF 07/23/03 - issue #21933 - speed improvement clean up.
*				GF 03/02/2005 - issue #19185 material vendor payment enhancement
*				CHS 03/12/08 - issue #127082 international addresses
*				DAN SO 05/18/09 - Issue: #133441 - Handle Attachment deletion differently
*				CHS	10/29/2009	- issue #136209 - tweak to auditing key string.
*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
*				GF 08/07/2012 TK-16813 pass phase group and phase to trigger delete proc
*				GF 08/10/2012 TK-16962 pass vendor group and material vendor to MSTD trigger proc
*
*
* Backs out units sold to MS Quote Detail
*
* Backs out MS Sales Activity
*
* Inserts HQ Master Audit entries if Ticket Detail or Hauler Time Sheets flagged for auditing.
*/----------------------------------------------------------------
   
   declare  @numrows int, @errmsg varchar(255), @rcode int
   
--bMSTD declares
declare @msco bCompany, @mth bMonth, @fromloc bLoc, @saletype char(1), @custgroup bGroup,
		@customer bCustomer, @custjob varchar(20), @custpo varchar(20), @jcco bCompany, @job bJob,
		@inco bCompany, @toloc bLoc, @matlgroup bGroup, @material bMatl, @matlum bUM, @matlunits bUnits,
		@matltotal bDollar, @haultotal bDollar, @taxtotal bDollar, @discoff bDollar, @void bYN, @purge bYN
		----TK-16813
		,@phasegroup bGroup, @matlphase bPhase
		----TK-16962
		,@vendorgroup bGroup, @matlvendor bVendor
	

   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
if @numrows = 1
select @msco = MSCo, @mth = Mth, @fromloc = FromLoc, @matlgroup = MatlGroup, @material = Material,
       @saletype = SaleType, @custgroup = CustGroup, @customer = Customer, @custjob = CustJob,
       @custpo = CustPO, @jcco = JCCo, @job = Job, @inco = INCo, @toloc = ToLoc, @matlum = UM,
       @matlunits = MatlUnits, @matltotal = MatlTotal, @haultotal = HaulTotal, @taxtotal = TaxTotal,
       @discoff = DiscOff, @void = Void, @purge = Purge
		----TK-16813
		,@phasegroup = PhaseGroup, @matlphase = MatlPhase
		----TK-16962
		,@vendorgroup = VendorGroup, @matlvendor = MatlVendor	
   from deleted
else
  begin
-- use a cursor to process each deleted row
declare bMSTD_delete cursor LOCAL FAST_FORWARD for
	select MSCo, Mth, FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob,
			CustPO, JCCo, Job, INCo, ToLoc, UM, MatlUnits, MatlTotal, HaulTotal, TaxTotal, DiscOff, Void, Purge
			----TK-16813
			,PhaseGroup, MatlPhase
			----TK-16962
			,VendorGroup, MatlVendor
   from deleted

open bMSTD_delete

   fetch next from bMSTD_delete into @msco, @mth, @fromloc, @matlgroup, @material, @saletype, @custgroup,
       @customer, @custjob, @custpo, @jcco, @job, @inco, @toloc,  @matlum, @matlunits, @matltotal,
       @haultotal, @taxtotal, @discoff, @void, @purge
       ----TK-16813
       ,@phasegroup, @matlphase
       ----TK-16962
       ,@vendorgroup, @matlvendor

   if @@fetch_status <> 0
	begin
	select @errmsg = 'Cursor error'
	goto error
	end
end
   
   delete_check:
   --process old info unless void or purging Ticket detail
   if @void = 'N' and @purge = 'N'
   	begin
       exec @rcode = dbo.bspMSTDTrigProc @msco, @mth, @fromloc, @matlgroup, @material, @saletype,
               @custgroup, @customer, @custjob, @custpo, @jcco, @job, @inco, @toloc, @matlum,
               @matlunits, @matltotal, @haultotal, @taxtotal, @discoff
               ----TK-16813
               ,@phasegroup, @matlphase
               ----TK-16962
               ,@vendorgroup, @matlvendor, 'O'
               ,@errmsg output
   	if @rcode = 1 goto error
   	end
   
   if @numrows > 1
   	begin
   	fetch next from bMSTD_delete into @msco, @mth, @fromloc, @matlgroup, @material, @saletype, @custgroup,
           @customer, @custjob, @custpo, @jcco, @job, @inco, @toloc,  @matlum, @matlunits, @matltotal,
           @haultotal, @taxtotal, @discoff, @void, @purge
			----TK-16813
			,@phasegroup, @matlphase
			----TK-16972
			,@vendorgroup, @matlvendor
   	if @@fetch_status = 0
   		goto delete_check
   	else
   		begin
   		close bMSTD_delete
   		deallocate bMSTD_delete
   		end
   	end
   
   -- Insert into deleted batch table if MSCompany flag 'SaveDeleted' set to 'Y' and not purging
   insert bMSTX(MSCo,Mth,MSTrans,SaleDate,Ticket,FromLoc,VendorGroup,MatlVendor,SaleType,CustGroup,Customer,
   	CustJob,CustPO,PaymentType,CheckNo,Hold,JCCo,Job,PhaseGroup,INCo,ToLoc,MatlGroup,Material,UM,
   	MatlPhase,MatlJCCType,GrossWght,TareWght,WghtUM,MatlUnits,UnitPrice,ECM,MatlTotal,MatlCost,HaulerType,
   	HaulVendor,Truck,Driver,EMCo,Equipment,EMGroup,PRCo,Employee,TruckType,StartTime,StopTime,Loads,Miles,
   	Hours,Zone,HaulCode,HaulPhase,HaulJCCType,HaulBasis,HaulRate,HaulTotal,PayCode,PayBasis,PayRate,PayTotal,
   	RevCode,RevBasis,RevRate,RevTotal,TaxGroup,TaxCode,TaxType,TaxBasis,TaxTotal,DiscBasis,DiscRate,DiscOff,
   	TaxDisc,Void,APRef,VerifyHaul,Changed,ReasonCode,BatchId,DeleteDate,VPUserName,ShipAddress,City,State,Zip,
   	APCo,APMth,MatlAPCo,MatlAPMth,MatlAPRef,Country)
   select d.MSCo,d.Mth,d.MSTrans,d.SaleDate,d.Ticket,d.FromLoc,d.VendorGroup,d.MatlVendor,d.SaleType,d.CustGroup,
   	d.Customer,d.CustJob,d.CustPO,d.PaymentType,d.CheckNo,d.Hold,d.JCCo,d.Job,d.PhaseGroup,d.INCo,d.ToLoc,
   	d.MatlGroup,d.Material,d.UM,d.MatlPhase,d.MatlJCCType,d.GrossWght,d.TareWght,d.WghtUM,d.MatlUnits,
   	d.UnitPrice,d.ECM,d.MatlTotal,d.MatlCost,d.HaulerType,d.HaulVendor,d.Truck,d.Driver,d.EMCo,d.Equipment,
   	d.EMGroup,d.PRCo,d.Employee,d.TruckType,d.StartTime,d.StopTime,d.Loads,d.Miles,d.Hours,d.Zone,d.HaulCode,
   	d.HaulPhase,d.HaulJCCType,d.HaulBasis,d.HaulRate,d.HaulTotal,d.PayCode,d.PayBasis,d.PayRate,d.PayTotal,
   	d.RevCode,d.RevBasis,d.RevRate,d.RevTotal,d.TaxGroup,d.TaxCode,d.TaxType,d.TaxBasis,d.TaxTotal,d.DiscBasis,
   	d.DiscRate,d.DiscOff,d.TaxDisc,d.Void,d.APRef,d.VerifyHaul,d.Changed,d.ReasonCode,d.BatchId,getdate(),
   	suser_sname(),d.ShipAddress,d.City,d.State,d.Zip,d.APCo,d.APMth,d.MatlAPCo,d.MatlAPMth,d.MatlAPRef,d.Country
   from deleted d join  bMSCO c with (nolock) on d.MSCo = c.MSCo
   where d.Purge <> 'Y' and c.SaveDeleted = 'Y'
   


	-- ISSUE: #133441
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null
	INSERT vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
		SELECT AttachmentID, suser_name(), 'Y' 
          FROM bHQAT h join deleted d 
			ON h.UniqueAttchID = d.UniqueAttchID                  
         WHERE d.UniqueAttchID IS NOT NULL            



   -- Audit HQ deletions
   insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSTD',' Mth: ' + convert(char(8), d.Mth,1) + ' MS Trans: ' + convert(varchar(6),d.MSTrans),
       d.MSCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   from deleted d join bMSCO c with (nolock) on d.MSCo = c.MSCo
   where c.AuditTics = 'Y' and d.Purge = 'N' or (c.AuditHaulers = 'Y' and d.HaulTrans is not null)
   
   
   return

   
   
   
   error:
       select @errmsg = @errmsg +  ' - cannot delete MS Transaction Detail!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
CREATE trigger [dbo].[btMSTDi] on [dbo].[bMSTD] for INSERT as
/*-----------------------------------------------------------------
* Created: GG 10/26/00
* Modified:  RM 03/05/01 Validate Reason Code
*				GG 07/03/01 - add hierarchal Quote search  - #13888
*				GF 09/28/01 - fixed cross-company material validation.
*				GG 02/13/02 - #16085 - another fix to cross-company material validation
*				CMW 06/27/02 - #17760 - fixed error message wordings.
*				SR 07/08/02 - issue 17738 - passing in @phasegroup to bspJCVPHASE &VCOSTTYPE
*				GF 06/10/2003 - issue #21418 - not getting UM conversion properly for MSSA update/insert
*				GF 07/23/03 - issue #21933 - speed improvement clean up.
*				GF 03/19/2004 - issue #24038 - changes to MSQD update for sold units using phase if type 'J'
*				GF 02/08/2006 - issue #120087 - added check for to material group material std um <> posted um
*				GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
*				GF 01/08/2007 - issue #126665 @reasoncode missing from fetch next
*				GF 06/23/2008 - issue #128290 new tax type 3-VAT for international tax
*				DAN SO 10/15/2009 - ISSUE #129350 - Handle Surcharge materials
*				GF 08/10/2012 TK-16962 added MSQD updates for material vendor if we have one
*
*
* Validates critical column values
*
* Updates units sold to MS Quote Detail
*
* Updates MS Sales Activity
* Inserts HQ Master Audit entry if Ticket Detail or Hauler Time Sheets flagged for auditing.
   */----------------------------------------------------------------
declare @numrows int, @errmsg varchar(255), @umconv bUnitCost, @quote varchar(10), @mssaseq int,
  		@msglco bCompany, @costtype varchar(5), @rcode int, @postclosedjobs bYN, @status tinyint, 
  		@stdum bUM, @validcnt int
  
--bMSTD declares
declare @msco bCompany, @mth bMonth, @mstrans bTrans, @haultrans bTrans, @saledate bDate, @fromloc bLoc,
  		@ticket bTic, @vendorgroup bGroup, @matlvendor bVendor, @saletype char(1), @custgroup bGroup, 
  		@customer bCustomer, @custjob varchar(20), @custpo varchar(20), @paymenttype char(1), 
  		@checkno bCMRef, @jcco bCompany, @job bJob, @phasegroup bGroup, @inco bCompany, @toloc bLoc, 
  		@matlgroup bGroup, @material bMatl, @matlum bUM, @matlphase bPhase, @matljcct bJCCType, @wghtum bUM, 
  		@matlunits bUnits, @matltotal bDollar, @haultype char(1), @haulvendor bVendor, @truck bTruck, 
  		@driver varchar(30), @emco bCompany, @equipment bEquip, @emgroup bGroup, @prco bCompany, 
  		@employee bEmployee, @trucktype varchar(10), @haulcode bHaulCode, @haulphase bPhase, @hauljcct bJCCType,
  		@haulbasis bUnits, @haultotal bDollar, @paycode bPayCode, @paytotal bDollar, @revcode bRevCode, 
  		@revtotal bDollar, @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @taxtotal bDollar, 
  		@discoff bDollar, @taxdisc bDollar, @void bYN, @purge bYN, @reasoncode bReasonCode, 
  		@tomatlgroup bGroup, @tomatlstdum bUM, @pphase bPhase, @msqdphase bPhase, @validphasechars int,
		@postsoftclosedjobs bYN, @valueadd varchar(1), @SurchargeKeyID BIGINT
		----TK-15962
		,@found TINYINT
		
  
  SELECT @numrows = @@rowcount
  IF @numrows = 0 return
  SET nocount on
  
  if @numrows = 1
  	select @msco = MSCo, @mth = Mth, @mstrans = MSTrans, @haultrans = HaulTrans, @saledate = SaleDate, @fromloc = FromLoc,
          @ticket = Ticket, @vendorgroup = VendorGroup, @matlvendor = MatlVendor, @saletype = SaleType, @custgroup = CustGroup,
          @customer = Customer, @custjob = CustJob, @custpo = CustPO, @paymenttype = PaymentType, @checkno = CheckNo,
          @jcco = JCCo, @job = Job, @phasegroup = PhaseGroup, @inco = INCo, @toloc = ToLoc,
          @matlgroup = MatlGroup, @material = Material, @matlum = UM, @matlphase = MatlPhase, @matljcct = MatlJCCType,
          @wghtum = WghtUM, @matlunits = MatlUnits, @matltotal = MatlTotal, @haultype = HaulerType, @haulvendor = HaulVendor,
          @truck = Truck, @driver = Driver, @emco = EMCo, @equipment = Equipment, @emgroup = EMGroup, @prco = PRCo,
          @employee = Employee, @trucktype = TruckType, @haulcode = HaulCode, @haulphase = HaulPhase, @hauljcct = HaulJCCType,
          @haulbasis = HaulBasis, @haultotal = HaulTotal, @paycode = PayCode, @paytotal = PayTotal, @revcode = RevCode,
          @revtotal = RevTotal, @taxgroup = TaxGroup, @taxcode = TaxCode, @taxtype = TaxType, @taxtotal = TaxTotal,
          @discoff = DiscOff, @taxdisc = TaxDisc, @void = Void, @purge = Purge, @reasoncode = ReasonCode,
          @SurchargeKeyID = SurchargeKeyID
      from inserted
  else
      begin
  	-- use a cursor to process each inserted row
  	declare bMSTD_insert cursor LOCAL FAST_FORWARD
  	for select MSCo, Mth, MSTrans, HaulTrans, SaleDate, FromLoc, Ticket, VendorGroup, MatlVendor, SaleType,
          CustGroup, Customer, CustJob, CustPO, PaymentType, CheckNo, JCCo, Job, PhaseGroup, INCo,
          ToLoc, MatlGroup, Material, UM, MatlPhase, MatlJCCType, WghtUM, MatlUnits, MatlTotal, HaulerType,
          HaulVendor, Truck, Driver, EMCo, Equipment, EMGroup, PRCo, Employee, TruckType, HaulCode, HaulPhase,
          HaulJCCType, HaulBasis, HaulTotal, PayCode, PayTotal, RevCode, RevTotal, TaxGroup, TaxCode, TaxType,
          TaxTotal, DiscOff, TaxDisc, Void, Purge, ReasonCode, SurchargeKeyID
  	from inserted
  
  	open bMSTD_insert
  
      fetch next from bMSTD_insert into @msco, @mth, @mstrans, @haultrans, @saledate, @fromloc, @ticket, 
  		@vendorgroup, @matlvendor, @saletype, @custgroup, @customer, @custjob, @custpo, @paymenttype, 
  		@checkno, @jcco, @job, @phasegroup, @inco, @toloc, @matlgroup, @material, @matlum, @matlphase,
  		@matljcct, @wghtum, @matlunits, @matltotal, @haultype, @haulvendor, @truck, @driver, @emco, 
  		@equipment, @emgroup, @prco, @employee, @trucktype, @haulcode, @haulphase, @hauljcct, @haulbasis, 
  		@haultotal, @paycode, @paytotal, @revcode, @revtotal, @taxgroup, @taxcode, @taxtype, @taxtotal, 
  		@discoff, @taxdisc, @void, @purge, @reasoncode, @SurchargeKeyID
  
      if @@fetch_status <> 0
  		begin
  		select @errmsg = 'Cursor error'
  		goto error
  		end
      end
  
  insert_check:
  --reset values for each row
  select @umconv = 1, @quote = null, @mssaseq = NULL
  SET @found = 0 --false
  
  --validate MS Co#
  select @msglco = GLCo from bMSCO with (nolock) where MSCo = @msco
  if @@rowcount <> 1
      begin
      select @errmsg = 'Invalid MS Co#: ' + convert(varchar(3),@msco)
      goto error
      end
  
  --validate Month
  exec @rcode = dbo.bspHQBatchMonthVal @msglco, @mth, 'MS', @errmsg output
  if @rcode = 1 goto error
  --validate Haul Trans#
  if @haultrans is not null
      begin
      if not exists(select 1 from bMSHH with (nolock) where MSCo = @msco and Mth = @mth and HaulTrans = @haultrans)
          begin
          select @errmsg = 'Invalid Haul Trans#: ' + convert(varchar(6),@haultrans)
          goto error
          end
      end
  
  --validate From Location
  if not exists(select 1 from bINLM with (nolock) where INCo = @msco and Loc = @fromloc and Active = 'Y')
      begin
      select @errmsg = 'Invalid or inactive From Location: ' + isnull(@fromloc,'')
      goto error
      end
  
  --validate Material Vendor
  if @matlvendor is not null
      begin
      if not exists(select 1 from bAPVM with (nolock) where VendorGroup = @vendorgroup and Vendor = @matlvendor and ActiveYN = 'Y')
          begin
          select @errmsg = 'Invalid or inactive material Vendor: ' + convert(varchar(6),isnull(@matlvendor,''))
          goto error
          end
      end
  
  --validate Sale Type
  if @saletype not in ('C','J','I')
      begin
      select @errmsg = 'Sale type must be C, J, or I'
      goto error
      end
  
  if @saletype = 'C'
      begin
      if not exists(select 1 from bARCM with (nolock) where CustGroup = @custgroup and Customer = @customer and Status <> 'I')
          begin
          select @errmsg = 'Invalid or inactive Customer: ' + convert(varchar(6),isnull(@customer,''))
          goto error
          end
      if @paymenttype not in ('A','C','X')
          begin
          select @errmsg = 'Payment Type must be A, C, or X'
          goto error
          end
      if (@paymenttype in ('A','X') and @checkno is not null)
          begin
          select @errmsg = 'Check number only allowed with Payment Type C'
          goto error
          end
      if @jcco is not null or @job is not null or @inco is not null or @toloc is not null
          begin
          select @errmsg = 'Cannot specify Job or Sell To Location on Customer sales'
          goto error
          end
  
   --   -- look for Customer Quote
   --   select @quote = Quote
   --   from bMSQH with (nolock)    
  	--where MSCo = @msco and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
  	--and isnull(CustJob,'') = isnull(@custjob,'') and isnull(CustPO,'') = isnull(@custpo,'')
   --   if @@rowcount = 0
   --       begin
   --       -- if no Quote at Cust PO level, check at Cust Job level
   --       select @quote = Quote
   --       from bMSQH with (nolock) 
   --       where MSCo = @msco and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
   --       and isnull(CustJob,'') = isnull(@custjob,'') and CustPO is null
   --       if @@rowcount = 0
   --           begin
   --           -- if no Quote at Cust Job level, check at Customer level
   --           select @quote = Quote
   --           from bMSQH with (nolock) 
   --           where MSCo = @msco and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
   --           and CustJob is null and CustPO is null
   --           end
  	--	end
      -- look for Sales Activity
      select @mssaseq = Seq
      from bMSSA with (nolock) 
      where MSCo = @msco and Mth = @mth and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material
      and SaleType = 'C' and CustGroup = @custgroup and Customer = @customer
      and isnull(CustJob,'') = isnull(@custjob,'') and isnull(CustPO,'') = isnull(@custpo,'')
      end
  
  
if @saletype = 'J'
	begin
  	select @postclosedjobs = j.PostClosedJobs, @validphasechars = j.ValidPhaseChars,
  		   @tomatlgroup = h.MatlGroup, @postsoftclosedjobs = j.PostSoftClosedJobs -- get 'sell to' MatlGroup
  	from bJCCO j with (nolock) join bHQCO h with (nolock) on h.HQCo = j.JCCo
  	where j.JCCo = @jcco
	if @@rowcount = 0
          begin
          select @errmsg = 'Invalid JC Co#: ' + convert(varchar(3),isnull(@jcco,''))
          goto error
          end
      select @status = JobStatus from bJCJM with (nolock) where JCCo = @jcco and Job = @job
      if @@rowcount=0
          begin
          select @errmsg = 'Invalid Job: ' + isnull(@job,'')
          goto error
          end
	if @postsoftclosedjobs = 'N' and @status = 2
		begin
		select @errmsg = 'Job: ' + isnull(@job,'') + ' is soft-closed'
		goto error
		end
  	if @postclosedjobs = 'N' and @status = 3
		begin
		select @errmsg = 'Job: ' + isnull(@job,'') + ' is hard-closed'
		goto error
		end
	if @customer is not null or @custjob is not null or @custpo is not null
          or @inco is not null or @toloc is not null
          begin
          select @errmsg = 'Cannot specify Customer or Sell To Location on Job sales'
          goto error
          end
  
  	-- set valid part material phase
  	if @validphasechars > 0
  		set @pphase = substring(@matlphase,1,@validphasechars) + '%'
  	else
  		set @pphase = @matlphase
  
      ---- look for Job Quote
      --select @quote = Quote
      --from bMSQH with (nolock) 
      --where MSCo = @msco and QuoteType = 'J' and JCCo = @jcco and Job= @job
      -- look for Sales Activity
      select @mssaseq = Seq
      from bMSSA with (nolock) 
      where MSCo = @msco and Mth = @mth and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material
      and SaleType = 'J' and JCCo = @jcco and Job = @job
      end
  
 
  if @saletype = 'I'
      begin
  	select @tomatlgroup = MatlGroup from bHQCO with (nolock) where HQCo = @inco
  	if @@rowcount = 0
          begin
          select @errmsg = 'Invalid HQ Co#: ' + convert(varchar(3),isnull(@inco,''))
          goto error
          end
      if not exists(select 1 from bINLM with (nolock) where INCo = @inco and Loc = @toloc and Active = 'Y')
          begin
          select @errmsg = 'Invalid or inactive To Location: ' + isnull(@toloc,'')
          goto error
          end
      if @inco = @msco and @toloc = @fromloc
          begin
          select @errmsg = 'Sell From and To Locations cannot be equal'
          goto error
          end
      if @customer is not null or @custjob is not null or @custpo is not null
          or @jcco is not null or @job is not null
          begin
          select @errmsg = 'Cannot specify Customer or Job type information on Inventory sales'
          goto error
          end
  
      ---- look for Inventory Quote
      --select @quote = Quote
      --from bMSQH with (nolock) 
      --where MSCo = @msco and QuoteType = 'I' and INCo = @inco and Loc = @toloc
      -- look for Sales Activity
      select @mssaseq = Seq
      from bMSSA with (nolock) 
      where MSCo = @msco and Mth = @mth and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material
      and SaleType = 'I' and INCo = @inco and ToLoc = @toloc
      end
  
  if @saletype in ('J','I') and (@paymenttype is not null or @checkno is not null)
      begin
      select @errmsg = 'Payment Type and Check # must be null for Job and Inventory sales'
      goto error
      end
  
  --validate Material
  select @stdum = StdUM from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material and Active = 'Y'
  if @@rowcount = 0
      begin
      select @errmsg = 'Invalid or inactive Material: ' + isnull(@material,'')
      goto error
      end
  
  if @matlvendor is null
      begin
      if not exists(select 1 from bINMT with (nolock) where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup
                  and Material = @material and Active = 'Y')
          begin
          
			-- ISSUE: #129350 --
			IF @SurchargeKeyID IS NULL
				BEGIN
					select @errmsg = 'Invalid or inactive Material: ' + isnull(@material,'') + ' at Location: ' + isnull(@fromloc,'')
					goto error
				END
  		end
      end
  
  if @saletype = 'I'
      begin
      if not exists(select 1 from bINMT with (nolock) where INCo = @inco and Loc = @toloc and MatlGroup = @tomatlgroup
                  and Material = @material and Active = 'Y')
          begin
          
			-- ISSUE: #129350 --
			IF @SurchargeKeyID IS NULL
				BEGIN
					select @errmsg = 'Invalid or inactive Material: ' + isnull(@material,'') + ' at Location: ' + isnull(@toloc,'')
					goto error
				END
          end
      end


if @matlum <> @stdum
	begin
  	select @umconv=Conversion from bINMU with (nolock) 
  	where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material and UM=@matlum
  	if @@rowcount = 0
  		begin
  		select @umconv=Conversion from bHQMU with (nolock)
  		where MatlGroup = @matlgroup and Material = @material and UM = @matlum
  		if @@rowcount <> 1
  	        begin
  	        select @errmsg = 'Invalid unit of measure: ' + isnull(@matlum,'')
  	        goto error
  	        end
  		end
	-- -- -- verify that material-UM exists at sell to location
	if @saletype = 'I'
		begin
		-- -- -- check if um for to location is the STD UM #120087
		select @tomatlstdum=StdUM from bHQMT with (nolock) where MatlGroup=@tomatlgroup and Material=@material
		-- -- -- when to std um <> um then must exists in bINMU
		if @tomatlstdum <> @matlum
			begin
			select @validcnt = count(*) from bINMU with (nolock)
			where INCo = @inco and Loc = @toloc and MatlGroup = @tomatlgroup and Material = @material and UM = @matlum
			if @validcnt = 0
				begin
				select @errmsg = 'Invalid unit of measure: ' + isnull(@matlum,'') + ' at Sale To Location: ' + isnull(@toloc,'')
				goto error
				end
			end
		end
	end

-- -- -- validate Material Phase and Cost Type
  if @saletype <> 'J' and (@matlphase is not null or @matljcct is not null)
      begin
      select @errmsg = 'Material Phase and Cost Type only allowed on Job Sales'
  	goto error
      end
  
  if @saletype = 'J' and (@matlunits <> 0 or @matltotal <> 0) and (@matlphase is null or @matljcct is null)
      begin
      select @errmsg = 'Missing Material Phase and/or Cost Type'
      goto error
      end
  
  if @matlphase is not null
      begin
      exec @rcode = bspJCVPHASE @jcco, @job, @matlphase, @phasegroup, 'N', @msg = @errmsg output
      if @rcode = 1
          begin
          select @errmsg = 'Material Phase: ' + isnull(@matlphase,'') + ' ' + isnull(@errmsg,'')
          goto error
          end
      end
  
  if @matljcct is not null
      begin
      select @costtype = convert(varchar(5),@matljcct)
      exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup,@matlphase, @costtype, 'N', @msg = @errmsg output
      if @rcode = 1
          begin
          select @errmsg = 'Material Cost Type: ' + isnull(@costtype,'') + ' ' + isnull(@errmsg,'')
          goto error
          end
      end
  
  --validate Weight U/M
  if @wghtum is not null
      begin
      if not exists(select 1 from bHQUM with (nolock) where UM = @wghtum)
          begin
          select @errmsg = 'Invalid Weight U/M: ' + isnull(@wghtum,'')
          goto error
          end
      end
  
  --validate Hauler Type
  if @haultype not in ('N','E','H')
      begin
      select @errmsg = 'Invalid Hauler Type - must be N, E, or H'
      goto error
      end
  
  --validate Equipment Haul
  if @haultype = 'E'
      begin
      --validate Equipment
      if not exists(select 1 from bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment and Type <> 'C' and Status = 'A')
          begin
          select @errmsg = 'Invalid or Inactive Equipment: ' + isnull(@equipment,'')
          goto error
          end
  
  
      --validate Employee
      if @employee is not null
          begin
          if not exists(select 1 from bPREH with (nolock) where PRCo = @prco and Employee = @employee)
              begin
              select @errmsg = 'Invalid Employee: ' + convert(varchar(6),isnull(@employee,''))
              goto error
              end
  		end
  
      --validate Revenue Code
      if @revtotal <> 0 and @revcode is null
          begin
          select @errmsg = 'Missing EM Revenue Code'
          goto error
          end
      if @revcode is not null
          begin
          if not exists(select 1 from bEMRC with (nolock) where EMGroup = @emgroup and RevCode = @revcode)
              begin
              select @errmsg = 'Invalid EM Revenue Code: ' + isnull(@revcode,'')
              goto error
              end
          end
  
      if @haulvendor is not null or @truck is not null or @paycode is not null or @paytotal is not null
          begin
          select @errmsg = 'Haul Vendor and Pay Code values must be null when Hauler Type is E'
          end
      end
  
  --validate Haul Vendor info (Truck not validated)
  if @haultype = 'H'
      begin
      if not exists(select 1 from bAPVM with (nolock) where VendorGroup = @vendorgroup and Vendor = @haulvendor and ActiveYN = 'Y')
          begin
  		select @errmsg = 'Invalid or inactive Haul Vendor: ' + convert(varchar(6),isnull(@haulvendor,''))
          goto error
          end
      if @paytotal <> 0 and @paycode is null
          begin
          select @errmsg = 'Missing Haul Vendor Pay Code'
          goto error
          end
      if @paycode is not null
          begin
          if not exists(select 1 from bMSPC with (nolock) where MSCo = @msco and PayCode = @paycode)
              begin
              select @errmsg = 'Invalid Haul Vendor Pay Code: ' + isnull(@paycode,'')
              goto error
              end
          end
      if @emco is not null or @equipment is not null or @employee is not null or @revcode is not null or @revtotal <> 0
          begin
          select @errmsg = 'Equipment and Revenue Code values must be null when Hauler Type is H'
          goto error
          end
      end
  
  --validate Haul Code info
  if @haultype in ('E','H')
      begin
      if @trucktype is not null
          begin
          if not exists(select 1 from bMSTT with (nolock) where MSCo = @msco and TruckType = @trucktype)
              begin
              select @errmsg = 'Invalid Truck Type: ' + isnull(@trucktype,'')
              end
          end
      if (@haulbasis <> 0 or @haultotal <> 0) and @haulcode is null
  		begin
          select @errmsg = 'Missing Haul Code'
          goto error
          end
      if @haulcode is not null
          begin
          if not exists(select 1 from bMSHC with (nolock) where MSCo = @msco and HaulCode = @haulcode)
              begin
  			select @errmsg = 'Invalid Haul Code: ' + isnull(@haulcode,'')
              goto error
              end
          end
      end
  
  --validate Haul Phase and Cost Type
  if @saletype <> 'J' and (@haulphase is not null or @hauljcct is not null)
      begin
      select @errmsg = 'Haul Phase and Cost Type only allowed on Job Sales'
      goto error
      end
  if @saletype = 'J' and (@haulbasis <> 0 or @haultotal <> 0) and (@haulphase is null or @hauljcct is null)
      begin
      select @errmsg = 'Missing Haul Phase and/or Cost Type'
      goto error
      end
  if @haulphase is not null
      begin
      exec @rcode = bspJCVPHASE @jcco, @job, @haulphase, @phasegroup, 'N', @msg = @errmsg output
      if @rcode = 1
          begin
          select @errmsg = 'Haul Phase: ' + isnull(@haulphase,'') + ' ' + isnull(@errmsg,'')
          goto error
          end
      end
  if @hauljcct is not null
      begin
      select @costtype = convert(varchar(5),@hauljcct)
      exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup,@haulphase, @costtype, 'N', @msg = @errmsg output
      if @rcode = 1
          begin
          select @errmsg = 'Haul Cost Type: ' + isnull(@costtype,'') + ' ' + isnull(@errmsg,'')
          goto error
          end
      end
  if @haultype = 'N'
      begin
      if @haulvendor is not null or @truck is not null or @driver is not null or @equipment is not null
          or @trucktype is not null or @haulcode is not null or @haultotal <> 0 or @paycode is not null
          or @paytotal <> 0 or @revcode is not null or @revtotal <> 0
          begin
          select @errmsg = 'Haul information not allowed if Hauler Type is N'
          goto error
          end
      end
  
--validate Tax info
if @taxtotal <> 0 and @taxcode is null
	begin
	select @errmsg = 'Missing Tax Code'
	goto error
	end
  
if @taxcode is not null
	begin
	select @valueadd=ValueAdd
	from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode
	if @@rowcount = 0
		begin
		select @errmsg = 'Invalid Tax Code: ' + isnull(@taxcode,'') + '.'
		goto error
		end
	-- validate tax type
	if @taxtype is null
		begin
		select @errmsg = 'Invalid tax type - no tax type assigned.'
		goto error
		end
	if @taxtype not in (1,2,3)
		begin
		select @errmsg = 'Invalid Tax Type, must be 1, 2, or 3.'
		goto error
		end
	if @taxtype = 3 and isnull(@valueadd,'N') <> 'Y'
		begin
		select @errmsg = 'Invalid Tax Code: ' + isnull(@taxcode,'') + '. Must be a value added tax code!'
		goto error
		end
	end

  
  --validate Discount
  if @saletype in ('J','I') and (@discoff <> 0 or @taxdisc <> 0)
      begin
      select @errmsg = 'Discount and Tax Discount can only be offered on Customer sales'
      goto error
      end
  --validate Purge flag
  if @purge = 'Y'
      begin
      select @errmsg = 'Purge flag must be N'
      goto error
      end
  
  --Validate Reason Code
  if not exists(select 1 from bHQRC with (nolock) where ReasonCode = @reasoncode) and @reasoncode is not null
  	begin
  	select @errmsg = 'Invalid Reason Code'
  	goto error
  	end

---- TK-16962 process new info unless void
IF @void = 'N'
   BEGIN
   EXEC @rcode = dbo.bspMSTDTrigProc @msco, @mth, @fromloc, @matlgroup, @material, @saletype,
		@custgroup, @customer, @custjob, @custpo, @jcco, @job, @inco, @toloc, @matlum,
		@matlunits, @matltotal, @haultotal, @taxtotal, @discoff, @phasegroup, @matlphase,
		@vendorgroup, @matlvendor, 'N', @errmsg output
   END
   
------update Quote Detail if material has been quoted (Inventory allocations updated via bMSQD trigger)
--IF @quote is not null and @void = 'N'   -- quote may be inactive, skip update if ticket is void
--	BEGIN
--  	-- only update MSQD if there are material units to update
--  	if @matlunits <> 0 
--  		BEGIN
--  		----TK-16962
--		SET @found = 0 --false
		
--  		-- if sale type not 'J' update with no phase
--  		if @saletype <> 'J'
--  			BEGIN
--  			----TK-16962 try update by material vendor if we have one
--			IF @matlvendor IS NOT NULL AND @vendorgroup IS NOT NULL
--				BEGIN
--				UPDATE dbo.bMSQD
--  					SET SoldUnits = SoldUnits + @matlunits,
--  						AuditYN = 'N'   -- set audit flag
--  				FROM dbo.bMSQD
--  				WHERE MSCo = @msco  -- may be any status
--  					AND Quote = @quote
--  					AND FromLoc = @fromloc
--  					AND MatlGroup = @matlgroup
--  					AND Material = @material 
--  					AND UM = @matlum
--  					AND VendorGroup = @vendorgroup
--  					AND MatlVendor = @matlvendor
--  					AND Phase IS NULL
--  				IF @@ROWCOUNT <> 0 SET @found = 1 --true
--  				END
  			
--  			---- TK-16962 try update without material vendor if not found
--  			IF @found = 0
--  				BEGIN
--  	    		UPDATE dbo.bMSQD
--  					SET SoldUnits = SoldUnits + @matlunits,
--  						AuditYN = 'N'   -- set audit flag
--  				FROM dbo.bMSQD with (ROWLOCK)  -- may be any status
--  				WHERE MSCo = @msco
--  					AND Quote = @quote
--  					AND FromLoc = @fromloc
--  					AND MatlGroup = @matlgroup
--  					AND Material = @material
--  					AND UM = @matlum
--  					AND Phase is NULL
--  					AND MatlVendor IS NULL
--  				END
  			
--  			---- teset audit flag
--  			UPDATE dbo.bMSQD SET AuditYN = 'Y'
--  		    WHERE MSCo = @msco  -- may be any status
--  				AND Quote = @quote
--  				AND FromLoc = @fromloc
--  				AND MatlGroup = @matlgroup
--  				AND Material = @material
--  				AND UM = @matlum
--  				AND Phase is null
--  			END
--  		ELSE
--  			BEGIN
--  			----TK-16962 try update by material vendor if we have one
--  			IF @matlvendor IS NOT NULL AND @vendorgroup IS NOT NULL
--  				BEGIN
--  				---- phase exact match first
--  				UPDATE dbo.bMSQD 
--				SET SoldUnits = SoldUnits + @matlunits,
--					AuditYN = 'N'   -- set audit flag
--  				FROM dbo.bMSQD  -- may be any status
--  				WHERE MSCo = @msco
--  					AND Quote = @quote
--  					AND FromLoc = @fromloc
--  					AND MatlGroup = @matlgroup
--  					AND Material = @material
--  					AND UM = @matlum 
--  					AND PhaseGroup = @phasegroup
--  					AND Phase = @matlphase
--  					AND VendorGroup = @vendorgroup
--  					AND MatlVendor = @matlvendor
--  				IF @@ROWCOUNT = 0
--  					BEGIN
--  					---- look for valid part phase second
--  					SELECT TOP 1 @msqdphase = Phase
--  					FROM dbo.bMSQD
--  					WHERE MSCo = @msco
--  						AND Quote = @quote
--  						AND FromLoc = @fromloc
--  						AND MatlGroup = @matlgroup 
--  						AND Material = @material
--  						AND UM = @matlum
--  						AND PhaseGroup = @phasegroup
--  						AND Phase like @pphase
--  						AND VendorGroup = @vendorgroup
--  						AND MatlVendor = @matlvendor
--  					GROUP BY MSCo, Quote, FromLoc, MatlGroup, Material, UM, PhaseGroup, Phase, UnitPrice, ECM, VendorGroup, MatlVendor
--  					IF @@ROWCOUNT <> 0
--  						BEGIN
--  						---- update valid part phase
--  						UPDATE dbo.bMSQD 
--  							SET SoldUnits = SoldUnits + @matlunits,
--  								AuditYN = 'N'   -- set audit flag
--  						FROM dbo.bMSQD 
--  						WHERE MSCo = @msco
--  							AND Quote = @quote
--  							AND FromLoc = @fromloc
--  							AND MatlGroup = @matlgroup
--  							AND Material = @material
--  							AND UM = @matlum
--  							AND PhaseGroup = @phasegroup
--  							AND Phase = @msqdphase
--  							AND VendorGroup = @vendorgroup
--  							AND MatlVendor = @matlvendor
--  						IF @@ROWCOUNT <> 0 SET @found = 1 --true
--  						END
--  					END
--  				ELSE
--					BEGIN
--					SET @found = 1 --true
--					END
  			
--  				---- reset audit flag
--  				IF @found = 1
--  					BEGIN
--					UPDATE dbo.bMSQD SET AuditYN = 'Y'
--					WHERE MSCo = @msco  -- may be any status
--						AND Quote = @quote
--						AND FromLoc = @fromloc
--						AND MatlGroup = @matlgroup
--						AND Material = @material
--						AND UM = @matlum
--						AND Phase IS NOT NULL
--						AND VendorGroup = @vendorgroup
--  						AND MatlVendor = @matlvendor
--					END
--  				END


--  			---- sale type 'J' look for exact match phase first
--			IF @found = 0
--				BEGIN
--  				update bMSQD 
--  				set SoldUnits = SoldUnits + @matlunits, AuditYN = 'N'   -- set audit flag
--  				from bMSQD with (rowlock)
--  				where MSCo=@msco and Quote=@quote and FromLoc=@fromloc and MatlGroup=@matlgroup
--  				and Material=@material and UM=@matlum and PhaseGroup=@phasegroup and Phase=@matlphase
--  				if @@rowcount = 0
--  					begin
--  					-- look for valid part phase second
--  					select Top 1 @msqdphase=Phase from bMSQD with (nolock) 
--  					where MSCo=@msco and Quote=@quote and FromLoc=@fromloc and MatlGroup=@matlgroup 
--  					and Material=@material and UM=@matlum and PhaseGroup=@phasegroup and Phase like @pphase
--  					group by MSCo, Quote, FromLoc, MatlGroup, Material, UM, PhaseGroup, Phase, UnitPrice, ECM
--  					if @@rowcount <> 0
--  						begin
--  						-- update valid part phase
--  						update bMSQD
--  						set SoldUnits = SoldUnits + @matlunits, AuditYN = 'N'   -- set audit flag
--  						from bMSQD with (ROWLOCK)
--  						where MSCo = @msco and Quote = @quote and FromLoc = @fromloc and MatlGroup = @matlgroup
--  						and Material = @material and UM = @matlum and PhaseGroup=@phasegroup and Phase=@msqdphase
--  						end
--  					else
--  						begin
--  						-- update with no phase
--  						update bMSQD
--  						set SoldUnits = SoldUnits + @matlunits, AuditYN = 'N'   -- set audit flag
--  						from bMSQD with (ROWLOCK)
--  						where MSCo = @msco and Quote = @quote and FromLoc = @fromloc and MatlGroup = @matlgroup
--  						and Material = @material and UM = @matlum and Phase is null -- may be any status
--  						end
--  					end
--  				update bMSQD set AuditYN = 'Y'
--  				where MSCo=@msco and Quote=@quote and FromLoc=@fromloc and MatlGroup=@matlgroup
--  				and Material=@material and UM=@matlum and PhaseGroup=@phasegroup and Phase=@matlphase
--  				END
--  			END
--  	    END
--	END
  
  
  
----update MS Sales Activity
if @mssaseq is not null and @void = 'N' -- skip if void
	begin
	update bMSSA
	set MatlUnits = MatlUnits + (@umconv * @matlunits), -- convert to std u/m
		MatlTotal = MatlTotal + @matltotal, HaulTotal = HaulTotal + @haultotal,
		TaxTotal = TaxTotal + @taxtotal, DiscOff = DiscOff + @discoff
	from bMSSA with (ROWLOCK)
	where MSCo = @msco and Mth = @mth and Loc = @fromloc and MatlGroup = @matlgroup
	and Material = @material and Seq = @mssaseq
	if @@rowcount <> 1
		begin
		select @errmsg = 'Unable to update MS Sales Activity'
		goto error
		end
	end

----add MS Sales Activity entry if needed
if @mssaseq is null and @void = 'N'     -- skip if void
	begin
	--get next Seq
	select @mssaseq = isnull(max(Seq),0) + 1
	from bMSSA with (nolock) 
	where MSCo = @msco and Mth = @mth and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material
	--add entry
	insert bMSSA(MSCo, Mth, Loc, MatlGroup, Material, Seq, SaleType, CustGroup, Customer, CustJob,
		CustPO, JCCo, Job, INCo, ToLoc, MatlUnits, MatlTotal, HaulTotal, TaxTotal, DiscOff)
	values(@msco, @mth, @fromloc, @matlgroup, @material, @mssaseq, @saletype, @custgroup, @customer, @custjob,
		@custpo, @jcco, @job, @inco, @toloc, (@umconv * @matlunits), @matltotal, @haultotal, @taxtotal, @discoff)
	end
  
  
if @numrows > 1
	begin
	fetch next from bMSTD_insert into @msco, @mth, @mstrans, @haultrans, @saledate, @fromloc, @ticket, @vendorgroup,
		  @matlvendor, @saletype, @custgroup, @customer, @custjob, @custpo, @paymenttype, @checkno, @jcco, @job, @phasegroup,
		  @inco, @toloc, @matlgroup, @material, @matlum, @matlphase, @matljcct, @wghtum, @matlunits, @matltotal, @haultype,
		  @haulvendor, @truck, @driver, @emco, @equipment, @emgroup, @prco, @employee, @trucktype, @haulcode, @haulphase,
		  @hauljcct, @haulbasis, @haultotal, @paycode, @paytotal, @revcode, @revtotal, @taxgroup, @taxcode, @taxtype,
		  @taxtotal, @discoff, @taxdisc, @void, @purge, @reasoncode
	if @@fetch_status = 0
		goto insert_check
	else
		begin
		close bMSTD_insert
		deallocate bMSTD_insert
		end
	end
  
  
  -- Audit inserts
  insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  select 'bMSTD',' Mth: ' + convert(varchar(8),i.Mth,1) + ' MSTrans: ' + convert(varchar(6),i.MSTrans),
  	i.MSCo, 'A', null, null, null, getdate(), suser_sname()
  from inserted i join bMSCO c with (nolock) on c.MSCo = i.MSCo
  where c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null)	-- audit if Ticket or Haul Trans
  
  
  return
  
  
  
  error:
      select @errmsg = @errmsg +  ' - cannot insert MS Transaction Detail!'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************************************/
CREATE trigger [dbo].[btMSTDu] on [dbo].[bMSTD] for UPDATE as
/*-----------------------------------------------------------------
* Created: GG 10/26/00
* Modified: RM 03/05/01 - Validate and Audit Reason Code
*			GG 04/12/01 - fixed error messages and HQMA updates
*           GG 07/03/01 - add hierarchal Quote search  - #13888
*           GF 07/20/01 - Changes to speed up update - HQ Audits
*           GF 10/01/01 - Using wrong CO to validate material at location in IN.
*			GG 02/13/02 - #16085 - fix cross-company material validation
*			SR 07/09/02 - 17738 pass @phasegroup to bspJCVPHASE
*			GF 09/10/02 - #18367 - Speed up invoice batch clear and post.
*			GF 01/09/02 - #19941 - More of 18367, skip validation when updating MSInv from MSIB Post
*			GF 06/10/2003 - issue #21418 - not getting UM conversion properly for MSSA update/insert
*			GF 07/23/2003 - issue #21933 - speed improvement clean up.
*			GF 12/03/2003 - issue #23147 changes for ansi nulls and isnull
*			GF 03/19/2004 - issue #24038 - changes to MSQD update for sold units using phase if type 'J'
*			GF 06/21/2005 - routine to get @umconv worked differently than in MSTD triggers. Made the same.
*			GF 02/08/2006 - issue #120087 - added check for to material group material std um <> posted um
*			GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
*			CHS 03/14/08 - issue #127082 - international addresses
*			GF 06/23/2008 - issue #128290 new tax type 3-VAT for international tax
*			JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
*			DAN SO 10/21/2009 - Issue: #129350 - Handle Surcharges
*			GF 08/07/2012 TK-16813 pass phase group and phase to MSTD trigger proc
*			GF 08/10/2012 TK-16962 pass vendor group and material vendor to MSTD trigger proc
*
*
* Validates critical column values
*
* Updates units sold to MS Quote Detail
*
* Updates MS Sales Activity

* Inserts HQ Master Audit entries for changed values if Ticket Detail flagged for auditing.
*/----------------------------------------------------------------
declare @numrows int, @errmsg varchar(255), @umconv bUnitCost, @quote varchar(10), @mssaseq int,
  		@msglco bCompany, @costtype varchar(5), @rcode int, @postclosedjobs bYN, @status tinyint, @stdum bUM,
  		@errstart varchar(20), @validcnt int

--bMSTD declares
declare @msco bCompany, @mth bMonth, @mstrans bTrans, @haultrans bTrans, @saledate bDate, @fromloc bLoc,
       	@ticket bTic, @vendorgroup bGroup, @matlvendor bVendor, @saletype char(1), @custgroup bGroup, 
  		@customer bCustomer, @custjob varchar(20), @custpo varchar(20), @paymenttype char(1), @checkno bCMRef,
  		@jcco bCompany, @job bJob, @phasegroup bGroup, @inco bCompany, @toloc bLoc, @matlgroup bGroup, 
  		@material bMatl, @matlum bUM, @matlphase bPhase, @matljcct bJCCType, @wghtum bUM, @matlunits bUnits, 
  		@matltotal bDollar, @haultype char(1), @haulvendor bVendor, @truck bTruck, @driver varchar(30), 
  		@emco bCompany, @equipment bEquip, @emgroup bGroup, @prco bCompany, @employee bEmployee, 
  		@trucktype varchar(10), @haulcode bHaulCode, @haulphase bPhase, @hauljcct bJCCType,
  		@haulbasis bUnits, @haultotal bDollar, @paycode bPayCode, @paytotal bDollar, @revcode bRevCode, 
  		@revtotal bDollar, @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @taxtotal bDollar, 
  		@discoff bDollar, @taxdisc bDollar, @void bYN, @reasoncode bReasonCode, @tomatlgroup bGroup,
		@tomatlstdum bUM, @SurchargeKeyID bigint
  
declare @oldfromloc bLoc, @oldmatlgroup bGroup, @oldmaterial bMatl, @oldsaletype char(1), @oldcustgroup bGroup, 
  		@oldcustomer bCustomer, @oldcustjob varchar(20), @oldcustpo varchar(20), @oldjcco bCompany, @oldjob bJob, 
  		@oldinco bCompany, @oldtoloc bLoc, @oldmatlum bUM, @oldmatlunits bUnits, @oldmatltotal bMatl,
  		@oldhaultotal bDollar, @oldtaxtotal bDollar, @olddiscoff bDollar, @oldvoid bYN, 
  		@oldreasoncode bReasonCode, @pphase bPhase, @msqdphase bPhase, @validphasechars int,
		@postsoftclosedjobs bYN, @valueadd varchar(1)
		----TK-16813
		,@oldphasegroup bGroup, @oldmatlphase bPhase
		----TK-16962
		,@oldvendorgroup bGroup, @oldmatlvendor bVendor
  
  
  select @numrows = @@rowcount
  if @numrows = 0 return
  set nocount on
  
   --If the only column that changed was UniqueAttachID, then skip validation.        
	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bMSTD', 'UniqueAttchID') = 1
	BEGIN 
		goto Trigger_End
	END    
   --check for primary key changes
   if update(MSCo)
       begin
       select @errmsg = 'Cannot change MS Co#'
       goto error
       end
   if update(Mth)
       begin
       select @errmsg = 'Cannot change Month'
       goto error
       end
   if update(MSTrans)
       begin
       select @errmsg = 'Cannot change MS Trans#'
       goto error
       end
   if update(HaulTrans)
       begin
       select @errmsg = 'Cannot change Haul Trans#'
       goto error
       end
  
  
  /*
  -- check if batch for rows is MSIB and setting InUseBatchId is null. When this
  -- condition is true, then bypass validation and auditing in the update trigger.
  select @validcnt = count(*) from inserted i
  join deleted d on d.MSCo=i.MSCo and d.Mth=i.Mth and d.MSTrans=i.MSTrans
  join bHQBC a with (nolock) on a.Co=d.MSCo and a.Mth=d.Mth and a.BatchId=d.InUseBatchId
  where a.TableName='MSIB' and i.InUseBatchId is null
  if @validcnt = @numrows goto Trigger_End
  
  
  -- check if batch for rows is MSIB and setting MSInv and AuditYN columns.
  -- When this condition is true, then bypass validation and auditing in the update trigger.
  select @validcnt = count(*) from inserted i 
  join deleted d on d.MSCo=i.MSCo and d.Mth=i.Mth and d.MSTrans=i.MSTrans
  join bHQBC a with (nolock) on a.Co=d.MSCo and a.Mth=d.Mth and a.BatchId=d.InUseBatchId
  where a.TableName='MSIB' and i.MSInv is not null and i.AuditYN = 'N'
  if @validcnt = @numrows goto Trigger_End
  */
  
  
  -- added update check so that validation will be by-passed if only updating user memos
  if update(SaleDate) or update(FromLoc) or update(Ticket) or update(VendorGroup) or update(MatlVendor)
  	or update(SaleType) or update(CustGroup) or update(Customer) or update(CustJob) or update(CustPO)
  	or update(PaymentType) or update(CheckNo) or update(JCCo) or update(Job) or update(PhaseGroup)
  	or update(INCo) or update(ToLoc) or update(MatlGroup) or update(Material) or update(UM)
  	or update(MatlPhase) or update(MatlJCCType) or update(WghtUM) or update(MatlUnits) or update(MatlTotal)
  	or update(HaulerType) or update(HaulVendor) or update(Truck) or update(Driver) or update(EMCo)
  	or update(Equipment) or update(EMGroup) or update(PRCo) or update(Employee) or update(TruckType)
  	or update(HaulCode) or update(HaulPhase) or update(HaulJCCType) or update(HaulBasis) or update(HaulTotal)
  	or update(PayCode) or update(PayTotal) or update(RevCode) or update(RevTotal) or update(TaxGroup)
  	or update(TaxCode) or update(TaxType) or update(TaxTotal) or update(DiscOff) or update(TaxDisc)
  	or update(Void) or update(ReasonCode) 
  	
  	goto Begin_Process
  else
  	goto Audit_Check
  
  
  Begin_Process: -- begin process
  if @numrows = 1
   	select @msco = MSCo, @mth = Mth, @mstrans = MSTrans, @haultrans = HaulTrans, @saledate = SaleDate, @fromloc = FromLoc,
           @ticket = Ticket, @vendorgroup = VendorGroup, @matlvendor = MatlVendor, @saletype = SaleType, @custgroup = CustGroup,
           @customer = Customer, @custjob = CustJob, @custpo = CustPO, @paymenttype = PaymentType, @checkno = CheckNo,
           @jcco = JCCo, @job = Job, @phasegroup = PhaseGroup, @inco = INCo, @toloc = ToLoc,
           @matlgroup = MatlGroup, @material = Material, @matlum = UM, @matlphase = MatlPhase, @matljcct = MatlJCCType,
           @wghtum = WghtUM, @matlunits = MatlUnits, @matltotal = MatlTotal, @haultype = HaulerType, @haulvendor = HaulVendor,
           @truck = Truck, @driver = Driver, @emco = EMCo, @equipment = Equipment, @emgroup = EMGroup, @prco = PRCo,
           @employee = Employee, @trucktype = TruckType, @haulcode = HaulCode, @haulphase = HaulPhase, @hauljcct = HaulJCCType,
           @haulbasis = HaulBasis, @haultotal = HaulTotal, @paycode = PayCode, @paytotal = PayTotal, @revcode = RevCode,
           @revtotal = RevTotal, @taxgroup = TaxGroup, @taxcode = TaxCode, @taxtype = TaxType, @taxtotal = TaxTotal,
           @discoff = DiscOff, @taxdisc = TaxDisc, @void = Void,@reasoncode = ReasonCode, @SurchargeKeyID = SurchargeKeyID
       from inserted
  else
      begin
   	-- use a cursor to process each updated row
   	declare bMSTD_update cursor LOCAL FAST_FORWARD
  	for select MSCo, Mth, MSTrans, HaulTrans, SaleDate, FromLoc, Ticket, VendorGroup, MatlVendor, SaleType,
           CustGroup, Customer, CustJob, CustPO, PaymentType, CheckNo, JCCo, Job, PhaseGroup, INCo,
           ToLoc, MatlGroup, Material, UM, MatlPhase, MatlJCCType, WghtUM, MatlUnits, MatlTotal, HaulerType,
           HaulVendor, Truck, Driver, EMCo, Equipment, EMGroup, PRCo, Employee, TruckType, HaulCode, HaulPhase,
           HaulJCCType, HaulBasis, HaulTotal, PayCode, PayTotal, RevCode, RevTotal, TaxGroup, TaxCode, TaxType,
           TaxTotal, DiscOff, TaxDisc, Void, ReasonCode, SurchargeKeyID 
  	from inserted
  
   	open bMSTD_update
  
  	fetch next from bMSTD_update into @msco, @mth, @mstrans, @haultrans, @saledate, @fromloc, @ticket, @vendorgroup,
           @matlvendor, @saletype, @custgroup, @customer, @custjob, @custpo, @paymenttype, @checkno, @jcco, @job, @phasegroup,
           @inco, @toloc, @matlgroup, @material, @matlum, @matlphase, @matljcct, @wghtum, @matlunits, @matltotal, @haultype,
           @haulvendor, @truck, @driver, @emco, @equipment, @emgroup, @prco, @employee, @trucktype, @haulcode, @haulphase,
           @hauljcct, @haulbasis, @haultotal, @paycode, @paytotal, @revcode, @revtotal, @taxgroup, @taxcode, @taxtype,
           @taxtotal, @discoff, @taxdisc, @void, @reasoncode, @SurchargeKeyID
  
  	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
  
   update_check:
   --reset values for each row
   select @umconv = 1, @quote = null, @mssaseq = null, @errstart = 'MS Trans#: ' + convert(varchar(8),@mstrans)
  
   --validate From Location
   if update(FromLoc)
       begin
       if not exists(select top 1 1 from bINLM with (nolock) where INCo = @msco and Loc = @fromloc and Active = 'Y')
           begin
           select @errmsg = @errstart + ' - Invalid or inactive From Location: ' + isnull(@fromloc,'')
           goto error
           end
       end
  
   --validate Material Vendor
   if update(VendorGroup) or update(MatlVendor)
       begin
       if @matlvendor is not null
           begin
           if not exists(select top 1 1 from bAPVM with (nolock) where VendorGroup = @vendorgroup and Vendor = @matlvendor and ActiveYN = 'Y')
               begin
               select @errmsg = @errstart + ' - Invalid or inactive material Vendor: ' + convert(varchar(6),isnull(@matlvendor,''))
               goto error
               end
           end
       end
  
   --validate Sale Type
   if update(SaleType)
       begin
       if @saletype not in ('C','J','I')
           begin
           select @errmsg = @errstart + ' - Sale type must be C, J, or I'
           goto error
           end
       end
  
   if @saletype = 'C'
       begin
       if not exists(select top 1 1 from bARCM with (nolock) where CustGroup = @custgroup and Customer = @customer and Status <> 'I')
           begin
           select @errmsg = @errstart + ' - Invalid or inactive Customer: ' + convert(varchar(6),isnull(@customer,''))
           goto error
           end
       if @paymenttype not in ('A','C','X')
           begin
           select @errmsg = @errstart + ' - Payment Type must be A, C, or X'
           goto error
           end
       if (@paymenttype in ('A','X') and @checkno is not null)
           begin
           select @errmsg = @errstart + ' - Check number only allowed with Payment Type C'
           goto error
           end
       if @jcco is not null or @job is not null or @inco is not null or @toloc is not null
           begin
           select @errmsg = @errstart + ' - Cannot specify Job or Sell To Location on Customer sales'
           goto error
           end
       ---- look for Customer Quote
       --select @quote = Quote
       --from bMSQH with (nolock) 
       --where MSCo = @msco and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
       --and isnull(CustJob,'') = isnull(@custjob,'') and isnull(CustPO,'') = isnull(@custpo,'')
       --if @@rowcount = 0
       --   begin
       --   -- if no Quote at Cust PO level, check at Cust Job level
       --   select @quote = Quote
       --   from bMSQH with (nolock) 
       --   where MSCo = @msco and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
       --   and isnull(CustJob,'') = isnull(@custjob,'') and CustPO is null
       --   if @@rowcount = 0
       --       begin
       --       -- if no Quote at Cust Job level, check at Customer level
       --       select @quote = Quote
       --       from bMSQH with (nolock) 
       --       where MSCo = @msco and QuoteType = 'C' and CustGroup = @custgroup and Customer = @customer
       --       and CustJob is null and CustPO is null
       --       end
       --   end 
       -- look for Sales Activity
       select @mssaseq = Seq
       from bMSSA with (nolock) 
       where MSCo = @msco and Mth = @mth and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material
       and SaleType = 'C' and CustGroup = @custgroup and Customer = @customer
       and isnull(CustJob,'') = isnull(@custjob,'') and isnull(CustPO,'') = isnull(@custpo,'')
       end
  
if @saletype = 'J'
  	begin
  	select @postclosedjobs = j.PostClosedJobs, @validphasechars = j.ValidPhaseChars,
  		   @tomatlgroup = h.MatlGroup, @postsoftclosedjobs = j.PostSoftClosedJobs -- get 'sell to' MatlGroup
  	from bJCCO j with (nolock) join bHQCO h with (nolock) on h.HQCo = j.JCCo
  	where j.JCCo = @jcco
	if @@rowcount = 0
          begin
          select @errmsg = @errstart + ' - Invalid JC Co#: ' + convert(varchar(3),isnull(@jcco,''))
          goto error
          end
	select @status = JobStatus from bJCJM with (nolock) where JCCo = @jcco and Job = @job
	if @@rowcount=0
           begin
           select @errmsg = @errstart + ' - Invalid Job: ' + isnull(@job,'')
           goto error
           end
	if @postsoftclosedjobs = 'N' and @status = 2
           begin
           select @errmsg = @errstart + ' - Job: ' + @job + ' is soft-closed'
           goto error
           end
	if @postclosedjobs = 'N' and @status = 3
           begin
           select @errmsg = @errstart + ' - Job: ' + @job + ' is hard-closed'
           goto error
           end
	if @customer is not null or @custjob is not null or @custpo is not null
           or @inco is not null or @toloc is not null
           begin
           select @errmsg = @errstart + ' - Cannot specify Customer or Sell To Location on Job sales'
           goto error
           end
  
  	-- set valid part material phase
  	if @validphasechars > 0
  		set @pphase = substring(@matlphase,1,@validphasechars) + '%'
  	else
  		set @pphase = @matlphase
  
       ---- look for Job Quote
       --select @quote = Quote
       --from bMSQH with (nolock) 
       --where MSCo = @msco and QuoteType = 'J' and JCCo = @jcco and Job = @job
       -- look for Sales Activity
       select @mssaseq = Seq
       from bMSSA with (nolock) 
       where MSCo = @msco and Mth = @mth and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material
       and SaleType = 'J' and JCCo = @jcco and Job = @job
       end
  
   if @saletype = 'I'
      begin
  	select @tomatlgroup = MatlGroup from bHQCO with (nolock) where HQCo = @inco
  	if @@rowcount = 0
           begin
           select @errmsg = @errstart + ' - Invalid HQ Co#: ' + convert(varchar(3),isnull(@inco,''))
           goto error
           end
       if not exists(select top 1 1 from bINLM with (nolock) where INCo = @inco and Loc = @toloc and Active = 'Y')
           begin
           select @errmsg = @errstart + ' - Invalid or inactive To Location: ' + isnull(@toloc,'')
           goto error
           end
       if @inco = @msco and @toloc = @fromloc
           begin
           select @errmsg = @errstart + ' - Sell From and To Locations cannot be equal'
           goto error
           end
       if @customer is not null or @custjob is not null or @custpo is not null
           or @jcco is not null or @job is not null
           begin
           select @errmsg = @errstart + ' - Cannot specify Customer or Sell To Location on Inventory sales'
           goto error
           end
       ---- look for Inventory Quote
       --select @quote = Quote
       --from bMSQH with (nolock) 
       --where MSCo = @msco and QuoteType = 'I' and INCo = @inco and Loc = @toloc
       -- look for Sales Activity
       select @mssaseq = Seq
       from bMSSA with (nolock) 
       where MSCo = @msco and Mth = @mth and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material
       and SaleType = 'I' and INCo = @inco and ToLoc = @toloc
       end
  
   if @saletype in ('J','I') and (@paymenttype is not null or @checkno is not null)
       begin
       select @errmsg = @errstart + ' - Payment Type and Check # must be must null for Job and Inventory sales'
       goto error
       end
  
   --validate Material
   select @stdum = StdUM from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material and Active = 'Y'
   if @@rowcount = 0
       begin
       select @errmsg = @errstart + ' - Invalid or inactive Material: ' + isnull(@material,'')
       goto error
  	 end
   if @matlvendor is null
       begin
       if not exists(select top 1 1 from bINMT with (nolock) where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup
                   and Material = @material and Active = 'Y')
           begin
           
           		-- ISSUE: #129350 --
				IF @SurchargeKeyID IS NULL
					BEGIN
						select @errmsg = @errstart + ' - Invalid or inactive Material: ' + isnull(@material,'') + ' at Location: ' + isnull(@fromloc,'')
						goto error
					END
           end
       end
  
  
   if @saletype = 'I'
       begin
       if not exists(select top 1 1 from bINMT with (nolock) where INCo = @inco and Loc = @toloc and MatlGroup = @tomatlgroup
                   and Material = @material and Active = 'Y')
           begin
           		-- ISSUE: #129350 --
				IF @SurchargeKeyID IS NULL
					BEGIN
						select @errmsg = @errstart + ' - Invalid or inactive Material: ' + isnull(@material,'') + ' at Location: ' + isnull(@toloc,'')
						goto error
					END
           end
       end

	if @matlum <> @stdum
		begin
		select @umconv=Conversion from bINMU with (nolock) 
		where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material and UM=@matlum
		if @@rowcount = 0
	  		begin
	  		select @umconv=Conversion from bHQMU with (nolock)
	  		where MatlGroup = @matlgroup and Material = @material and UM = @matlum
	  		if @@rowcount <> 1
	  	        begin
	  	        select @errmsg = @errstart + ' - Invalid unit of measure: ' + isnull(@matlum,'') + ' for Material: ' + isnull(@material,'')
	  	        goto error
	  	        end
  			end

		-- -- -- verify that material-UM exists at sell to location
		if @saletype = 'I'
			begin
			-- -- -- check if um for to location is the STD UM
			select @tomatlstdum=StdUM from bHQMT with (nolock) where MatlGroup=@tomatlgroup and Material=@material
			-- -- -- when to std um <> um then must exists in bINMU
			if @tomatlstdum <> @matlum
				begin
				select @validcnt = count(*) from bINMU with (nolock)
				where INCo = @inco and Loc = @toloc and MatlGroup = @tomatlgroup and Material = @material and UM = @matlum
				if @validcnt = 0
					begin
				select @errmsg = @errstart + ' - Invalid unit of measure: ' + isnull(@matlum,'') + ' at Sale To Location: ' + isnull(@toloc,'') + ' for Material: ' + isnull(@material,'')
					goto error
					end
				end
			end
		end
  
  
  
  
   --validate Material Phase and Cost Type
   if @saletype <> 'J' and (@matlphase is not null or @matljcct is not null)
       begin
       select @errmsg = @errstart + ' - Material Phase and Cost Type only allowed on Job Sales'
       goto error
       end
   if @saletype = 'J' and (@matlunits <> 0 or @matltotal <> 0) and (@matlphase is null or @matljcct is null)
       begin
       select @errmsg = @errstart + ' - Missing Material Phase and/or Cost Type'
       goto error
       end
   if @matlphase is not null
       begin
       exec @rcode = bspJCVPHASE @jcco, @job, @matlphase, @phasegroup, 'N', @msg = @errmsg output
       if @rcode = 1
           begin
           select @errmsg = @errstart + ' - Material Phase: ' + isnull(@matlphase,'') + ' ' + isnull(@errmsg,'')
           goto error
           end
       end
   if @matljcct is not null
       begin
       select @costtype = convert(varchar(5),@matljcct)
       exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup,@matlphase, @costtype, 'N', @msg = @errmsg output
       if @rcode = 1
           begin
           select @errmsg = @errstart + ' - Material Cost Type: ' + isnull(@costtype,'') + ' ' + isnull(@errmsg,'')
           goto error
           end
       end
   --validate Weight U/M
   if update(WghtUM)
       begin
       if @wghtum is not null
           begin
           if not exists(select top 1 1 from bHQUM with (nolock) where UM = @wghtum)
               begin
               select @errmsg = @errstart + ' - Invalid Weight U/M: ' + isnull(@wghtum,'')
               goto error
               end
           end
       end
   --validate Hauler Type
   if update(HaulerType)
       begin
       if @haultype not in ('N','E','H')
           begin
           select @errmsg = @errstart + ' - Invalid Hauler Type - must be N, E, or H'
           goto error
           end
       end
  
   --validate Equipment Haul
   if @haultype = 'E'
       begin
       --validate Equipment
       if not exists(select top 1 1 from bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment and Type <> 'C' and Status = 'A')
           begin
           select @errmsg = @errstart + ' - Invalid or inactive Equipment: ' + isnull(@equipment,'')
           goto error
           end
       --validate Employee
       if @employee is not null
           begin
           if not exists(select top 1 1 from bPREH with (nolock) where PRCo = @prco and Employee = @employee)
               begin
               select @errmsg = @errstart + ' - Invalid Employee: ' + convert(varchar(6),isnull(@employee,''))
               goto error
               end
           end
       --validate Revenue Code
       if @revtotal <> 0 and @revcode is null
           begin
        	 select @errmsg = @errstart + ' - Missing EM Revenue Code'
           goto error
           end
       if @revcode is not null
          begin
           if not exists(select top 1 1 from bEMRC with (nolock) where EMGroup = @emgroup and RevCode = @revcode)
               begin
               select @errmsg = @errstart + ' - Invalid EM Revenue Code: ' + isnull(@revcode,'')
               goto error
               end
           end
       if @haulvendor is not null or @truck is not null or @paycode is not null or @paytotal is not null
           begin
           select @errmsg = @errstart + ' - Haul Vendor and Pay Code values must be null when Hauler Type is E'
           end
       end
  
   --validate Haul Vendor info (Truck not validated)
   if @haultype = 'H'
       begin
       if not exists(select top 1 1 from bAPVM with (nolock) where VendorGroup = @vendorgroup and Vendor = @haulvendor and ActiveYN = 'Y')
           begin
           select @errmsg = @errstart + ' - Invalid or inactive Haul Vendor: ' + convert(varchar(6),isnull(@haulvendor,''))
           goto error
           end
       if @paytotal <> 0 and @paycode is null
           begin
           select @errmsg = @errstart + ' - Missing Haul Vendor Pay Code'
     		 goto error
           end
       if @paycode is not null
           begin
           if not exists(select top 1 1 from bMSPC with (nolock) where MSCo = @msco and PayCode = @paycode)
               begin
               select @errmsg = @errstart + ' - Invalid Haul Vendor Pay Code: ' + isnull(@paycode,'')
               goto error
               end
           end
       if @emco is not null or @equipment is not null or @employee is not null or @revcode is not null or @revtotal <> 0
           begin
           select @errmsg = @errstart + ' - Equipment and Revenue Code values must be null when Hauler Type is H'
           goto error
           end
       end
  
   --validate Haul Code info
   if @haultype in ('E','H')
       begin
       if @trucktype is not null
           begin
           if not exists(select top 1 1 from bMSTT with (nolock) where MSCo = @msco and TruckType = @trucktype)
               begin
               select @errmsg = @errstart + ' - Invalid Truck Type: ' + isnull(@trucktype,'')
  			 goto error
    			 end
           end
       if (@haulbasis <> 0 or @haultotal <> 0) and @haulcode is null
           begin
           select @errmsg = @errstart + ' - Missing Haul Code'
           goto error
           end
       if @haulcode is not null
           begin
           if not exists(select top 1 1 from bMSHC with (nolock) where MSCo = @msco and HaulCode = @haulcode)
               begin
               select @errmsg = @errstart + ' - Invalid Haul Code: ' + isnull(@haulcode,'')
               goto error
               end
           end
       end
  
   --validate Haul Phase and Cost Type
   if @saletype <> 'J' and (@haulphase is not null or @hauljcct is not null)
       begin
       select @errmsg = @errstart + ' - Haul Phase and Cost Type only allowed on Job Sales'
       goto error
       end
   if @saletype = 'J' and (@haulbasis <> 0 or @haultotal <> 0) and (@haulphase is null or @hauljcct is null)
       begin
       select @errmsg = @errstart + ' - Missing Haul Phase and/or Cost Type'
       goto error
       end
   if @haulphase is not null
       begin
       exec @rcode = bspJCVPHASE @jcco, @job, @haulphase,@phasegroup, 'N', @msg = @errmsg output
       if @rcode = 1
           begin
           select @errmsg = @errstart + ' - Haul Phase: ' + isnull(@haulphase,'') + ' ' + isnull(@errmsg,'')
           goto error
           end
       end
   if @hauljcct is not null
       begin
       select @costtype = convert(varchar(5),@hauljcct)
exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup,@haulphase, @costtype, 'N', @msg = @errmsg output
       if @rcode = 1
           begin
           select @errmsg = @errstart + ' - Haul Cost Type: ' + isnull(@costtype,'') + ' ' + isnull(@errmsg,'')
           goto error
           end
       end
   if @haultype = 'N'
       begin
       if @haulvendor is not null or @truck is not null or @driver is not null or @equipment is not null
           or @trucktype is not null or @haulcode is not null or @haultotal <> 0 or @paycode is not null
           or @paytotal <> 0 or @revcode is not null or @revtotal <> 0
           begin
           select @errmsg = @errstart + ' - Haul information not allowed if Hauler Type is N'
           goto error
           end
       end
  
--validate Tax info
if @taxtotal <> 0 and @taxcode is null
	begin
	select @errmsg = @errstart + ' - Missing Tax Code'
	goto error
	end

if @taxcode is not null
	begin
	select @valueadd=ValueAdd
	from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode
	if @@rowcount = 0
		begin
		select @errmsg = 'Invalid Tax Code: ' + isnull(@taxcode,'') + '.'
		goto error
		end
	-- validate tax type
	if @taxtype is null
		begin
		select @errmsg = 'Invalid tax type - no tax type assigned.'
		goto error
		end
	if @taxtype not in (1,2,3)
		begin
		select @errmsg = 'Invalid Tax Type, must be 1, 2, or 3.'
		goto error
		end
	if @taxtype = 3 and isnull(@valueadd,'N') <> 'Y'
		begin
		select @errmsg = 'Invalid Tax Code: ' + isnull(@taxcode,'') + '. Must be a value added tax code!'
		goto error
		end
	end

   --validate Discount
   if @saletype in ('J','I') and (@discoff <> 0 or @taxdisc <> 0)
       begin
       select @errmsg = @errstart + ' - Discount and tax discount can only be offered on Customer sales'
  	 goto error
       end
  
  --Validate Reason Code
  if not exists(select top 1 1 from bHQRC with (nolock) where ReasonCode = @reasoncode) and @reasoncode is not null
  	begin
  	select @errmsg = @errstart + ' - Invalid Reason Code'
  	goto error
  	end
  
---- TK-16962 process new info unless void
IF @void = 'N'
   BEGIN
   EXEC @rcode = dbo.bspMSTDTrigProc @msco, @mth, @fromloc, @matlgroup, @material, @saletype,
		@custgroup, @customer, @custjob, @custpo, @jcco, @job, @inco, @toloc, @matlum,
		@matlunits, @matltotal, @haultotal, @taxtotal, @discoff, @phasegroup, @matlphase,
		@vendorgroup, @matlvendor, 'N', @errmsg output
   END
   
--update MS Sales Activity
if @mssaseq is not null and @void = 'N' -- skip if void
   begin
   update bMSSA
   set MatlUnits = MatlUnits + (@umconv * @matlunits), -- convert to std u/m
       MatlTotal = MatlTotal + @matltotal, HaulTotal = HaulTotal + @haultotal,
       TaxTotal = TaxTotal + @taxtotal, DiscOff = DiscOff + @discoff
 from bMSSA with (ROWLOCK)
   where MSCo = @msco and Mth = @mth and Loc = @fromloc and MatlGroup = @matlgroup
   and Material = @material and Seq = @mssaseq
 if @@rowcount <> 1
       begin
       select @errmsg = 'Unable to update MS Sales Activity'
       goto error
       end
   end

--add MS Sales Activity entry if needed
if @mssaseq is null and @void = 'N'     -- skip if void
   begin
   --get next Seq
   select @mssaseq = isnull(max(Seq),0) + 1
   from bMSSA with (nolock) 
   where MSCo = @msco and Mth = @mth and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material
   --add entry
   insert bMSSA(MSCo, Mth, Loc, MatlGroup, Material, Seq, SaleType, CustGroup, Customer, CustJob,
       CustPO, JCCo, Job, INCo, ToLoc, MatlUnits, MatlTotal, HaulTotal, TaxTotal, DiscOff)
   values(@msco, @mth, @fromloc, @matlgroup, @material, @mssaseq, @saletype, @custgroup, @customer, @custjob,
       @custpo, @jcco, @job, @inco, @toloc, (@umconv * @matlunits), @matltotal, @haultotal, @taxtotal, @discoff)
   end
  
--get 'old' info needed to update Quote Detail and Sales Activity
select @oldfromloc = FromLoc, @oldmatlgroup = MatlGroup, @oldmaterial = Material, @oldsaletype = SaleType,
   @oldcustgroup = CustGroup, @oldcustomer = Customer, @oldcustjob = CustJob, @oldcustpo = CustPO, @oldjcco = JCCo,
   @oldjob = Job, @oldinco = INCo, @oldtoloc = ToLoc, @oldmatlum = UM, @oldmatlunits = MatlUnits, @oldmatltotal = MatlTotal,
   @oldhaultotal = HaulTotal, @oldtaxtotal = TaxTotal, @olddiscoff = DiscOff, @oldvoid = Void
   ----TK-16813
   ,@oldphasegroup = PhaseGroup, @oldmatlphase = MatlPhase
   ----TK-16962
   ,@oldvendorgroup = VendorGroup, @oldmatlvendor = MatlVendor	
from deleted
where MSCo = @msco and Mth = @mth and MSTrans = @mstrans
if @@rowcount <> 1
   begin
   select @errmsg = 'Unable to get old values from MS Ticket Detail'
   goto error
   END
   
--process old info unless void
if @oldvoid = 'N'
	BEGIN
	exec @rcode = dbo.bspMSTDTrigProc @msco, @mth, @oldfromloc, @oldmatlgroup, @oldmaterial, @oldsaletype,
       @oldcustgroup, @oldcustomer, @oldcustjob, @oldcustpo, @oldjcco, @oldjob, @oldinco, @oldtoloc, @oldmatlum,
       @oldmatlunits, @oldmatltotal, @oldhaultotal, @oldtaxtotal, @olddiscoff
       ----TK-16813
       ,@oldphasegroup, @oldmatlphase
       ----TK-16962
       ,@oldvendorgroup, @oldmatlvendor, 'O'
       ,@errmsg output
	if @rcode = 1 goto error
	end
  
  
   -- finished with validation and updates (except HQ Audit)
   Valid_Finished:
   if @numrows > 1
   	begin
   	fetch next from bMSTD_update into @msco, @mth, @mstrans, @haultrans, @saledate, @fromloc, @ticket, @vendorgroup,
           @matlvendor, @saletype, @custgroup, @customer, @custjob, @custpo, @paymenttype, @checkno, @jcco, @job, @phasegroup,
           @inco, @toloc, @matlgroup, @material, @matlum, @matlphase, @matljcct, @wghtum, @matlunits, @matltotal, @haultype,
  
           @haulvendor, @truck, @driver, @emco, @equipment, @emgroup, @prco, @employee, @trucktype, @haulcode, @haulphase,
           @hauljcct, @haulbasis, @haultotal, @paycode, @paytotal, @revcode, @revtotal, @taxgroup, @taxcode, @taxtype,
           @taxtotal, @discoff, @taxdisc, @void, @reasoncode, @SurchargeKeyID
   	if @@fetch_status = 0
   		goto update_check
   	else
   		begin
   		close bMSTD_update
   		deallocate bMSTD_update
   		end
   	end
  
  
  Audit_Check:
  -- Insert records into HQMA for changes made to audited fields
  if not exists(select top 1 1 from inserted i join bMSCO c with (nolock) on i.MSCo=c.MSCo
  					where i.AuditYN='Y' and (c.AuditTics='Y' and c.AuditHaulers='Y'))
  	goto Trigger_End
  else
  --if exists(select * from inserted i join bMSCO c on i.MSCo=c.MSCo where i.AuditYN='Y' and (c.AuditTics='Y' or c.AuditHaulers='Y'))
  BEGIN
      if Update(SaleDate)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'SaleDate', convert(char(8),d.SaleDate,1), convert(char(8),i.SaleDate,1), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.SaleDate,'') <> isnull(i.SaleDate,'')
  		and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      IF Update(Ticket)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Ticket', d.Ticket, i.Ticket, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.Ticket,'') <> isnull(i.Ticket,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(FromLoc)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'FromLoc', d.FromLoc, i.FromLoc, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.FromLoc,'') <> isnull(i.FromLoc,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(MatlVendor)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'MatlVendor', convert(varchar(6),d.MatlVendor), convert(varchar(6),i.MatlVendor), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.MatlVendor,'') <> isnull(i.MatlVendor,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(SaleType)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'SaleType', d.SaleType, i.SaleType, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.SaleType,'') <> isnull(i.SaleType,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(Customer)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
       	i.MSCo, 'C', 'Customer', convert(varchar(6),d.Customer), convert(varchar(6),i.Customer), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.Customer,'') <> isnull(i.Customer,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(CustJob)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
          i.MSCo, 'C', 'CustJob', d.CustJob, i.CustJob, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.CustJob,'') <> isnull(i.CustJob,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(CustPO)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
          i.MSCo, 'C', 'CustPO', d.CustPO, i.CustPO, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.CustPO,'') <> isnull(i.CustPO,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(PaymentType)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'PaymentType', d.PaymentType, i.PaymentType, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.PaymentType,'') <> isnull(i.PaymentType,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(CheckNo)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'CheckNo', d.CheckNo, i.CheckNo, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.CheckNo,'') <> isnull(i.CheckNo,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(Hold)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Hold', d.Hold, i.Hold, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.Hold,'') <> isnull(i.Hold,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(JCCo)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'JCCo', convert(varchar(3),d.JCCo), convert(varchar(3),i.JCCo), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.JCCo,'') <> isnull(i.JCCo,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(Job)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Job', d.Job, i.Job, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.Job,'') <> isnull(i.Job,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(INCo)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'INCo', convert(varchar(3),d.INCo), convert(varchar(3),i.INCo), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.INCo,'') <> isnull(i.INCo,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(ToLoc)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'ToLoc', d.ToLoc, i.ToLoc, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.ToLoc,'') <> isnull(i.ToLoc,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(Material)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Material', d.Material, i.Material, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.Material,'') <> isnull(i.Material,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(UM)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'UM', d.UM, i.UM, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.UM,'') <> isnull(i.UM,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(MatlPhase)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'MatlPhase', d.MatlPhase, i.MatlPhase, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
       where isnull(d.MatlPhase,'') <> isnull(i.MatlPhase,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(MatlJCCType)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'MatlJCCType', convert(varchar(3),d.MatlJCCType), convert(varchar(3),i.MatlJCCType), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.MatlJCCType,'') <> isnull(i.MatlJCCType,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(GrossWght)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'GrossWght', convert(varchar(15),d.GrossWght), convert(varchar(15),i.GrossWght), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.GrossWght <> i.GrossWght and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(TareWght)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'TareWght', convert(varchar(15),d.TareWght), convert(varchar(15),i.TareWght), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.TareWght <> i.TareWght and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(WghtUM)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'WghtUM', d.WghtUM, i.WghtUM, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.WghtUM,'') <> isnull(i.WghtUM,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(MatlUnits)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'MatlUnits', convert(varchar(15),d.MatlUnits), convert(varchar(15),i.MatlUnits), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.MatlUnits <> i.MatlUnits and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(UnitPrice)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'UnitPrice', convert(varchar(15),d.UnitPrice), convert(varchar(15),i.UnitPrice), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.UnitPrice <> i.UnitPrice and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(ECM)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'ECM', d.ECM, i.ECM, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.ECM,'') <> isnull(i.ECM,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(MatlTotal)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'MatlTotal', convert(varchar(16),d.MatlTotal), convert(varchar(16),i.MatlTotal), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.MatlTotal <> i.MatlTotal and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(HaulerType)
  
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'HaulerType', d.HaulerType, i.HaulerType, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.HaulerType <> i.HaulerType and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(HaulVendor)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'HaulVendor', convert(varchar(6),d.HaulVendor), convert(varchar(6),i.HaulVendor), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.HaulVendor,'') <> isnull(i.HaulVendor,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(Truck)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Truck', d.Truck, i.Truck, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.Truck,'') <> isnull(i.Truck,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(Driver)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Driver', d.Driver, i.Driver, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.Driver,'') <> isnull(i.Driver,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(EMCo)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'EMCo', convert(varchar(3),d.EMCo), convert(varchar(3),i.EMCo), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.EMCo,'') <> isnull(i.EMCo,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(Equipment)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Equipment', d.Equipment, i.Equipment, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.Equipment,'') <> isnull(i.Equipment,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(PRCo)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'PRCo', convert(varchar(3),d.PRCo), convert(varchar(3),i.PRCo), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.PRCo,'') <> isnull(i.PRCo,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(Employee)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Employee', convert(varchar(6),d.Employee), convert(varchar(6),i.Employee), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.Employee,'') <> isnull(i.Employee,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(TruckType)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
      		i.MSCo, 'C', 'TruckType', d.TruckType, i.TruckType, getdate(), SUSER_SNAME()
  
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.TruckType,'') <> isnull(i.TruckType,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(StartTime)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'StartTime', d.StartTime, i.StartTime, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.StartTime,'') <> isnull(i.StartTime,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(StopTime)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'StopTime', d.StopTime, i.StopTime, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.StopTime,'') <> isnull(i.StopTime,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(Loads)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Loads', convert(varchar(3),d.Loads), convert(varchar(3),i.Loads), getdate(), SUSER_SNAME()
          from inserted i
        join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.Loads <> i.Loads and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
  if Update(Miles)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Miles', convert(varchar(15),d.Miles), convert(varchar(15),i.Miles), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.Miles <> i.Miles and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(Hours)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Hours', convert(varchar(15),d.Hours), convert(varchar(15),i.Hours), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.Hours <> i.Hours and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(Zone)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Zone', d.Zone, i.Zone, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.Zone,'') <> isnull(i.Zone,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(HaulCode)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'HaulCode', d.HaulCode, i.HaulCode, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.HaulCode,'') <> isnull(i.HaulCode,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(HaulPhase)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'HaulPhase', d.HaulPhase, i.HaulPhase, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.HaulPhase,'') <> isnull(i.HaulPhase,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(HaulJCCType)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'HaulJCCType', convert(varchar(3),d.HaulJCCType), convert(varchar(3),i.HaulJCCType), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.HaulJCCType,'') <> isnull(i.HaulJCCType,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(HaulBasis)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'HaulBasis', convert(varchar(15),d.HaulBasis), convert(varchar(15),i.HaulBasis), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.HaulBasis <> i.HaulBasis and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(HaulRate)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'HaulRate', convert(varchar(15),d.HaulRate), convert(varchar(15),i.HaulRate), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.HaulRate <> i.HaulRate and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(HaulTotal)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'HaulTotal', convert(varchar(15),d.HaulTotal), convert(varchar(15),i.HaulTotal), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.HaulTotal <> i.HaulTotal and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(PayCode)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'PayCode', d.PayCode, i.PayCode, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.PayCode,'') <> isnull(i.PayCode,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(PayBasis)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'PayBasis', convert(varchar(15),d.PayBasis), convert(varchar(15),i.PayBasis), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.PayBasis <> i.PayBasis and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(PayRate)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'PayRate', convert(varchar(15),d.PayRate), convert(varchar(15),i.PayRate), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.PayRate <> i.PayRate and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(PayTotal)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'PayTotal', convert(varchar(15),d.PayTotal), convert(varchar(15),i.PayTotal), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
  where d.PayTotal <> i.PayTotal  and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(RevCode)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'RevCode', d.RevCode, i.RevCode, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.RevCode,'') <> isnull(i.RevCode,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(RevBasis)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'RevBasis', convert(varchar(15),d.RevBasis), convert(varchar(15),i.RevBasis), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.RevBasis <> i.RevBasis and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(RevRate)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'RevRate', convert(varchar(15),d.RevRate), convert(varchar(15),i.RevRate), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.RevRate <> i.RevRate and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(RevTotal)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'RevTotal', convert(varchar(15),d.RevTotal), convert(varchar(15),i.RevTotal), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.RevTotal <> i.RevTotal and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(TaxCode)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'TaxCode', d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
       	where isnull(d.TaxCode,'') <> isnull(i.TaxCode,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(TaxType)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'TaxType', convert(char(1),d.TaxType), convert(char(1),i.TaxType), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
  	    where isnull(d.TaxType,'') <> isnull(i.TaxType,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(TaxBasis)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'TaxBasis', convert(varchar(15),d.TaxBasis), convert(varchar(15),i.TaxBasis), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.TaxBasis <> i.TaxBasis and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(TaxTotal)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'TaxTotal', convert(varchar(15),d.TaxTotal), convert(varchar(15),i.TaxTotal), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.TaxTotal <> i.TaxTotal and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(DiscBasis)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'DiscBasis', convert(varchar(15),d.DiscBasis), convert(varchar(15),i.DiscBasis), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.DiscBasis <> i.DiscBasis and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(DiscRate)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'DiscRate', convert(varchar(15),d.DiscRate), convert(varchar(15),i.DiscRate), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.DiscRate <> i.DiscRate and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(DiscOff)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'DiscOff', convert(varchar(15),d.DiscOff), convert(varchar(15),i.DiscOff), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where d.DiscOff <> i.DiscOff and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(TaxDisc)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'TaxDisc', convert(varchar(15),d.TaxDisc), convert(varchar(15),i.TaxDisc), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
         where d.TaxDisc <> i.TaxDisc and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(Void)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Void', d.Void, i.Void, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.Void,'') <> isnull(i.Void,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
 end
  
      if Update(ShipAddress)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'ShipAddress', d.ShipAddress, i.ShipAddress, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.ShipAddress,'') <> isnull(i.ShipAddress,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(City)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'City', d.City, i.City, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.City,'') <> isnull(i.City,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(State)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'State', d.State, i.State, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.State,'') <> isnull(i.State,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(Zip)
          begin
      	insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Zip', d.Zip, i.Zip, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.Zip,'') <> isnull(i.Zip,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
      if Update(Country)
          begin
          insert bHQMA select 'bMSTD', ' Mth: ' + convert(char(8), i.Mth,1) + ' MSTrans: ' + convert(varchar(6), i.MSTrans),
              i.MSCo, 'C', 'Country', d.Country, i.Country, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on d.MSCo = i.MSCo and d.Mth = i.Mth and d.MSTrans = i.MSTrans
          join bMSCO c with (nolock) on c.MSCo = i.MSCo
          where isnull(d.Country,'') <> isnull(i.Country,'') and (c.AuditTics = 'Y' or (c.AuditHaulers = 'Y' and i.HaulTrans is not null))
          end
  
  END
  
  
  
  
  
  Trigger_End:  
  
  
  
  return
  
  
  
  error:
       select @errmsg = @errmsg +  ' - cannot update MS Transaction Detail!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction



GO
ALTER TABLE [dbo].[bMSTD] WITH NOCHECK ADD CONSTRAINT [CK_bMSTD_AuditYN] CHECK (([AuditYN]='Y' OR [AuditYN]='N'))
GO
ALTER TABLE [dbo].[bMSTD] WITH NOCHECK ADD CONSTRAINT [CK_bMSTD_Changed] CHECK (([Changed]='Y' OR [Changed]='N'))
GO
ALTER TABLE [dbo].[bMSTD] WITH NOCHECK ADD CONSTRAINT [CK_bMSTD_ECM] CHECK (([ECM]='E' OR [ECM]='M' OR [ECM]='C'))
GO
ALTER TABLE [dbo].[bMSTD] WITH NOCHECK ADD CONSTRAINT [CK_bMSTD_Hold] CHECK (([Hold]='Y' OR [Hold]='N'))
GO
ALTER TABLE [dbo].[bMSTD] WITH NOCHECK ADD CONSTRAINT [CK_bMSTD_Purge] CHECK (([Purge]='Y' OR [Purge]='N'))
GO
ALTER TABLE [dbo].[bMSTD] WITH NOCHECK ADD CONSTRAINT [CK_bMSTD_VerifyHaul] CHECK (([VerifyHaul]='Y' OR [VerifyHaul]='N'))
GO
ALTER TABLE [dbo].[bMSTD] WITH NOCHECK ADD CONSTRAINT [CK_bMSTD_Void] CHECK (([Void]='Y' OR [Void]='N'))
GO
ALTER TABLE [dbo].[bMSTD] ADD CONSTRAINT [PK_bMSTD] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bMSTD_HaulAPTLKeyID] ON [dbo].[bMSTD] ([HaulAPTLKeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bMSTD_MatlAPTLKeyID] ON [dbo].[bMSTD] ([MatlAPTLKeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bMSTD_MSCo_FromLoc_Ticket_MSTrans] ON [dbo].[bMSTD] ([MSCo], [MSTrans], [Ticket], [FromLoc]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biMSTDMSInv] ON [dbo].[bMSTD] ([MSCo], [Mth], [MSInv]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSTD] ON [dbo].[bMSTD] ([MSCo], [Mth], [MSTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biMSTDSaleDate] ON [dbo].[bMSTD] ([MSCo], [Mth], [SaleDate], [HaulerType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bMSTD_SurchargeKeyID] ON [dbo].[bMSTD] ([SurchargeKeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biMSTDTicket] ON [dbo].[bMSTD] ([Ticket], [MSCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bMSTD_UniqueAttchID] ON [dbo].[bMSTD] ([UniqueAttchID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
