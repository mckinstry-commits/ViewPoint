CREATE TABLE [dbo].[bMSTB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[MSTrans] [dbo].[bTrans] NULL,
[SaleDate] [dbo].[bDate] NULL,
[FromLoc] [dbo].[bLoc] NULL,
[Ticket] [dbo].[bTic] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[MatlVendor] [dbo].[bVendor] NULL,
[SaleType] [char] (1) COLLATE Latin1_General_BIN NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[PaymentType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[CheckNo] [dbo].[bCMRef] NULL,
[Hold] [dbo].[bYN] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[INCo] [dbo].[bCompany] NULL,
[ToLoc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[UM] [dbo].[bUM] NULL,
[MatlPhase] [dbo].[bPhase] NULL,
[MatlJCCType] [dbo].[bJCCType] NULL,
[GrossWght] [dbo].[bUnits] NULL,
[TareWght] [dbo].[bUnits] NULL,
[WghtUM] [dbo].[bUM] NULL,
[MatlUnits] [dbo].[bUnits] NULL,
[UnitPrice] [dbo].[bUnitCost] NULL,
[ECM] [dbo].[bECM] NULL,
[MatlTotal] [dbo].[bDollar] NULL,
[MatlCost] [dbo].[bDollar] NULL,
[HaulerType] [char] (1) COLLATE Latin1_General_BIN NULL,
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
[Loads] [smallint] NULL,
[Miles] [dbo].[bUnits] NULL,
[Hours] [dbo].[bHrs] NULL,
[Zone] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[HaulCode] [dbo].[bHaulCode] NULL,
[HaulPhase] [dbo].[bPhase] NULL,
[HaulJCCType] [dbo].[bJCCType] NULL,
[HaulBasis] [dbo].[bUnits] NULL,
[HaulRate] [dbo].[bUnitCost] NULL,
[HaulTotal] [dbo].[bDollar] NULL,
[PayCode] [dbo].[bPayCode] NULL,
[PayBasis] [dbo].[bUnits] NULL,
[PayRate] [dbo].[bUnitCost] NULL,
[PayTotal] [dbo].[bDollar] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[RevBasis] [dbo].[bUnits] NULL,
[RevRate] [dbo].[bUnitCost] NULL,
[RevTotal] [dbo].[bDollar] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[TaxBasis] [dbo].[bDollar] NULL,
[TaxTotal] [dbo].[bDollar] NULL,
[DiscBasis] [dbo].[bUnits] NULL,
[DiscRate] [dbo].[bUnitCost] NULL,
[DiscOff] [dbo].[bDollar] NULL,
[TaxDisc] [dbo].[bDollar] NULL,
[Void] [dbo].[bYN] NULL,
[OldSaleDate] [dbo].[bDate] NULL,
[OldTic] [dbo].[bTic] NULL,
[OldFromLoc] [dbo].[bLoc] NULL,
[OldVendorGroup] [dbo].[bGroup] NULL,
[OldMatlVendor] [dbo].[bVendor] NULL,
[OldSaleType] [char] (1) COLLATE Latin1_General_BIN NULL,
[OldCustGroup] [dbo].[bGroup] NULL,
[OldCustomer] [dbo].[bCustomer] NULL,
[OldCustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OldCustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OldPaymentType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[OldCheckNo] [dbo].[bCMRef] NULL,
[OldHold] [dbo].[bYN] NULL,
[OldJCCo] [dbo].[bCompany] NULL,
[OldJob] [dbo].[bJob] NULL,
[OldPhaseGroup] [dbo].[bGroup] NULL,
[OldINCo] [dbo].[bCompany] NULL,
[OldToLoc] [dbo].[bLoc] NULL,
[OldMatlGroup] [dbo].[bGroup] NULL,
[OldMaterial] [dbo].[bMatl] NULL,
[OldUM] [dbo].[bUM] NULL,
[OldMatlPhase] [dbo].[bPhase] NULL,
[OldMatlJCCType] [dbo].[bJCCType] NULL,
[OldGrossWght] [dbo].[bUnits] NULL,
[OldTareWght] [dbo].[bUnits] NULL,
[OldWghtUM] [dbo].[bUM] NULL,
[OldMatlUnits] [dbo].[bUnits] NULL,
[OldUnitPrice] [dbo].[bUnitCost] NULL,
[OldECM] [dbo].[bECM] NULL,
[OldMatlTotal] [dbo].[bDollar] NULL,
[OldMatlCost] [dbo].[bDollar] NULL,
[OldHaulerType] [char] (1) COLLATE Latin1_General_BIN NULL,
[OldHaulVendor] [dbo].[bVendor] NULL,
[OldTruck] [dbo].[bTruck] NULL,
[OldDriver] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldEMCo] [dbo].[bCompany] NULL,
[OldEquipment] [dbo].[bEquip] NULL,
[OldEMGroup] [dbo].[bGroup] NULL,
[OldPRCo] [dbo].[bCompany] NULL,
[OldEmployee] [dbo].[bEmployee] NULL,
[OldTruckType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldStartTime] [smalldatetime] NULL,
[OldStopTime] [smalldatetime] NULL,
[OldLoads] [smallint] NULL,
[OldMiles] [dbo].[bUnits] NULL,
[OldHours] [dbo].[bHrs] NULL,
[OldZone] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldHaulCode] [dbo].[bHaulCode] NULL,
[OldHaulPhase] [dbo].[bPhase] NULL,
[OldHaulJCCType] [dbo].[bJCCType] NULL,
[OldHaulBasis] [dbo].[bUnits] NULL,
[OldHaulRate] [dbo].[bUnitCost] NULL,
[OldHaulTotal] [dbo].[bDollar] NULL,
[OldPayCode] [dbo].[bPayCode] NULL,
[OldPayBasis] [dbo].[bUnits] NULL,
[OldPayRate] [dbo].[bUnitCost] NULL,
[OldPayTotal] [dbo].[bDollar] NULL,
[OldRevCode] [dbo].[bRevCode] NULL,
[OldRevBasis] [dbo].[bUnits] NULL,
[OldRevRate] [dbo].[bUnitCost] NULL,
[OldRevTotal] [dbo].[bDollar] NULL,
[OldTaxGroup] [dbo].[bGroup] NULL,
[OldTaxCode] [dbo].[bTaxCode] NULL,
[OldTaxType] [tinyint] NULL,
[OldTaxBasis] [dbo].[bDollar] NULL,
[OldTaxTotal] [dbo].[bDollar] NULL,
[OldDiscBasis] [dbo].[bUnits] NULL,
[OldDiscRate] [dbo].[bUnitCost] NULL,
[OldDiscOff] [dbo].[bDollar] NULL,
[OldTaxDisc] [dbo].[bDollar] NULL,
[OldVoid] [dbo].[bYN] NULL,
[OldMSInv] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldAPRef] [dbo].[bAPReference] NULL,
[OldVerifyHaul] [dbo].[bYN] NULL,
[Changed] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSTB_Changed] DEFAULT ('N'),
[OldReasonCode] [dbo].[bReasonCode] NULL,
[ReasonCode] [dbo].[bReasonCode] NULL,
[ShipAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[OldShipAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[OldCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[OldZip] [dbo].[bZip] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[APCo] [dbo].[bCompany] NULL,
[APMth] [dbo].[bMonth] NULL,
[OldAPCo] [dbo].[bCompany] NULL,
[OldAPMth] [dbo].[bMonth] NULL,
[MatlAPCo] [dbo].[bCompany] NULL,
[MatlAPMth] [dbo].[bMonth] NULL,
[MatlAPRef] [dbo].[bAPReference] NULL,
[OldMatlAPCo] [dbo].[bCompany] NULL,
[OldMatlAPMth] [dbo].[bMonth] NULL,
[OldMatlAPRef] [dbo].[bAPReference] NULL,
[OrigMSTrans] [int] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[OldCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[SurchargeKeyID] [bigint] NULL,
[SurchargeBasis] [dbo].[bUnits] NULL,
[SurchargeRate] [dbo].[bUnitCost] NULL,
[SurchargeCode] [smallint] NULL,
[HaulPayTaxCode] [dbo].[bTaxCode] NULL,
[HaulPayTaxRate] [dbo].[bUnitCost] NULL,
[OldHaulPayTaxCode] [dbo].[bTaxCode] NULL,
[OldHaulPayTaxRate] [dbo].[bUnitCost] NULL,
[HaulPayTaxAmt] [dbo].[bDollar] NULL,
[OldHaulPayTaxAmt] [dbo].[bDollar] NULL,
[HaulPayTaxType] [tinyint] NULL,
[OldHaulPayTaxType] [tinyint] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bMSTB] ADD
CONSTRAINT [CK_bMSTB_Changed] CHECK (([Changed]='Y' OR [Changed]='N' OR [Changed] IS NULL))
ALTER TABLE [dbo].[bMSTB] ADD
CONSTRAINT [CK_bMSTB_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M' OR [ECM] IS NULL))
ALTER TABLE [dbo].[bMSTB] ADD
CONSTRAINT [CK_bMSTB_Hold] CHECK (([Hold]='Y' OR [Hold]='N' OR [Hold] IS NULL))
ALTER TABLE [dbo].[bMSTB] ADD
CONSTRAINT [CK_bMSTB_OldECM] CHECK (([OldECM]='E' OR [OldECM]='C' OR [OldECM]='M' OR [OldECM] IS NULL))
ALTER TABLE [dbo].[bMSTB] ADD
CONSTRAINT [CK_bMSTB_OldHold] CHECK (([OldHold]='Y' OR [OldHold]='N' OR [OldHold] IS NULL))
ALTER TABLE [dbo].[bMSTB] ADD
CONSTRAINT [CK_bMSTB_OldVerifyHaul] CHECK (([OldVerifyHaul]='Y' OR [OldVerifyHaul]='N' OR [OldVerifyHaul] IS NULL))
ALTER TABLE [dbo].[bMSTB] ADD
CONSTRAINT [CK_bMSTB_OldVoid] CHECK (([OldVoid]='Y' OR [OldVoid]='N' OR [OldVoid] IS NULL))
ALTER TABLE [dbo].[bMSTB] ADD
CONSTRAINT [CK_bMSTB_Void] CHECK (([Void]='Y' OR [Void]='N' OR [Void] IS NULL))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************/
CREATE trigger [dbo].[btMSTBd] on [dbo].[bMSTB] for DELETE as
/*-----------------------------------------------------------------
*  Delete trigger MSTB
*  Created By:  GF 07/12/2000
*  Modified By: RM 03/05/01 - Added code to save deleted tickets based on MSCompany SaveDeleted flag.
*               GF 07/20/01 - Set AuditYN to 'N'
*               TV 03/21/02 Delete HQAT records
*				GF 06/20/03 - issue #20785 - added OldAPCo, OldAPMth to insert for MSTX
*				GF 07/23/03 - issue #21933 - speed improvement clean up.
*				GF 03/02/2005 - issue #19185 material vendor payment enhancement
*				GF 06/11/2007 - issue #124772 only insert MSTX records when deleting from MSTB where MSTrans is null
*				CHS 03/13/2008 - issue #1270892 - international addresses
*				DAN SO 05/18/09 - Issue: #133441 - Delete Attachments
*				DAN SO 02/14/2010 - Issue: #129350 - Delete ALL associated Surcharge Record(s) in bMSSurcharges
*
*	Unlock any associated MS Detail - set InUseBatchId to null.
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int

	select @numrows = @@rowcount
	if @numrows = 0 return
	set nocount on


	select @validcnt = count(*) from deleted where MSTrans is not null

	---- 'unlock' existing MS Detail
	update bMSTD set InUseBatchId = null
	from bMSTD t join deleted d on d.Co = t.MSCo and d.Mth = t.Mth and d.MSTrans = t.MSTrans

	if @@rowcount <> @validcnt
		begin
		select @errmsg = 'Unable to unlock MS Transaction Detail' 
		goto error
		end


	---- If an 'add' ticket, save in deleted tickets when tickets are deleted from the batch
	insert bMSTX(MSCo,Mth,MSTrans,SaleDate,Ticket,FromLoc,VendorGroup,MatlVendor,SaleType,CustGroup,Customer,
   		CustJob,CustPO,PaymentType,CheckNo,Hold,JCCo,Job,PhaseGroup,INCo,ToLoc,MatlGroup,Material,UM,MatlPhase,
   		MatlJCCType,GrossWght,TareWght,WghtUM,MatlUnits,UnitPrice,ECM,MatlTotal,MatlCost,HaulerType,HaulVendor,
   		Truck,Driver,EMCo,Equipment,EMGroup,PRCo,Employee,TruckType,StartTime,StopTime,Loads,Miles,Hours,Zone,
   		HaulCode,HaulPhase,HaulJCCType,HaulBasis,HaulRate,HaulTotal,PayCode,PayBasis,PayRate,PayTotal,RevCode,
   		RevBasis,RevRate,RevTotal,TaxGroup,TaxCode,TaxType,TaxBasis,TaxTotal,DiscBasis,DiscRate,DiscOff,TaxDisc,
   		Void,APRef,VerifyHaul,Changed,ReasonCode,BatchId,DeleteDate,VPUserName,ShipAddress,City,State,Zip,
   		APCo,APMth,MatlAPCo,MatlAPMth,MatlAPRef,Country)
	select d.Co,d.Mth,d.MSTrans,d.OldSaleDate,d.Ticket,d.OldFromLoc,d.OldVendorGroup,d.OldMatlVendor,d.OldSaleType,
   		d.OldCustGroup,d.OldCustomer,d.OldCustJob,d.OldCustPO,d.OldPaymentType,d.OldCheckNo,d.OldHold,d.OldJCCo,
   		d.OldJob,d.OldPhaseGroup,d.OldINCo,d.OldToLoc,d.OldMatlGroup,d.OldMaterial,d.OldUM,d.OldMatlPhase,
   		d.OldMatlJCCType,d.OldGrossWght,d.OldTareWght,d.OldWghtUM,d.OldMatlUnits,d.OldUnitPrice,d.OldECM,
   		d.OldMatlTotal,d.OldMatlCost,d.OldHaulerType,d.OldHaulVendor,d.OldTruck,d.OldDriver,d.OldEMCo,d.OldEquipment,
   		d.OldEMGroup,d.OldPRCo,d.OldEmployee,d.OldTruckType,d.OldStartTime,d.OldStopTime,d.OldLoads,d.OldMiles,
   		d.OldHours,d.OldZone,d.OldHaulCode,d.OldHaulPhase,d.OldHaulJCCType,d.OldHaulBasis,d.OldHaulRate,d.OldHaulTotal,
   		d.OldPayCode,d.OldPayBasis,d.OldPayRate,d.OldPayTotal,d.OldRevCode,d.OldRevBasis,d.OldRevRate,d.OldRevTotal,
   		d.OldTaxGroup,d.OldTaxCode,d.OldTaxType,d.OldTaxBasis,d.OldTaxTotal,d.OldDiscBasis,d.OldDiscRate,d.OldDiscOff,
   		d.OldTaxDisc,d.OldVoid,d.OldAPRef,d.OldVerifyHaul,d.Changed,d.ReasonCode,d.BatchId,getdate(),suser_sname(),
   		d.OldShipAddress,d.OldCity,d.OldState,d.OldZip,d.OldAPCo,d.OldAPMth,d.MatlAPCo,d.MatlAPMth,d.MatlAPRef,d.Country
	from deleted d
	join bMSCO c with (nolock) on d.Co=c.MSCo
	where d.BatchTransType = 'A' and c.SaveDeleted = 'Y' and d.MSTrans is null
	
	-- ISSUE: #133441 --
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	INSERT vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
		SELECT AttachmentID, SUSER_NAME(), 'Y' 
          FROM bHQAT h JOIN deleted d 
			ON h.UniqueAttchID = d.UniqueAttchID
         WHERE h.UniqueAttchID NOT IN(SELECT t.UniqueAttchID 
										FROM bMSTD t JOIN deleted d1 
										  ON t.UniqueAttchID = d1.UniqueAttchID)
           AND d.UniqueAttchID IS NOT NULL    


	-----------------------------------------------
	-- DELETE ALL ASSOCIATED SURCHARGE RECORD(S) --
	-----------------------------------------------
	-- ISSUE: #129350 --
	DELETE bMSSurcharges 
	  FROM bMSSurcharges s WITH (NOLOCK)
	  JOIN Deleted d ON d.KeyID = s.MSTBKeyID


	-- IF THE PARENT TICKET STILL EXISTS IN MSTB --
	-- RESET THE DELETED RECORD InUseBatchId --
	UPDATE bMSTD 
	   SET InUseBatchId = d.BatchId
	  FROM bMSTD t WITH (NOLOCK)
      JOIN Deleted d ON d.Co = t.MSCo AND d.Mth = t.Mth AND d.MSTrans = t.MSTrans
      JOIN bMSTB b WITH (NOLOCK) ON b.KeyID = d.SurchargeKeyID


return


error:
	select @errmsg = @errmsg + ' - cannot delete MS Ticket Batch!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO

GO

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE trigger [dbo].[btMSTBi] on [dbo].[bMSTB] for INSERT as
/*--------------------------------------------------------------
* Created By: GF 07/12/2000
* Modified By: GG 10/31/00 - Save original values as 'old' for all new entries
*              RM 03/05/01 - save original values as old for Reason Code
*              GG 03/12/01 - auto add entries for Equipment attachments
*				GG 03/15/02 - #16679 - fix to Seq# when adding Equip attachments 
*				GG 09/17/02 - #18583 - fix to save 'old' values
*				GG 03/25/03 - #20702 - init haul charges for attachments if haul code is revenue based
*				GF 06/20/03 - #20785 - added update for OldAPCo=APCo and OldAPMth=APMth for old values
*				GF 07/23/03 - #21933 - misc performance improvements
*				GF 08/18/03 - issue #22195 - for equipment attachments - use same cost type from original
*				GF 08/22/03 - #22227 - need to check EMRC.HaulBased flag. 
*								Use haul basis, haulrate, basis*haulrate for revenue on attachment.
*				GF 03/02/2005 - issue #19185 material vendor enhancement
*				CHS 03/13/2008 - issue #1270892 - international addresses
*				DAN SO 10/13/2009 - Issue #129350 - Check SurchargeKeyID while dealing with Equipment Attachments
*				DAN SO 02/10/2010 - Issue #129350 - AutoCreate Surcharges 
*				GF 04/26/2013 TFS-48578 look for haul rate quote override for equipment attachments
*
*
* Insert trigger bMSTB
*
* Performs validation on critical columns only.
*
* Locks bMSTD entries pulled into batch
*
* Adds bHQCC entries as needed
*
*--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @opencursor tinyint, @msglco bCompany, @co bCompany,
		@mth bMonth, @batchid bBatchID, @inco bCompany,  @jcco bCompany, @emco bCompany, @glco bCompany, @batchseq int,
		@saletype char(1), @job bJob, @equipment bEquip, @emgroup bGroup, @revcode bRevCode, @attachment bEquip,
		@attachpostrev bYN, @emcategory bCat, @equipctype bJCCType, @mstrucktype varchar(10), @emtranstype char(1),
		@timeum bUM, @workum bUM, @msg varchar(255), @rcode tinyint, @revrate bUnitCost, @seq int, @haulcode bHaulCode,
   		@revbased bYN, @haulbased bYN, 
   		@curAutoCreateOpen tinyint, @MSTBKeyID bigint, @MatlGroup bGroup, @Material bMatl, @FromLoc bLoc, @UM bUM,
   		@Zone varchar(10), @PhaseGroup bGroup, @Phase bPhase, @CustGroup bGroup, @Customer bCustomer, 
		@CustJob varchar(20), @CustPO varchar(20), @ToLoc bLoc, @TempRCode int, @TempMsg varchar(255), @PaymentType char(1)
		----TFS-48578
		,@Quote VARCHAR(10), @LocGroup bGroup, @Category VARCHAR(10), @OvrHaulRate bUnitCost, @HaulBasis TINYINT
   

   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0   
   
	-- validate batch
	select @validcnt = count(*) from bHQBC r with (nolock) 
	JOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId
	if @validcnt<>@numrows
		begin
			select @errmsg = 'Invalid Batch ID#'
			goto error
		end
   
	select @validcnt = count(*) from bHQBC r with (nolock) 
	JOIN inserted i ON i.Co=r.Co and i.Mth = r.Mth and i.BatchId=r.BatchId and r.Status = 0
	if @validcnt <> @numrows
		begin
			select @errmsg = 'Must be an open batch.'
			goto error
		end
   
	-- validate BatchTransType
	if exists(select 1 from inserted where BatchTransType not in ('A','C','D'))
		begin
			select @errmsg = 'Invalid Batch Trans Type, must be A, C,or D!'
			goto error
		end
   
	-- validate MS Trans#
	if exists(select 1 from inserted where BatchTransType = 'A' and MSTrans is not null)
		begin
			select @errmsg = 'MS Trans # must be null for all type A entries!'
			goto error
		end
   
	if exists(select * from inserted where BatchTransType <> 'A' and MSTrans is null)
		begin
			select @errmsg = 'All type C and D entries must have an MS Trans #!'
			goto error
		end
  
	----------------------------
	-- AUTO CREATE SURCHARGES --
	----------------------------
	-- ISSUE: #129350 --
	SELECT @PaymentType = PaymentType FROM inserted
	
	-- CREATE SURCHARGES FOR CUSTOMER's WHEN PAYING ON ACCOUNT
	-- CREATE SURCHARGES FOR ALL JOB AND INVENTORY SALES
	IF (@saletype = 'C' AND @PaymentType = 'A') OR (@saletype in ('J','I'))
		BEGIN
			-- DO NOT ATTEMPT TO CREATE SURCHARGES FOR ATTACHED EQUIPMENT --
			IF NOT EXISTS (SELECT 1 FROM bEMEM m WITH (NOLOCK) 
							 JOIN Inserted i ON i.EMCo = m.EMCo AND i.Equipment = m.Equipment
							WHERE m.AttachToEquip IS NOT NULL)
				BEGIN	
			
					-- SET UP CURSOR --
					DECLARE curAutoCreate CURSOR LOCAL FAST_FORWARD FOR
						SELECT  Co, Mth, BatchId, BatchSeq, KeyID, MatlGroup, Material, 
								FromLoc, TruckType, UM, Zone, JCCo, Job, PhaseGroup, HaulPhase, SaleType,
								CustGroup, Customer, CustJob, CustPO, INCo, ToLoc
						  FROM  Inserted i
						 WHERE	i.SurchargeKeyID IS NULL
						   AND	i.BatchTransType = 'A'
						  
					-- PRIME VALUES --
					OPEN curAutoCreate
					SET @curAutoCreateOpen = 1
					
					FETCH NEXT FROM curAutoCreate
						INTO @co, @mth, @batchid, @batchseq, @MSTBKeyID, @MatlGroup, @Material, 
							@FromLoc, @mstrucktype, @UM, @Zone, @jcco, @job, @PhaseGroup, @Phase, @saletype,
							@CustGroup, @Customer, @CustJob, @CustPO, @inco, @ToLoc
																					
					-- LOOP THROUGH CURSOR --
					WHILE @@FETCH_STATUS = 0
						BEGIN
					
							-- SEARCH/CREATE SURCHARGES --
							EXEC @TempRCode = vspMSSurchargeAutoCreate @co, @mth, @batchid, @batchseq, @MSTBKeyID, 
										@MatlGroup, @Material, @FromLoc, @mstrucktype, @UM, @Zone, @jcco, @job, @PhaseGroup, 
										@Phase, @saletype, @CustGroup, @Customer, @CustJob, @CustPO, @inco, @ToLoc,
										@TempMsg output
										
							-- CHECK SUCCESS --
							IF @TempRCode = 1
								BEGIN
									SET @errmsg = 'AutoCreate Error: ' + ISNULL(@TempMsg, '')
									GOTO error
								END
					
							-- GET NEXT RECORD --
							FETCH NEXT FROM curAutoCreate
								INTO @co, @mth, @batchid, @batchseq, @MSTBKeyID, @MatlGroup, @Material, 
									@FromLoc, @mstrucktype, @UM, @Zone, @jcco, @job, @PhaseGroup, @Phase, @saletype,
									@CustGroup, @Customer, @CustJob, @CustPO, @inco, @ToLoc
						
						END	-- WHILE @@FETCH_STATUS = 0

					-- CLOSE AND REMOVE CURSOR --
					IF @curAutoCreateOpen = 1
						BEGIN
							CLOSE curAutoCreate
							DEALLOCATE curAutoCreate
							SET @curAutoCreateOpen = 0
						END

				END	-- IF NOT EXISTS......
		END -- IF @PaymentType = 'A'
	--------------------------------
	-- END AUTO CREATE SURCHARGES --
	--------------------------------
   
	-- check for new Tickets posted with Equipment Usage
	if exists(select 1 from inserted where BatchTransType = 'A' and Equipment is not null and RevCode is not null
		and isnull(Void,'N') <> 'Y' and SurchargeKeyID IS NULL) --ISSUE: #129350
		begin
		
			-- add equipment usage entries for attachments
			if @numrows = 1
				select @co = Co, @mth = Mth, @batchid = BatchId, @batchseq = BatchSeq, @saletype = SaleType,
						@jcco = JCCo, @job = Job, @emco = EMCo, @equipment = Equipment, @emgroup = EMGroup, 
						@revcode = RevCode, @haulcode = HaulCode, @equipctype = HaulJCCType
						----TFS-48578
						,@FromLoc = FromLoc, @CustGroup = CustGroup, @Customer = Customer, @CustJob = CustJob
						,@CustPO = CustPO, @inco = INCo, @ToLoc = ToLoc, @MatlGroup = MatlGroup, @Material = Material
						,@UM = UM, @Zone = Zone, @PhaseGroup = PhaseGroup, @Phase = HaulPhase
				from inserted
			else
				begin
					-- use a cursor to process each inserted row
					declare bMSTB_insert cursor LOCAL FAST_FORWARD
						for select Co, Mth, BatchId, BatchSeq, SaleType, JCCo, Job, EMCo, Equipment, EMGroup, RevCode, HaulCode, HaulJCCType
								----TFS-48578
								,FromLoc, CustGroup, Customer, CustJob, CustPO, INCo, ToLoc, MatlGroup, Material
								,UM, Zone, PhaseGroup, HaulPhase
							from inserted
							where BatchTransType = 'A' and Equipment is not null and RevCode is not null and isnull(Void,'N') <> 'Y'

					open bMSTB_insert
					set @opencursor = 1  -- open cursor flag

					fetch next from bMSTB_insert into @co, @mth, @batchid, @batchseq, @saletype, @jcco, @job, @emco, @equipment,
								@emgroup, @revcode, @haulcode, @equipctype
								----TFS-48578
								,@FromLoc, @CustGroup, @Customer, @CustJob, @CustPO, @inco, @ToLoc, @MatlGroup, @Material
								,@UM, @Zone, @PhaseGroup, @Phase
					if @@fetch_status <> 0
						begin
							select @errmsg = 'Cursor error'
							goto error
						end
				end --if @numrows = 1
   
			attachment_check:
			   -- check for Equipment Attachments
			   if exists(select 1 from dbo.bEMEM with (nolock) where EMCo = @emco and AttachToEquip = @equipment and Status = 'A')
				   begin
						-- get last BatchSeq # here because inserted will not include entries added in trigger for attachments
						select @seq = isnull(max(BatchSeq),0) 
						from inserted i where i.Co = @co and i.Mth = @mth and i.BatchId = @batchid
						-- get first Attachment
						select @attachment = min(Equipment)
						from bEMEM with (nolock) where EMCo = @emco and AttachToEquip = @equipment and Status = 'A'
						
						-- if posting revenue to Attachment - add a timecard
						while @attachment is not null
						   begin
							   select @attachpostrev = AttachPostRevenue, @emcategory = Category, @mstrucktype = MSTruckType
							   from bEMEM with (nolock) 
							   where EMCo = @emco and Equipment = @attachment
								
							   SET @OvrHaulRate = NULL
							   if @attachpostrev = 'Y'
									BEGIN
									----TFS-48578 check for haul rate override for attachment
									-- check for revenue based haul code
									set @revbased = 'N'
									select @revbased = RevBased from bMSHC with (nolock) where MSCo = @co and HaulCode = @haulcode

									-- check for haul based revenue code
									set @haulbased = 'N'
									select @haulbased = HaulBased from bEMRC with (nolock) where EMGroup = @emgroup and RevCode = @revcode

									----need location group                                          
									SELECT @LocGroup = LocGroup
									FROM dbo.bINLM WITH (NOLOCK)
									WHERE INCo = @co
										AND Loc = @FromLoc
									IF @@ROWCOUNT = 0 SET @LocGroup = NULL
									---- need material category
									SELECT @Category = Category
									FROM dbo.bHQMT WITH (NOLOCK)
									WHERE MatlGroup = @MatlGroup
										AND Material = @Material
									IF @@ROWCOUNT = 0 SET @Category = NULL
									---- need haul basis                                          
									SELECT @HaulBasis = HaulBasis
									from dbo.bMSHC WITH (NOLOCK)
									WHERE MSCo = @co
										AND HaulCode = @haulcode
									if @@rowcount = 0 SET @HaulBasis = NULL

									----check for quote for ticket
									EXEC @TempRCode = dbo.bspMSTicTemplateGet @co, @saletype, @CustGroup, @Customer, @CustJob, @CustPO, @jcco, @job, @inco, @ToLoc, @FromLoc,
													@Quote OUTPUT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @TempMsg OUTPUT
									IF @TempRCode <> 0 SET @Quote = NULL
                                                        
									---- get haul rate
									EXEC @TempRCode = dbo.bspMSTicHaulRateGet @co, @haulcode, @MatlGroup, @Material, @Category, @LocGroup,
													@FromLoc, @mstrucktype, @UM, @Quote, @Zone, @HaulBasis, @jcco, @PhaseGroup, @Phase,
													@OvrHaulRate OUTPUT, NULL, @TempMsg OUTPUT
									IF @TempRCode <> 0 SET @OvrHaulRate = NULL
									IF @OvrHaulRate = 0 SET @OvrHaulRate = NULL                                      
									----PRINT dbo.vfToString(@OvrHaulRate)
                                        
									-- get default revenue code rate for attachment
									SET @emtranstype = CASE WHEN @saletype <> 'J' THEN 'X' ELSE 'J' END
									exec @rcode = bspEMRevRateUMDflt @emco, @emgroup, @emtranstype, @attachment, @emcategory, @revcode,
															@jcco, @job, @revrate output, @timeum output, @workum output, @msg output
									if @rcode <> 0 SET @revrate = 0
				   
                  					select @seq = @seq + 1
				   
									insert into bMSTB (Co, Mth, BatchId, BatchSeq, BatchTransType, SaleDate, FromLoc, Ticket, VendorGroup,
										MatlVendor, SaleType, CustGroup, Customer, CustJob, CustPO, PaymentType, CheckNo, Hold, JCCo,
										Job, PhaseGroup, INCo, ToLoc, MatlGroup, Material, UM, MatlPhase, MatlJCCType, GrossWght, TareWght,
										WghtUM, MatlUnits, UnitPrice, ECM, MatlTotal, MatlCost, HaulerType, EMCo, Equipment, EMGroup, PRCo,
										Employee, TruckType, StartTime, StopTime, Loads, Miles, Hours, Zone, HaulCode, HaulPhase, HaulJCCType,
										HaulBasis, HaulRate, HaulTotal, PayCode, PayBasis, PayRate, PayTotal, RevCode, RevBasis, RevRate,
										RevTotal, TaxGroup, TaxCode, TaxType, TaxBasis, TaxTotal, DiscBasis, DiscRate, DiscOff, TaxDisc,
										Void, Changed, ReasonCode)
									select @co, @mth, @batchid, @seq, 'A', SaleDate, FromLoc, Ticket, VendorGroup,
										MatlVendor, SaleType, CustGroup, Customer, CustJob, CustPO, PaymentType, CheckNo, Hold, JCCo,
										Job, PhaseGroup, INCo, ToLoc, MatlGroup, Material, UM, MatlPhase, MatlJCCType, 0, 0,
										WghtUM, 0, UnitPrice, ECM, 0, 0, 'E', EMCo, @attachment, EMGroup, PRCo,
										Employee, @mstrucktype, StartTime, StopTime, Loads, Miles, Hours, Zone, HaulCode, HaulPhase,
										(case SaleType when 'J' then @equipctype else null end),
										-- #20702 - if haul code is revenue based, init haul charge using attachment revenue
										(case @revbased when 'Y' then RevBasis else 0 end),
										----TFS-48578
										(case @revbased when 'Y' then @revrate else ISNULL(@OvrHaulRate, HaulRate) end),		
										(case @revbased when 'Y' then (RevBasis * @revrate) else 0 end),	
										null, 0, 0, 0, RevCode,
										-- #22227 - if rev code is haul based, init rev charge using haul code
										(case @haulbased when 'Y' then 0 else RevBasis end),
										----TFS-48578
										(case @haulbased when 'Y' then ISNULL(@OvrHaulRate, HaulRate) else @revrate end),
										(case @haulbased when 'Y' then 0 else (RevBasis * @revrate) end),
										TaxGroup, TaxCode, TaxType, 0, 0, 0, DiscRate, 0, 0, 'N', 'N', ReasonCode
									from inserted
									where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
									END --if @attachpostrev = 'Y'
								
								-- get next Attachment
								select @attachment = min(Equipment)
								from bEMEM with (nolock) 
								where EMCo = @emco and AttachToEquip = @equipment and Status = 'A' and Equipment > @attachment
		                   
						   end --while @attachment is not null
						   
				   end --if exists(select 1 from bEMEM ......
   
				if @opencursor = 1
					begin
						fetch next from bMSTB_insert into @co, @mth, @batchid, @batchseq, @saletype, @jcco, @job, @emco, @equipment,
								@emgroup, @revcode, @haulcode, @equipctype
								----TFS-48578
								,@FromLoc, @CustGroup, @Customer, @CustJob, @CustPO, @inco, @ToLoc, @MatlGroup, @Material
								,@UM, @Zone, @PhaseGroup, @Phase

						if @@fetch_status = 0
							goto attachment_check
						else
							begin
								close bMSTB_insert
								deallocate bMSTB_insert
								select @opencursor = 0
							end
    				end --if @opencursor = 1
		end --if exists(select 1 from inserted
   
	--save initial values on all new entries by setting 'old' values equal to current values
	--this will allow us to rollback any changes using an 'undo' procedure on the batch (offered in MS Mass Edit)
	update bMSTB
	set OldSaleDate = i.SaleDate, OldTic = i.Ticket, OldFromLoc = i.FromLoc, OldVendorGroup = i.VendorGroup,
		OldMatlVendor = i.MatlVendor, OldSaleType = i.SaleType, OldCustGroup = i.CustGroup, OldCustomer = i.Customer,
		OldCustJob = i.CustJob, OldCustPO = i.CustPO, OldPaymentType = i.PaymentType, OldCheckNo = i.CheckNo,
		OldHold = i.Hold, OldJCCo = i.JCCo, OldJob = i.Job, OldPhaseGroup = i.PhaseGroup, OldINCo = i.INCo,
		OldToLoc = i.ToLoc, OldMatlGroup = i.MatlGroup, OldMaterial = i.Material, OldUM = i.UM, OldMatlPhase = i.MatlPhase,
		OldMatlJCCType = i.MatlJCCType, OldGrossWght = i.GrossWght, OldTareWght = i.TareWght, OldWghtUM = i.WghtUM,
		OldMatlUnits = i.MatlUnits, OldUnitPrice = i.UnitPrice, OldECM = i.ECM, OldMatlTotal = i.MatlTotal,
		OldMatlCost = i.MatlCost, OldHaulerType = i.HaulerType, OldHaulVendor = i.HaulVendor, OldTruck = i.Truck,
		OldDriver = i.Driver, OldEMCo = i.EMCo, OldEquipment = i.Equipment, OldEMGroup = i.EMGroup,
		OldPRCo = i.PRCo, OldEmployee = i.Employee, OldTruckType = i.TruckType, OldStartTime = i.StartTime,
		OldStopTime = i.StopTime, OldLoads = i.Loads, OldMiles = i.Miles, OldHours = i.Hours, OldZone = i.Zone,
		OldHaulCode = i.HaulCode, OldHaulPhase = i.HaulPhase, OldHaulJCCType = i.HaulJCCType, OldHaulBasis = i.HaulBasis, 
		OldHaulRate = i.HaulRate, OldHaulTotal = i.HaulTotal, OldPayCode = i.PayCode, OldPayBasis = i.PayBasis,
		OldPayRate = i.PayRate, OldPayTotal = i.PayTotal, OldRevCode = i.RevCode, OldRevBasis = i.RevBasis,
		OldRevRate = i.RevRate, OldRevTotal = i.RevTotal, OldTaxGroup = i.TaxGroup, OldTaxCode = i.TaxCode,
		OldTaxType = i.TaxType, OldTaxBasis = i.TaxBasis, OldTaxTotal = i.TaxTotal, OldDiscBasis = i.DiscBasis,
		OldDiscRate = i.DiscRate, OldDiscOff = i.DiscOff, OldTaxDisc = i.TaxDisc, OldVoid = i.Void, OldMSInv = null,
		OldAPRef = null, OldVerifyHaul = 'N', OldReasonCode = i.ReasonCode, OldShipAddress = i.ShipAddress,
		OldCity = i.City, OldState = i.State, OldZip = i.Zip, OldAPCo = i.APCo, OldAPMth = i.APMth,
		OldMatlAPCo = i.MatlAPCo, OldMatlAPMth = i.MatlAPMth, OldMatlAPRef = i.MatlAPRef, OldCountry = i.Country
	from inserted i
	join bMSTB b on i.Co = b.Co and i.Mth = b.Mth and i.BatchId = b.BatchId and i.BatchSeq = b.BatchSeq
	where i.BatchTransType = 'A' 	-- applies to new entries only
   
	-- attempt to update InUseBatchId in MSTD
	select @validcnt = count(*) from inserted where BatchTransType <> 'A'
												AND SurchargeKeyID IS NULL	--ISSUE: #129350

	update bMSTD
	set InUseBatchId = i.BatchId
	from bMSTD t join inserted i on i.Co = t.MSCo and i.Mth = t.Mth and i.MSTrans = t.MSTrans
	where t.InUseBatchId is null	-- must be unlocked
	  AND t.SurchargeKeyID IS NULL	--ISSUE: #129350
	
	if @validcnt <> @@rowcount
		begin
			select @errmsg = 'Unable to lock existing MS Transaction!'
			goto error
		end
   
	-- Add entries to HQ Close Control if needed.
	if @numrows = 1
		select @co = i.Co, @mth = i.Mth, @batchid = i.BatchId, @jcco = JCCo, @inco = INCo, @emco = EMCo, @msglco = c.GLCo
		from inserted i join bMSCO c on i.Co = c.MSCo
	else
		begin
			-- use a cursor to process each inserted row
			declare bMSTB_insert cursor for
				select distinct i.Co, i.Mth, i.BatchId, i.JCCo, i.INCo, i.EMCo, c.GLCo
				from inserted i join bMSCO c on i.Co = c.GLCo

			open bMSTB_insert
			select @opencursor = 1

			fetch next from bMSTB_insert into @co, @mth, @batchid,  @jcco, @inco, @emco, @msglco
			if @@fetch_status <> 0
				begin
					select @errmsg = 'Cursor error'
					goto error
				end
		end --if @numrows = 1
   
	insert_HQCC_check:

	-- add entry to HQ Close Control for MS Company GLCo
	if not exists(select top 1 1 from bHQCC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @msglco)
		begin
			insert bHQCC (Co, Mth, BatchId, GLCo)
			values (@co, @mth, @batchid, @msglco)
		end

	-- get GL Company for Job sales
	if @jcco is not null
		begin
			select @glco = GLCo from bJCCO with (nolock) where JCCo = @jcco
			if @@rowcount <> 0
				begin
					-- add entry to HQ Close Control for Job Sale
					if not exists(select top 1 1 from bHQCC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
						begin
							insert bHQCC (Co, Mth, BatchId, GLCo)
							values (@co, @mth, @batchid, @glco)
						end
				end
		end --if @jcco is not null

	-- get GL Company for Inventory sales
	if @inco is not null
		begin
			select @glco = GLCo from bINCO with (nolock) where INCo = @inco
			if @@rowcount <> 0
				begin
					-- add entry to HQ Close Control for Inventory Sale
					if not exists(select top 1 1 from bHQCC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
						begin
							insert bHQCC (Co, Mth, BatchId, GLCo)
							values (@co, @mth, @batchid, @glco)
						end
				end
		end --if @inco is not null

	-- get GL Company for Equipment use
	if @emco is not null
		begin
			select @glco = GLCo from bEMCO with (nolock) where EMCo = @emco
			if @@rowcount <> 0
				begin
					-- add entry to HQ Close Control for Equipment use
					if not exists(select top 1 1 from bHQCC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
						begin
							insert bHQCC (Co, Mth, BatchId, GLCo)
							values (@co, @mth, @batchid, @glco)
						end
				end
		end --if @emco is not null


	if @numrows > 1
		begin
			fetch next from bMSTB_insert into @co, @mth, @batchid,  @jcco, @inco, @emco, @msglco
			if @@fetch_status = 0 goto insert_HQCC_check

			close bMSTB_insert
			deallocate bMSTB_insert
			set @opencursor = 0
		end


	return
   
	--------------------
	-- ERROR HANDLING --
	--------------------   
	error:
		if @opencursor = 1
			begin
				close bMSTB_insert
				deallocate bMSTB_insert
			end


		-- CLOSE AND REMOVE CURSOR --
		-- ISSUE: #129350
		IF @curAutoCreateOpen = 1
			BEGIN
				CLOSE curAutoCreate
				DEALLOCATE curAutoCreate
				SET @curAutoCreateOpen = 0
			END
		
		select @errmsg = @errmsg + ' - cannot insert MS Ticket Batch'
		RAISERROR(@errmsg, 11, -1);
		rollback transaction


GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btMSTBu] on [dbo].[bMSTB] for UPDATE as
   

/*-----------------------------------------------------------------
* Created:  GG 10/24/00
* Modified: RM 03/05/01 - updated to track if anything changed.
*			DANF - #18001 - changed MS Transaction check for transactions that are changed or deleted.
*			GF 07/23/2003 - #21933 - performance improvements
*			GF 06/14/2004 - #24827 - error in select cursor - wrong column in where clause
*			CHS 03/13/2008 - issue #1270892 - international addresses
*			DAN SO 10/08/2009 - ISSUE: #129350 - Delete/Recreate Surcharge Record(s) 
*												- Reformatted and modified Select and Cursor delcaration
*			GF 04/30/2013 TFS-48487 do not re-generate surcharges if we have an APRef/MatlAPRef
*									
*
* Update trigger for bMSTB (Ticket Batch)
*
* Cannot change Company, Mth, BatchId, Seq, or MS Trans
*
* Add HQCC (Close Control) as needed.
*
*----------------------------------------------------------------*/
   
   declare @numrows int, @validcount int, @co bCompany, @mth bMonth, @batchid bBatchID,
   @seq int, @errmsg varchar(max), @opencursor tinyint, @jcco bCompany, @inco bCompany,
   @emco bCompany, @msglco bCompany, @glco bCompany, @validcount2 int,
   @MatlTotal bDollar, @MatlUnits bUnits, @HaulCharge bDollar, @HaulUnits bUnits, 
   @Miles bUnits, @Loads bUnits, @KeyID bigint, @MatlGroup bGroup, @Material bMatl, @FromLoc bLoc, 
   @TruckType varchar(10), @UM bUM, @Zone varchar(10), @Job bJob, @PhaseGroup bGroup, @Phase bPhase, 
   @SaleType char(1), @CustGroup bGroup, @Customer bCustomer, @CustJob varchar(20), @CustPO varchar(20), 
   @ToLoc bLoc, @TempRCode int, @TempMsg varchar(255), @SurchargeKeyID bigint, @Changed bYN, @Invoice varchar(10),
   @ParentTransType char(1), @PaymentType char(1), @rcode int

   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
    
   -- check for key changes
   select @validcount = count(*)
   from deleted d join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId
   and d.BatchSeq = i.BatchSeq --and isnull(d.MSTrans,0) = isnull(i.MSTrans,0)
   
   if @numrows <> @validcount
   	begin
   		select @errmsg = 'Cannot change Company, Month, Batch ID #, Sequence #'
   		goto error
   	end
   
   -- check for key changes on MS Trans for any deleted or changed transactions
   select @validcount2 = count(*)
   from inserted i  where i.BatchTransType <> 'A'
   
   select @validcount = count(*)
   from deleted d join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId
   and d.BatchSeq = i.BatchSeq and isnull(d.MSTrans,0) = isnull(i.MSTrans,0) and i.BatchTransType <> 'A'
   
   if @validcount2 <> @validcount
   	begin
   		select @errmsg = 'Cannot change MS Trans #'
   		goto error
   	end
   
   -- cursor only needed if more than a single row updated
   if @numrows = 1

		SELECT	@co = ISNULL(i.Co, d.Co), @mth = ISNULL(i.Mth, d.Mth), @batchid = ISNULL(i.BatchId, d.BatchId),
				@jcco = ISNULL(i.JCCo, d.JCCo), @inco= ISNULL(i.INCo, d.INCo), @emco = i.EMCo, @msglco = c.GLCo,
				@MatlTotal = ISNULL(i.MatlTotal, 0), @MatlUnits = ISNULL(i.MatlUnits, 0), @HaulCharge = ISNULL(i.HaulTotal, 0), 
				@HaulUnits = ISNULL(i.HaulBasis, 0), @Miles = ISNULL(i.Miles, 0), @Loads = ISNULL(i.Loads, 0), 
				@KeyID = ISNULL(i.KeyID, d.KeyID), @seq = ISNULL(i.BatchSeq, d.BatchSeq), @MatlGroup = ISNULL(i.MatlGroup, d.MatlGroup), 
				@Material = ISNULL(i.Material, d.Material), @FromLoc = ISNULL(i.FromLoc, d.FromLoc), @TruckType = ISNULL(i.TruckType, d.TruckType), 
				@UM = ISNULL(i.UM, d.UM), @Zone = ISNULL(i.Zone, d.Zone), @Job = ISNULL(i.Job, d.Job), @PhaseGroup = ISNULL(i.PhaseGroup, d.PhaseGroup), 
				@Phase = ISNULL(i.HaulPhase, d.HaulPhase), @SaleType = ISNULL(i.SaleType, d.SaleType), @CustGroup = ISNULL(i.CustGroup, d.CustGroup), 
				@Customer = ISNULL(i.Customer, d.Customer), @CustJob = ISNULL(i.CustJob, d.CustJob), @CustPO = ISNULL(i.CustPO, d.CustPO), 
				@ToLoc = ISNULL(i.ToLoc, d.ToLoc), @SurchargeKeyID = ISNULL(i.SurchargeKeyID, d.SurchargeKeyID), @Changed = ISNULL(i.Changed, d.Changed),
				@Invoice = ISNULL(i.OldMSInv, d.OldMSInv), @PaymentType = ISNULL(i.PaymentType, d.PaymentType), @ParentTransType = ISNULL(i.BatchTransType, d.BatchTransType)
		  FROM	inserted i 
		  JOIN	bMSCO c WITH (NOLOCK) ON i.Co = c.MSCo 
		  JOIN deleted d ON d.KeyID = i.KeyID
              		
              		
   else
       begin
   			-- use a cursor to process each updated row
   			DECLARE bMSTB_update CURSOR LOCAL FAST_FORWARD FOR				
				SELECT	ISNULL(i.Co, d.Co), ISNULL(i.Mth, d.Mth), ISNULL(i.BatchId, d.BatchId),
						ISNULL(i.JCCo, d.JCCo), ISNULL(i.INCo, d.INCo), i.EMCo, c.GLCo,
						ISNULL(i.MatlTotal, 0), ISNULL(i.MatlUnits, 0), ISNULL(i.HaulTotal, 0), 
						ISNULL(i.HaulBasis, 0), ISNULL(i.Miles, 0), ISNULL(i.Loads, 0), 
						ISNULL(i.KeyID, d.KeyID), ISNULL(i.BatchSeq, d.BatchSeq), ISNULL(i.MatlGroup, d.MatlGroup), 
						ISNULL(i.Material, d.Material), ISNULL(i.FromLoc, d.FromLoc), ISNULL(i.TruckType, d.TruckType), 
						ISNULL(i.UM, d.UM), ISNULL(i.Zone, d.Zone), ISNULL(i.Job, d.Job), ISNULL(i.PhaseGroup, d.PhaseGroup), 
						ISNULL(i.HaulPhase, d.HaulPhase), ISNULL(i.SaleType, d.SaleType), ISNULL(i.CustGroup, d.CustGroup), 
						ISNULL(i.Customer, d.Customer), ISNULL(i.CustJob, d.CustJob), ISNULL(i.CustPO, d.CustPO), 
						ISNULL(i.ToLoc, d.ToLoc), ISNULL(i.SurchargeKeyID, d.SurchargeKeyID), ISNULL(i.Changed, d.Changed),
						ISNULL(i.OldMSInv, d.OldMSInv), ISNULL(i.PaymentType, d.PaymentType), ISNULL(i.BatchTransType, d.BatchTransType)
				  FROM	inserted i 
				  JOIN	bMSCO c WITH (NOLOCK) ON i.Co = c.MSCo 
				  JOIN	deleted d ON d.KeyID = i.KeyID
		  
   			open bMSTB_update
			set @opencursor = 1
		   
   			fetch next from bMSTB_update into @co, @mth, @batchid, @jcco, @inco, @emco, @msglco,
   	   										@MatlTotal, @MatlUnits, @HaulCharge, @HaulUnits, @Miles, @Loads, @KeyID,
   	   										@seq, @MatlGroup, @Material, @FromLoc, @TruckType, 
											@UM, @Zone, @Job, @PhaseGroup, @Phase, @SaleType,
											@CustGroup, @Customer, @CustJob, @CustPO, @ToLoc, @SurchargeKeyID, @Changed,
											@Invoice, @PaymentType, @ParentTransType
   			if @@fetch_status <> 0
				begin
   					select @errmsg = 'Cursor error'
   					goto error
   				end
	   end
  
  
   ------------------------
   -- INSERT CHECK START --
   ------------------------
   insert_HQCC_check:  
      
	-- add entry to HQ Close Control for MS Company GLCo
	if not exists(select top 1 1 from bHQCC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @msglco)
       begin
   			insert bHQCC (Co, Mth, BatchId, GLCo)
   			values (@co, @mth, @batchid, @msglco)
   		end
   
	-- get GL Company for Job sales
	if @jcco is not null
   		begin
   			select @glco = GLCo from bJCCO with (nolock) where JCCo = @jcco
   				if @@rowcount <> 0
   					begin
   						-- add entry to HQ Close Control for Job Sale
   						if not exists(select top 1 1 from bHQCC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
   							begin
   								insert bHQCC (Co, Mth, BatchId, GLCo)
   								values (@co, @mth, @batchid, @glco)
   							end
   					end
   		end	-- if @jcco is not null
   
	-- get GL Company for Inventory sales
	if @inco is not null
   		begin
   			select @glco = GLCo from bINCO with (nolock) where INCo = @inco
   			if @@rowcount <> 0
   				begin
   					-- add entry to HQ Close Control for Inventory Sale
   					if not exists(select top 1 1 from bHQCC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
   						begin
   							insert bHQCC (Co, Mth, BatchId, GLCo)
   							values (@co, @mth, @batchid, @glco)
   						end
   				end
   		end -- if @inco is not null
   
	-- get GL Compamy for Equipment use
	if @emco is not null
   		begin
   			select @glco = GLCo from bEMCO with (nolock) where EMCo = @emco
   			if @@rowcount <> 0
   				begin
   					-- add entry to HQ Close Control for Equipment use
   					if not exists(select top 1 1 from bHQCC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
   						begin
   							insert bHQCC (Co, Mth, BatchId, GLCo)
   							values (@co, @mth, @batchid, @glco)
   						end
   				end
   		end -- if @emco is not null
   		

	---------------------------------------------
	-- DELETE AND RECREATE SURCHARGE RECORD(S) --
	---------------------------------------------
	-- ISSUE: #129350 --
	-- CREATE SURCHARGES FOR CUSTOMER's WHEN PAYING ON ACCOUNT
	-- CREATE SURCHARGES FOR ALL JOB AND INVENTORY SALES
	IF (@SaleType = 'C' AND @PaymentType = 'A') OR (@SaleType in ('J','I'))
		BEGIN
			-- DO NOT PROCESS IF THERE ARE ANY SURCHARGE RECORDS IN MSTB
			IF NOT EXISTS(SELECT 1 FROM bMSTB WITH (NOLOCK) WHERE Co = @co AND Mth = @mth 
																		   AND BatchId = @batchid 
																		   AND SurchargeKeyID IS NOT NULL)
				BEGIN			
					
					IF (@SurchargeKeyID IS NULL) AND (@Invoice IS NULL)
						BEGIN
						
							-- MARK PROCESSED ASSOCIATED SURCHARGE RECORD(S) FOR DELETION --
							-- THIS WILL ALLOW DISTRIBUTIONS TO BE BACKED OUT --
							UPDATE bMSSurcharges
							   SET BatchTransType = 'D'
							 WHERE MSTBKeyID = @KeyID
								AND MSTDKeyID IS NOT NULL
								----TFS-48487                            
								AND APRef IS NULL
								AND MatlAPRef IS NULL                             
						
							-- DELETE ASSOCIATED SURCHARGE RECORD(S) --
							DELETE bMSSurcharges
							 WHERE MSTBKeyID = @KeyID
								AND BatchTransType <> 'D'
								----TFS-48487                            
								AND APRef IS NULL
								AND MatlAPRef IS NULL  

							-- DO NOT CREATE SURCHARGES WHEN PARENT TICKET IS SET TO D-Delete --
							IF @ParentTransType <> 'D'
								BEGIN

									-- DO NOT ATTEMPT TO CREATE SURCHARGES FOR ATTACHED EQUIPMENT --
									IF NOT EXISTS (SELECT 1 FROM bEMEM m WITH (NOLOCK) 
													JOIN Inserted i ON i.EMCo = m.EMCo AND i.Equipment = m.Equipment
													WHERE m.AttachToEquip IS NOT NULL)    
										BEGIN 
								
											----TFS-48487
											IF EXISTS(SELECT 1 FROM dbo.bMSTB WHERE KeyID = @KeyID AND OldAPRef IS NULL AND OldMatlAPRef IS NULL)
												BEGIN
  												---- ATTEMPT TO CREATE SURCHARGE RECORD(S) --
												EXEC @TempRCode = vspMSSurchargeAutoCreate @co, @mth, @batchid, @seq, @KeyID, 
														@MatlGroup, @Material, @FromLoc, @TruckType, @UM, @Zone, @jcco, @Job, @PhaseGroup, 
														@Phase, @SaleType, @CustGroup, @Customer, @CustJob, @CustPO, @inco, @ToLoc,
														@TempMsg output
												END                                              

											
											-- CHECK SUCCESS --
											IF @TempRCode = 1
												BEGIN
													SET @errmsg = 'AutoCreate Error: ' + ISNULL(@TempMsg, '')
													GOTO error
												END
								
										END -- IF NOT EXISTS ......
								END -- IF @ParentTransType <> 'D'
						END	-- IF @SurchargeKeyID IS NULL
				END -- IF NOT EXISTS .....
		END -- IF @PaymentType ....
	ELSE
		BEGIN
			-----------------------------------------------------------------
			-- CASH OR CREDIT CARD SALES - SURCHARGES ARE MANUALLY CREATED --
			-----------------------------------------------------------------
			
			-- MARK PROCESSED ASSOCIATED SURCHARGE RECORD(S) FOR DELETION --
			-- THIS WILL ALLOW DISTRIBUTIONS TO BE BACKED OUT --
			UPDATE bMSSurcharges
			   SET BatchTransType = 'D'
			 WHERE MSTBKeyID = @KeyID
			   AND MSTDKeyID IS NOT NULL
		
			-- DELETE ASSOCIATED SURCHARGE RECORD(S) --
			DELETE bMSSurcharges
			 WHERE MSTBKeyID = @KeyID
			   AND BatchTransType <> 'D'
			   
		END -- ELSE -- IF @PaymentType ....
		
		
	if @numrows > 1
		begin
			fetch next from bMSTB_update into @co, @mth, @batchid, @jcco, @inco, @emco, @msglco,
											@MatlTotal, @MatlUnits, @HaulCharge, @HaulUnits, @Miles, @Loads, @KeyID,
											@seq, @MatlGroup, @Material, @FromLoc, @TruckType, 
											@UM, @Zone, @Job, @PhaseGroup, @Phase, @SaleType,
											@CustGroup, @Customer, @CustJob, @CustPO, @ToLoc, @SurchargeKeyID, @Changed,
											@Invoice, @PaymentType, @ParentTransType
										
			-- CHECK NEXT RECORD --
			if @@fetch_status = 0 
				goto insert_HQCC_check
   
			-- NO MORE RECORDS - CLEAN UP CURSOR --
   			close bMSTB_update
   			deallocate bMSTB_update
   			set @opencursor = 0
   			
   		end -- if @numrows > 1
   
	-- set 'Changed' flag if anything changed
	if update(BatchTransType) or update(SaleDate) or update(FromLoc) or update(Ticket) or update(VendorGroup) 
   		or update(MatlVendor) or update(SaleType) or update(CustGroup) or update(Customer) or update(CustJob) 
   		or update(CustPO) or update(PaymentType) or update(CheckNo) or update(Hold) or update(JCCo) or update(Job) 
   		or update(PhaseGroup) or update(INCo) or update(ToLoc) or update(MatlGroup) or update(Material) or update(UM) 
   		or update(MatlPhase) or update(MatlJCCType) or update(GrossWght) or update(TareWght) or update(WghtUM) 
   		or update(MatlUnits) or update(UnitPrice) or update(ECM) or update(MatlTotal) or update(MatlCost)
   		or update(HaulerType) or update(HaulVendor) or update(Truck) or update(Driver) or update(EMCo) or update(Equipment)
   		or update(EMGroup) or update(PRCo) or update(Employee) or update(TruckType) or update(StartTime) 
   		or update(StopTime) or update(Loads) or update(Miles) or update(Hours) or update(Zone) or update(HaulCode) 
   		or update(HaulPhase) or update(HaulJCCType) or update(HaulBasis) or update(HaulRate) or update(HaulTotal) 
   		or update(PayCode) or update(PayBasis) or update(PayRate) or update(PayTotal) or update(RevCode) 
   		or update(RevBasis) or update(RevRate) or update(RevTotal) or update(TaxGroup) or update(TaxCode) 
   		or update(TaxType) or update(TaxBasis) or update(TaxTotal) or update(DiscBasis) or update(DiscRate) 
   		or update(DiscOff) or update(TaxDisc) or update(Void) or update(ShipAddress) or update(City) 
   		or update(State) or update(Zip) or update(Country)
   
   		begin  		
   			update bMSTB set Changed = 'Y'
   			from bMSTB b, inserted i
   			where b.Co = i.Co and b.Mth = i.Mth and b.BatchSeq = i.BatchSeq and b.BatchId = i.BatchId
   			
   		end -- if update(BatchTransType)
     
   
   return
   
   
   
   
	error:
   		if @opencursor = 1
   			begin
   				close bMSTB_update
   				deallocate bMSTB_update
   			end
   
   		select @errmsg = @errmsg + ' - cannot update MS Ticket Batch Detail!'
   		RAISERROR(@errmsg, 11, -1);
   		rollback transaction


GO

CREATE UNIQUE CLUSTERED INDEX [biMSTB] ON [dbo].[bMSTB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSTB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSTB].[Hold]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSTB].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSTB].[Void]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSTB].[OldHold]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSTB].[OldECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSTB].[OldVoid]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSTB].[OldVerifyHaul]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSTB].[Changed]'
GO
