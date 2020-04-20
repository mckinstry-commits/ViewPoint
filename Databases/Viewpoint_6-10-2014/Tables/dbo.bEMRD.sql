CREATE TABLE [dbo].[bEMRD]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[Trans] [dbo].[bTrans] NOT NULL,
[BatchID] [dbo].[bBatchID] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[Source] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[TransType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PostDate] [dbo].[bDate] NOT NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[JCPhase] [dbo].[bPhase] NULL,
[JCCostType] [dbo].[bJCCType] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[GLCo] [dbo].[bCompany] NULL,
[RevGLAcct] [dbo].[bGLAcct] NULL,
[ExpGLCo] [dbo].[bCompany] NULL,
[ExpGLAcct] [dbo].[bGLAcct] NULL,
[Memo] [dbo].[bItemDesc] NULL,
[Category] [dbo].[bCat] NULL,
[MeterTrans] [dbo].[bTrans] NULL,
[OdoReading] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bEMRD_OdoReading] DEFAULT ((0)),
[PreviousOdoReading] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bEMRD_PreviousOdoReading] DEFAULT ((0)),
[HourReading] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bEMRD_HourReading] DEFAULT ((0)),
[PreviousHourReading] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bEMRD_PreviousHourReading] DEFAULT ((0)),
[UM] [dbo].[bUM] NULL,
[WorkUnits] [dbo].[bUnits] NOT NULL,
[TimeUM] [dbo].[bUM] NULL,
[TimeUnits] [dbo].[bUnits] NOT NULL,
[Dollars] [dbo].[bDollar] NOT NULL,
[RevRate] [dbo].[bDollar] NOT NULL,
[UsedOnEquipCo] [dbo].[bCompany] NULL,
[UsedOnEquipGroup] [dbo].[bGroup] NULL,
[UsedOnEquipment] [dbo].[bEquip] NULL,
[UsedOnComponentType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UsedOnComponent] [dbo].[bEquip] NULL,
[EMCostTrans] [dbo].[bTrans] NULL,
[EMCostCode] [dbo].[bCostCode] NULL,
[EMCostType] [dbo].[bEMCType] NULL,
[WorkOrder] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[InUseBatchID] [dbo].[bBatchID] NULL,
[MSCo] [dbo].[bCompany] NULL,
[MSTrans] [dbo].[bTrans] NULL,
[FromLoc] [dbo].[bLoc] NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[INCo] [dbo].[bCompany] NULL,
[ToLoc] [dbo].[bLoc] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[PRCrew] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NULL,
[SMWorkOrder] [int] NULL,
[SMScope] [int] NULL,
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
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMRDd    Script Date: 8/28/99 9:37:19 AM ******/
   CREATE    trigger [dbo].[btEMRDd] on [dbo].[bEMRD] for Delete as
   

/*--------------------------------------------------------------
    *
    *  Delete trigger for EMRD
    *  Created By:  bc  04/26/99
    *  Modified by: bc  04/20/00 - added deletion of EMRB
    *				 TV 02/11/04 - 23061 added isnulls
    *				GP 05/26/09 - 133434 added new HQAT insert
    *
    *--------------------------------------------------------------*/
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
           @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int, @nullcnt int, @rcode int
   
   declare @emco bCompany, @mth bMonth, @emtrans bTrans, @equip bEquip, @emgroup bGroup, @revcode bRevCode,
           @emcosttrans bTrans, @transtype varchar(10), @actualdate bDate,
           @timeunits bHrs, @workunits bHrs,
           @dollars bDollar, @meter_trans bTrans,
           @catgy bCat, @usedonequipco bCompany
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   /* spin through records and adjust Monthly Revenue amounts and post to EMCD on type 'E' */
   select @emco = min(EMCo) from deleted
   while @emco is not null
     begin
   
     select @mth = min(Mth) from deleted where EMCo = @emco
     while @mth is not null
       begin
   
       select @emtrans = min(Trans) from deleted where EMCo = @emco and Mth = @mth
       while @emtrans is not null
         begin
   
         select @equip = Equipment, @emgroup = EMGroup, @revcode = RevCode, @meter_trans = MeterTrans,
                @emcosttrans = EMCostTrans, @transtype = TransType,
                @timeunits = TimeUnits, @workunits = WorkUnits, @dollars = Dollars, @usedonequipco = UsedOnEquipCo
         from deleted
         where EMCo = @emco and Mth = @mth and Trans = @emtrans
   
   
         /* record the monthly revenue for each posted revenue code */
         update bEMAR
         set ActualWorkUnits = ActualWorkUnits - @workunits,
             Actual_Time = Actual_Time - @timeunits,
             ActualAmt = ActualAmt - @dollars
         where EMCo = @emco and Month = @mth and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
   
         /* delete meter reading */
         if @meter_trans is not null
           begin
           delete bEMMR 
           where EMCo = @emco and Mth = @mth and EMTrans = @meter_trans and Equipment = @equip
           end
   
         /* if the transtype was an Equip or WO type, delete existing record in EMCD */
         if @transtype in ('E','W')
           begin
           delete bEMCD where EMCo = @usedonequipco and Mth = @mth and EMTrans = @emcosttrans
           end
   
         /* delete revenue breakdown code totals if they exists */
         delete bEMRB where EMCo = @emco and Mth = @mth and Trans = @emtrans
   
         select @emtrans = min(Trans) from deleted where EMCo = @emco and Mth = @mth and Trans > @emtrans
         end
   
       select @mth = min(Mth) from deleted where EMCo = @emco and Mth > @mth
       end
   
     select @emco = min(EMCo) from deleted where EMCo > @emco
     end
     
    -- Delete attachments if they exist. Make sure UniqueAttchID is not null
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
    from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
    where d.UniqueAttchID is not null    
   
   return
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete EMRD'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btEMRDi] on [dbo].[bEMRD] for INSERT as

/*--------------------------------------------------------------
*  Insert trigger for EMRD
*  Created By:  bc  04/27/00
*  Modified by: bc  04/07/99 EMAR routine/EMEM job update
*		GG 10/13/99 Allow null phase on Job type EMRD entries
*		GG 11/08/99 Allow null GL Expense Account - not always passed from PR
*		bc 06/06/00 get the EMMR transaction number from here now.
*		bc 06/20/00 changed the source written to EMMR
*		GG 10/28/00 - Added TransTypes 'C' and 'I', added Source 'MS'
*		MV 04/16/01 - Modified Validate Equipment - Added status 'D'
*		GG 06/20/01 - set bEMEM.UpdateYN = 'N' to avoid HQ auditing when updating last job
*		GG 08/02/01 - #14083 - do not update last job in EMEM if source = 'PR', done from bPRTB triggers
*		bc 08/08/01 - changed restriction that precedes update to EMEM
*		bc 09/04/01 - write out ExpGLCo to EMCD.  Issue # 14521
*		bc 09/18/01 - Further refinement to EMEM update
*		JM 1/29/02 - Reset UpdateYN to 'Y' - Ref GG 01/29/02 email.
*		SR 07/09/02 - 17738 pass @phasegroup to bspJCVPHASE
*		GF 08/01/2003 - issue #21933 - speed improvements
*		TV 11/11/03 17046 - Update JobLoc date in EMEM.
*		TV 01/17/04 17046 - Needs to use PostDate instead of Actual Date
*		TV TaxDay 2004 23255 - Move the update out of the trigger.
*		TV 10/12/04 25496 No update to EMMR when Miles do not change.
*		TJL 11/13/07 - Issue #120106, Add Usage Equipment# to EMCD (Cost Detail) transaction Description
*		TJL 12/19/07 - Issue #124391, Rev Equip Status must be A or D
*		mh 06/05/09 - Issue #24727
*		Dan So 07/31/09 - Issue: #134459 - wrapped LastUsedDate and @actualdate IN ISNULL's
*			GF 02/01/2010 - issue #132064 set previous hour meter and previous odometer to zero.
*		JB 4/27/10	Issue 138912	-	Fixed calculation of Current Total Odometer and Current Total Hours
*		JB 8/19/10	-	Issue #140964 - Fixed what was being inserted into EMMR to fix the zeroing out of meters.
*		GF 05/05/2013 TFS-49039
*
*
*--------------------------------------------------------------*/

------  basic declares for SQL Triggers ------
declare @rcode int, @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, @nullcnt int

declare @emco bCompany, @mth bMonth, @emtrans bTrans, @equip bEquip, @revcode bRevCode, @catgy bCat,
	@emgroup bGroup, @workunits bHrs, @timeunits bHrs, @dollars bDollar, @factor bHrs,
	@transtype varchar(10), @jcco bCompany, @job bJob, @phasegroup tinyint,@phase bPhase, @jcct bJCCType,
	@glco bCompany, @transacct bGLAcct, @offsetglco bCompany, @offsetacct bGLAcct,
	@usedonequipco bCompany, @usedonequip bEquip, @usedonequipgroup bGroup, @costcode bCostCode,
	@emct bEMCType, @workorder bWO, @woitem bItem, @actualdate bDate, @odoreading bHrs,
	@source varchar(10), @batchid bBatchID, @updatehours bYN, @convhours bHrs, @switch_a_roo varchar(5), 
	@meter_trans bTrans, @parameter char(1), @basis char(1), @msg varchar(255), @oldjob bJob, @joblocflag char, 
	@postdate bDate, @odomiles bHrs, @preodoreading bHrs

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @rcode = 0
     
     
     
-- Validate Used/Rev Equipment
select @validcnt = count(*) from bEMEM r with (nolock) 
JOIN inserted i ON i.EMCo = r.EMCo and i.Equipment = r.Equipment --and r.Status in ('A', 'D') --#24727
where r.Status in ('A', 'D') or (i.Source = 'PR' and i.TimeUnits <= 0 and i.Dollars <= 0 and i.WorkUnits <=0)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Equipment is Invalid or Status is InActive.'
	goto error
	end
     
-- Validate RevCode in EMRR based upon Category of Used/Usage Equipment
select @validcnt = count(*) from inserted i
join bEMEM e with (nolock) on i.EMCo = e.EMCo and i.Equipment = e.Equipment
join bEMRR r with (nolock) on r.EMCo = i.EMCo and r.RevCode = i.RevCode and r.EMGroup = i.EMGroup and r.Category = e.Category
if @validcnt <> @numrows
	begin
	select @errmsg = 'Revenue Code must be set up in Revenue Rates by Category in order to post '
	goto error
	end

     
-- Validate PRCo
select @validcnt = count(*) from bPRCO r JOIN inserted i ON i.PRCo = r.PRCo
select @validcnt2 = count(*) from inserted i Where i.PRCo is null
if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'PR Company is Invalid '
	goto error
	end

-- Validate Employee
select @validcnt = count(*) from bPREH r with (nolock) JOIN inserted i ON i.PRCo = r.PRCo and i.Employee = r.Employee
select @validcnt2 = count(*) from inserted i Where i.Employee is null
if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Employee Company is Invalid '
	goto error
	end
     
-- Validate GLCo 
select @validcnt = count(*) from bGLCO r JOIN inserted i ON i.GLCo = r.GLCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'GL Company is Invalid '
	goto error
	end

-- Validate ExpGLCo
select @validcnt = count(*) from bGLCO r JOIN inserted i ON i.ExpGLCo = r.GLCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Expense GL Company is Invalid '
	goto error
	end
     
-- Validate UM
select @validcnt = count(*) from bHQUM r with (nolock) JOIN inserted i ON i.UM = r.UM
select @validcnt2 = count(*) from inserted i Where i.UM is null
if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Unit of Measure is Invalid '
	goto error
	end

-- Validate TimeUM
select @validcnt = count(*) from bHQUM r with (nolock) JOIN inserted i ON i.TimeUM = r.UM
select @validcnt2 = count(*) from inserted i Where i.TimeUM is null
if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Time Unit of Measure is Invalid '
	goto error
	end
     
-- Validate used on equipment company (Cost/Repaired EMCo)
select @validcnt = count(*) from bEMCO r with (nolock) JOIN inserted i ON i.UsedOnEquipCo = r.EMCo
select @validcnt2 = count(*) from inserted i Where i.UsedOnEquipCo is null
if @validcnt + @validcnt2 <> @numrows
begin
select @errmsg = 'Used on Equipment Company is Invalid '
goto error
end

-- Validate used on equipment group	(Cost/Repaired Equip Group)
select @validcnt = count(*) from bHQGP r with (nolock) JOIN inserted i ON i.UsedOnEquipGroup = r.Grp
select @validcnt2 = count(*) from inserted i Where i.UsedOnEquipGroup is null
if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Used on Equipment Group is Invalid '
	goto error
	end
     

-- Validate component (Cost/Repaired component)
select @validcnt = count(*) from bEMEM r with (nolock) 
JOIN inserted i ON i.UsedOnEquipCo = r.EMCo and i.UsedOnComponent = r.Equipment and r.Status in ('A', 'D')
select @validcnt2 = count(*) from inserted i Where i.UsedOnComponent is null
if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Component is Invalid or Status is InActive.'
	goto error
	end
     

     
-- Validate customer group 
select @validcnt = count(*) from bHQGP r with (nolock) JOIN inserted i ON i.CustGroup = r.Grp
select @validcnt2 = count(*) from inserted i Where i.CustGroup is null
if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Customer group is Invalid '
	goto error
	end
     
-- Validate customer 
select @validcnt = count(*) from bARCM r with (nolock) JOIN inserted i ON i.CustGroup = r.CustGroup and i.Customer = r.Customer
select @validcnt2 = count(*) from inserted i Where i.Customer is null
if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Customer is Invalid '
	goto error
	end
     
     
          
if @numrows = 1
	-- Single Inserted row
	begin
	select @emco = EMCo, @mth = Mth, @emtrans = Trans, @equip = Equipment, @emgroup = EMGroup, @revcode = RevCode, 
		@workunits = WorkUnits, @timeunits = TimeUnits, @dollars = Dollars, @jcco = JCCo, @job = Job, 
		@phasegroup=PhaseGroup, @phase = JCPhase, @jcct = JCCostType, @transtype = TransType, @transacct = RevGLAcct, 
		@offsetacct = ExpGLAcct, @glco = GLCo, @offsetglco = ExpGLCo, @usedonequipco = UsedOnEquipCo, 
		@usedonequip = UsedOnEquipment, @usedonequipgroup = UsedOnEquipGroup, @costcode = EMCostCode, 
		@emct = EMCostType, @source = Source, @workorder = WorkOrder, @woitem = WOItem, @actualdate = ActualDate, 
		@odoreading = OdoReading, @batchid = BatchID, @postdate = PostDate, @preodoreading = PreviousOdoReading
	 from inserted
	end
else
	begin
	-- Multiple inserted rows.  Use a cursor to process each inserted row
	declare bEMRD_insert cursor FAST_FORWARD
	for select EMCo, Mth, Trans, Equipment, EMGroup, RevCode, WorkUnits, TimeUnits, Dollars, JCCo, Job, 
		PhaseGroup, JCPhase, JCCostType, TransType, RevGLAcct, ExpGLAcct, GLCo, ExpGLCo, UsedOnEquipCo, 
		UsedOnEquipment, UsedOnEquipGroup, EMCostCode, EMCostType, Source, WorkOrder, WOItem, ActualDate, 
		OdoReading, BatchID, PostDate, PreviousOdoReading
	from inserted


	open bEMRD_insert

	fetch next from bEMRD_insert into @emco, @mth, @emtrans, @equip, @emgroup, @revcode, @workunits, @timeunits, 
		@dollars, @jcco, @job, @phasegroup, @phase, @jcct, @transtype, @transacct, @offsetacct, @glco, @offsetglco, 
		@usedonequipco, @usedonequip, @usedonequipgroup, @costcode, @emct, @source, @workorder, @woitem, @actualdate, 
		@odoreading, @batchid, @postdate, @preodoreading

	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
	end

-- (SPECIAL Cost/Repaired item validation - More extensive then what was accomplished above) 
-- Each Single inserted record or each record of a multple insert will process the following code.

-- get the JobLoc flag from EMCO
select @joblocflag = JobLocationUpdate 
from bEMCO e
where EMCo = @emco
      
insert_check:
set @updatehours = null
set @factor = null
 
if @transtype = 'J' and @phase is not null
	begin
 	-- validate the Cost job/phase/costtype with a heavy hitting stored procedure
 	select @switch_a_roo = convert(varchar(5),@jcct)
 	exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup,@phase, @switch_a_roo, 'N', @msg = @errmsg output
 	if @rcode <> 0 goto error
 	end
     
if @transtype = 'E'
 	begin
	-- validate used on equipment (Cost/Repaired Equipment)
 	exec @rcode = dbo.bspEMEquipValUsage @usedonequipco, @usedonequip, 'Y', @errmsg = @errmsg output
 	if @rcode <> 0 goto error
 	end
     
if @transtype in ('E','W')
 	begin
 	-- validate the used on (Cost): group, cost code and cost type
 	select @switch_a_roo = convert(varchar(5),@emct)
 	exec @rcode = dbo.bspEMCostTypeCostCodeVal @usedonequipgroup, @costcode, @switch_a_roo, @msg = @errmsg output
 	if @rcode <> 0 goto error
 	end
     
if @transtype = 'W'
 	begin
 	-- validate the work order item
 	exec @rcode = dbo.bspEMWOItemVal @usedonequipco, @workorder, @woitem, @msg = @errmsg output
 	if @rcode <> 0 goto error
 	end

--  End SPECIAL Cost/Repaired item validation

-- validate the transaction gl account
if @transacct is not null
 	begin
 	exec @rcode = dbo.bspGLACfPostable @glco, @transacct, 'E', @errmsg output
 	if @rcode <> 0 goto error
 	end
 
-- validate the offset gl account
if @offsetacct is not null
 	begin
 	SELECT @parameter = CASE WHEN @source = 'SM' THEN 'S' WHEN @transtype = 'J' THEN 'J' ELSE 'E' END
 	exec @rcode = bspGLACfPostable @offsetglco, @offsetacct, @parameter, @errmsg output
 	if @rcode <> 0 goto error
 	end

-- SPECIAL UPDATES section
     
-- retrieve the update meter flag
select @catgy = Category from bEMEM with (nolock) where EMCo = @emco and Equipment = @equip
select @updatehours = UpdtHrMeter from bEMRH with (nolock)
where EMCo = @emco and EMGroup = @emgroup and  Equipment = @equip and RevCode = @revcode
if @@rowcount = 0
	begin
	select @updatehours = UpdtHrMeter from bEMRR with (nolock)
	where EMCo = @emco and EMGroup = @emgroup and Category = @catgy and RevCode = @revcode
	end
     
-- get the rev code information
select @basis = Basis, @factor = HrsPerTimeUM from bEMRC with (nolock)
where EMGroup = @emgroup and RevCode = @revcode
     
-- set the new hours for time units using the time factor from EMRC
select @convhours = case @updatehours when 'Y' then isnull(@factor,0) * @timeunits else 0 end
SELECT @odomiles = CASE WHEN (@odoreading = 0) THEN 0 ELSE @odoreading - @preodoreading END
     
----- meter update section ------
if isnull(@odomiles,0) <> 0 or @convhours <> 0
	begin
	exec @meter_trans = dbo.bspHQTCNextTrans 'bEMMR', @emco, @mth, @msg output
	if @meter_trans = 0
		begin
		select @errmsg =  @msg
		goto error
		end
     
 	-- update bEMRD with MeterTrans
 	update bEMRD
 	set MeterTrans = @meter_trans
 	where EMCo = @emco and Mth = @mth and Trans = @emtrans
 	if @@rowcount = 0
 		begin
 		select @errmsg = 'Error updating EMRD with meter transaction #'
 		goto error
 		end
     
 	-- update meter readings - 140964, updated this insert to 
 	-- work better with EMMR insert trigger and stop zeroing out fields.
 	INSERT bEMMR 
 	(
 		EMCo, 
 		Mth, 
 		EMTrans, 
 		BatchId, 
 		Equipment, 
 		PostingDate, 
 		ReadingDate, 
 		[Source],
		PreviousHourMeter, 
		CurrentHourMeter, 
		PreviousTotalHourMeter, 
		CurrentTotalHourMeter, 
		[Hours],
		PreviousOdometer, 
		CurrentOdometer, 
		CurrentTotalOdometer, 
		PreviousTotalOdometer,
		Miles, 
		InUseBatchID
 	)
 	SELECT 
 		@emco, 
 		@mth, 
 		@meter_trans, 
		@batchid, 
		@equip, 
		@postdate, 
		@actualdate, 
		@source,
		0,
		HourReading + @convhours,
		0,
		CASE WHEN (@actualdate < ReplacedHourDate) THEN @convhours + HourReading ELSE @convhours + HourReading + ReplacedHourReading END,
		@convhours, 
		0,
		OdoReading + @odomiles,
		CASE WHEN (@actualdate < ReplacedOdoDate) THEN OdoReading + @odomiles ELSE @preodoreading + @odomiles + ReplacedOdoReading END,
		0,
		@odomiles,
		NULL
 	FROM bEMEM WHERE EMCo = @emco AND Equipment = @equip
 	END
     
     
-- record the monthly revenue for each posted revenue code
update bEMAR set ActualWorkUnits = ActualWorkUnits + @workunits,
              Actual_Time = Actual_Time + @timeunits,
              ActualAmt = ActualAmt + @dollars
where EMCo = @emco and Month = @mth and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
if @@rowcount = 0
	begin
	insert bEMAR(EMCo, Equipment, RevCode, Month, EMGroup, AvailableHrs, EstWorkUnits, EstTime, 
			EstAmt, ActualWorkUnits, Actual_Time, ActualAmt)
	values (@emco, @equip, @revcode, @mth, @emgroup, 0, 0, 0, 0, @workunits, @timeunits, @dollars)
	end
     
-- insert EMCD with component information.  The gl accts are reversed.
insert into bEMCD(EMCo, Mth, EMTrans, BatchId, EMGroup, Equipment, ComponentTypeCode, Component,
	WorkOrder, WOItem, CostCode, EMCostType, PostedDate, ActualDate, Source, EMTransType, 
	Description,
	GLCo, GLTransAcct, GLOffsetAcct, ReversalStatus, PRCo, UM, Units, Dollars, UnitPrice, 
	CurrentHourMeter, CurrentTotalHourMeter, CurrentOdometer, CurrentTotalOdometer)
select UsedOnEquipCo, Mth, EMCostTrans, BatchID, UsedOnEquipGroup, UsedOnEquipment, UsedOnComponentType, 
	UsedOnComponent, WorkOrder, WOItem, EMCostCode, EMCostType, PostDate, ActualDate, Source, 'Usage', 
	'Equipment Used: ' + @equip,
	GLCo, ExpGLAcct, RevGLAcct, 0, PRCo,
	case @basis when 'H' then TimeUM else UM end,
	case @basis when 'H' then TimeUnits else WorkUnits end,
	Dollars, 0, HourReading + @convhours, 0, @odoreading, 0
from inserted
where EMCo = @emco and Mth = @mth and Trans = @emtrans and TransType in ('E','W') and EMCostTrans is not null
     
     
-- ISSUE: #134459 --
--Update the Last Used date everytime usage is post
update bEMEM
set LastUsedDate = @actualdate
where EMCo = @emco and Equipment = @equip and ISNULL(LastUsedDate,'1900-01-01') < ISNULL(@actualdate,'')



if @numrows > 1
	-- Only applies when multiple records have been inserted.  See above
	begin
	fetch next from bEMRD_insert into @emco, @mth, @emtrans, @equip, @emgroup, @revcode, @workunits, @timeunits, 
		@dollars, @jcco, @job, @phasegroup, @phase, @jcct, @transtype, @transacct, @offsetacct, @glco, @offsetglco, 
		@usedonequipco, @usedonequip, @usedonequipgroup, @costcode, @emct, @source, @workorder, @woitem, @actualdate, 
		@odoreading, @batchid

	if @@fetch_status = 0
		goto insert_check
	else
		begin
		close bEMRD_insert
		deallocate bEMRD_insert
		end
	end

return
 
error:
select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMRD'

RAISERROR(@errmsg, 11, -1);
rollback transaction
     
     
     
     
     
     
    
    
    
    
    
    
    
    
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btEMRDu] on [dbo].[bEMRD] for Update as

/*--------------------------------------------------------------
*  Update trigger for EMRD
*  Created:  bc 04/27/99
*  Modified: GG 10/13/99 - Allow null phase on Job type EMRD entries
*		bc 01/17/00 - added a mileage update to EMMR
*		GG 10/28/00 - Added TransTypes 'C' and 'I', added Source 'MS'
*		GG 02/14/01 - allow null GL Expense Account
*		GG 06/20/01 - set bEMEM.UpdateYN = 'N' to avoid HQ auditing when updating last job
*		GG 08/02/01 - #14083 - do not update last job in EMEM if source = 'PR', done from bPRTB triggers
*		bc 08/08/01 - changed the restriction that precedes the update to EMEM
*		bc 09/04/01 - update EMCD with @offsetglco.  Issue # 14521
*		bc 09/18/01 - further refinement to the EMEM update
*		JM 01/29/02 - Reset UpdateYN to 'Y' - Ref GG 01/29/02 email.
*		SR 07/09/02 - 17738 pass @phasegroup to bspJCVCOSTTYPE
*		bc 03/06/03 - # 20616
*		TV 09/18/03 - 21653- Only null Location when Job has changed.
*		TV 10/29/03 22780 - seperated out the Active Equipment and the RevCode validation for clarity.
*		TV 01/17/04 17046 - Needs to use PostDate instead of Actual Date
*		TV 02/11/04 - 23061 added isnulls
*		TV 23978 03/09/04 did not take into consideration a change in date.
*		TV 04/14/04 23255 - Update EMEM
*		TJL 11/13/07 - Issue #120106, Add Usage Equipment# to EMCD (Cost Detail) transaction Description
*		TJL 12/19/07 - Issue #124391, Rev Equip Status must be A or D
*		JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
*		JB 4/27/10	Issue 138912	-	Fixed calculation of Current Total Odometer and Current Total Hours
*		JB 8/20/10	Issue 140964	-	Fixed updated postings, when set to 0, odometer changes were ignored.
*		GF 05/05/2013 TFS-49039
*
*--------------------------------------------------------------*/
    
declare @numrows int, @errmsg varchar(255),
		@validcnt int, @validcnt2 int, @nullcnt int

declare @emco bCompany, @mth bMonth, @emtrans bTrans, @equip bEquip, @emgroup bGroup, @revcode bRevCode,
	@emcosttrans bTrans, @batchid bBatchID, @inusebatch bBatchID, @oldinusebatch bBatchID,
	@componenttype varchar(10), @component bEquip,
	@costcode bCostCode, @emct bEMCType, @postdate bDate, @actualdate bDate,
	@source bSource, @transtype varchar(10),
	@glco bCompany, @expglacct bGLAcct, @revglacct bGLAcct, @prco bCompany,
	@timeum bUM, @um bUM, @meter_trans bTrans, @timeunits bHrs, @workunits bHrs,
	@dollars bDollar, @revrate bDollar, @hourreading bHrs, @odoreading bHrs,
	@factor bHrs, @updatehours bYN, @convhours bHrs, @emar_hours bHrs, @catgy bCat,
	@joblocflag char

declare @jcco bCompany, @job bJob, @phasegroup tinyint,@phase bPhase, @jcct bJCCType, @workorder bWO,
    @woitem bItem, @usedonequipco bCompany, @usedonequipgroup bGroup, @usedonequip bEquip, @offsetglco bCompany

declare @oldequip bEquip, @oldrevcode bRevCode, @oldtranstype varchar(10), @oldactualdate bDate,
	@oldtimeunits bHrs, @oldworkunits bHrs, @olddollars bDollar, @oldhourreading bHrs, @oldodoreading bHrs,
	@oldupdatehours bYN, @oldcatgy bCat, @oldfactor bHrs, @oldconvhours bHrs,
	@oldusedonequipco bCompany, @oldusedonequipgroup bGroup, @oldusedonequip bEquip, @oldjob bJob

declare @rcode int, @basis char(1), @switch_a_roo varchar(5), @parameter char(1),
	@posthours bHrs, @postunits bHrs, @postamt bDollar, @miles bHrs
    
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

	--If the only column that changed was UniqueAttachID, then skip validation.        
	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bEMRD', 'UniqueAttchID') = 1
	BEGIN 
		goto Trigger_Skip
	END    

----TFS-49039  
SELECT @validcnt = COUNT(*) FROM dbo.bEMEM EMEM JOIN inserted i ON i.EMCo = EMEM.EMCo AND i.Equipment = EMEM.Equipment and EMEM.ChangeInProgress = 'Y'
IF @validcnt = @numrows goto Trigger_Skip

/* see if any fields have changed that is not allowed */
if update(Mth) or update(Trans)
	begin
	select @validcnt = count(*) from inserted i
	JOIN deleted d ON d.EMCo = i.EMCo and d.Mth=i.Mth and d.Trans=i.Trans
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Primary key fields may not be changed'
		GoTo error
		End
	end




     /* Validate Used/Rev Equipment */
     if update(Equipment)
		 begin
		 select @validcnt = count(*) from inserted i
		 join bEMEM e on i.EMCo = e.EMCo and i.Equipment = e.Equipment and e.Status in ('A', 'D')
		 --join bEMRR r on r.EMCo = i.EMCo and r.RevCode = i.RevCode and r.EMGroup = i.EMGroup and r.Category = e.Category
		 if @validcnt <> @numrows
			begin
			select @errmsg = 'Equipment is Invalid or Status is InActive.'
			goto error
			end
		 -- Validate RevCode in EMRR based upon Category of Used/Usage Equipment
		 select @validcnt = count(*) from inserted i
		 join bEMEM e on i.EMCo = e.EMCo and i.Equipment = e.Equipment --and e.Status = 'A'
		 join bEMRR r on r.EMCo = i.EMCo and r.RevCode = i.RevCode and r.EMGroup = i.EMGroup and r.Category = e.Category
		 if @validcnt <> @numrows
			begin
			select @errmsg = 'Revenue Code must be set up in Revenue Rates by Category in order to post '
			goto error
			end
		 end


     /* Validate PRCo */
     if update(PRCo)
		 begin
		 select @validcnt = count(*) from bPRCO r JOIN inserted i ON i.PRCo = r.PRCo
		 select @validcnt2 = count(*) from inserted i Where i.PRCo is null
		 if @validcnt + @validcnt2 <> @numrows
			begin
			select @errmsg = 'PR Company is Invalid '
			goto error
			end
		 end

     /* Validate Employee */
     if update(Employee)
		 begin
		 select @validcnt = count(*) from bPREH r JOIN inserted i ON i.PRCo = r.PRCo and i.Employee = r.Employee
		 select @validcnt2 = count(*) from inserted i Where i.Employee is null
		 if @validcnt + @validcnt2 <> @numrows
			begin
			select @errmsg = 'Employee Company is Invalid '
			goto error
			end
		 end

     /* Validate GLCo */
     if update(GLCo)
		 begin
		 select @validcnt = count(*) from bGLCO r JOIN inserted i ON i.GLCo = r.GLCo
		 if @validcnt <> @numrows
			begin
			select @errmsg = 'GL Company is Invalid '
			goto error
			end
		 end

     /* Validate ExpGLCo */
     if update(ExpGLCo)
		 begin
		 select @validcnt = count(*) from bGLCO r JOIN inserted i ON i.ExpGLCo = r.GLCo
		 if @validcnt <> @numrows
			begin
			select @errmsg = 'Expense GL Company is Invalid '
			goto error
			end
		 end

     /* Validate UM */
     if update(UM)
		 begin
		 select @validcnt = count(*) from bHQUM r JOIN inserted i ON i.UM = r.UM
		 select @validcnt2 = count(*) from inserted i Where i.UM is null
		 if @validcnt + @validcnt2 <> @numrows
			begin
			select @errmsg = 'Unit of Measure is Invalid '
			goto error
			end
		 end

     /* Validate TimeUM */
     if update(TimeUM)
		 begin
		 select @validcnt = count(*) from bHQUM r JOIN inserted i ON i.TimeUM = r.UM
		 select @validcnt2 = count(*) from inserted i Where i.TimeUM is null
		 if @validcnt + @validcnt2 <> @numrows
			begin
			select @errmsg = 'Time Unit of Measure is Invalid '
			goto error
			end
		 end

     /* Validate used on equipment company (Cost/Repaired EMCo) */
     if update(UsedOnEquipCo)
		 begin
		 select @validcnt = count(*) from bEMCO r JOIN inserted i ON i.UsedOnEquipCo = r.EMCo
		 select @validcnt2 = count(*) from inserted i Where i.UsedOnEquipCo is null
		 if @validcnt + @validcnt2 <> @numrows
			begin
			select @errmsg = 'Used on Equipment Company is Invalid '
			goto error
			end
		 end

     /* Validate used on equipment group	(Cost/Repaired Equip Group) */
     if update(UsedOnEquipGroup)
		 begin
		 select @validcnt = count(*) from bHQGP r JOIN inserted i ON i.UsedOnEquipGroup = r.Grp
		 select @validcnt2 = count(*) from inserted i Where i.UsedOnEquipGroup is null
		 if @validcnt + @validcnt2 <> @numrows
			begin
			select @errmsg = 'Used on Equipment Group is Invalid '
			goto error
			end
		 end


     /* Validate component (Cost/Repaired component) */
     if update(UsedOnComponent)
		 begin
		 select @validcnt = count(*) from bEMEM r 
		 JOIN inserted i ON i.UsedOnEquipCo = r.EMCo and i.UsedOnComponent = r.Equipment and r.Status in ('A', 'D')
		 select @validcnt2 = count(*) from inserted i Where i.UsedOnComponent is null
		 if @validcnt + @validcnt2 <> @numrows
			begin
			select @errmsg = 'Component is Invalid or Status is InActive.'
			goto error
			end
		 end



     /* Validate work order */
     if update(CustGroup)
		 begin
		 select @validcnt = count(*) from bHQGP r JOIN inserted i ON i.CustGroup = r.Grp
		 select @validcnt2 = count(*) from inserted i Where i.CustGroup is null
		 if @validcnt + @validcnt2 <> @numrows
			begin
			select @errmsg = 'Customer group is Invalid '
			goto error
			end
		 end

     /* Validate work order */
     if update(Customer)
		 begin
		 select @validcnt = count(*) from bARCM r JOIN inserted i ON i.CustGroup = r.CustGroup and i.Customer = r.Customer
		 select @validcnt2 = count(*) from inserted i Where i.Customer is null
		 if @validcnt + @validcnt2 <> @numrows
			begin
			select @errmsg = 'Customer is Invalid '
			goto error
			end
		 end


/* if the InUseBatchID column is being updated, then all that is happening is that a
record is being added into the batch table. in which case skip the following section
of accounting processing 

if MeterTrans is being updated, it's being done from the EMRD insert trigger.
So skip the following section
*/
if update(InUseBatchID) or update(MeterTrans)
	begin
	goto SkipLoop
	end
    
/* spin through records and adjust Monthly Revenue amounts and post to EMCD on type 'E' */
select @emco = min(EMCo) from inserted
while @emco is not null
	begin
	select @mth = min(Mth) from inserted where EMCo = @emco
	while @mth is not null
         begin
         select @emtrans = min(Trans) from inserted where EMCo = @emco and Mth = @mth
         while @emtrans is not null
			begin
    
			/* initialize the readings for the new record */
			select @odoreading = null, @hourreading = null, @inusebatch = null, @oldinusebatch = null
    
			select @equip = Equipment, @emgroup = EMGroup, @revcode = RevCode, @actualdate = ActualDate,
				@emcosttrans = EMCostTrans, @batchid = BatchID,
				@componenttype = UsedOnComponentType, @component = UsedOnComponent,
				@costcode = EMCostCode, @emct = EMCostType, @postdate = PostDate, @actualdate = ActualDate,
				@source = Source, @transtype = TransType,
				@glco = GLCo, @expglacct = ExpGLAcct, @revglacct = RevGLAcct, @prco = PRCo,
				@timeum = TimeUM, @um = UM, @meter_trans = MeterTrans,
				@timeunits = TimeUnits, @workunits = WorkUnits,
				@dollars = Dollars, @revrate = RevRate, @hourreading = HourReading, @odoreading = isnull(OdoReading,0),
				/* read in variables needed for further validation */
				@jcco = JCCo, @job = Job, @phasegroup=PhaseGroup, @phase = JCPhase, @jcct = JCCostType,
				@workorder = WorkOrder, @woitem = WOItem, @usedonequipco = UsedOnEquipCo,
				@usedonequipgroup = UsedOnEquipGroup, @usedonequip = UsedOnEquipment, @offsetglco = ExpGLCo
			from inserted
			where EMCo = @emco and Mth = @mth and Trans = @emtrans
    
			/* get the old values */
			select @oldequip = Equipment, @oldrevcode = RevCode, @oldtranstype = TransType, @oldactualdate = ActualDate,
				@oldtimeunits = TimeUnits, @oldworkunits = WorkUnits,
				@olddollars = Dollars, @oldhourreading =  HourReading, @oldodoreading = isnull(OdoReading,0),
				@oldusedonequipco = UsedOnEquipCo, @oldusedonequipgroup = UsedOnEquipGroup,
				@oldusedonequip = UsedOnEquipment, @oldjob = Job
			from deleted
			where EMCo = @emco and Mth = @mth and Trans = @emtrans
   
			-- (SPECIAL Cost/Repaired item validation - More extensive then what was accomplished above) 

			--get the JobLoc flag from EMCO
			select @joblocflag = JobLocationUpdate 
			from bEMCO e
			where EMCo = @emco
    
			/* do some validation that requires the specific values stored in each record */
			if @transtype = 'J' and @phase is not null
				begin
				/* validate the job/phase/costtype with a heavy hitting stored procedure */
				select @switch_a_roo = convert(varchar(5),@jcct)
				exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup,@phase, @switch_a_roo, 'N', @msg = @errmsg output
				if @rcode <> 0 goto error
				end
    
			if @transtype = 'E'
				begin
				/* validate the used on equip */
				exec @rcode = dbo.bspEMEquipValUsage @usedonequipco, @usedonequip, 'Y', @errmsg = @errmsg output
				if @rcode <> 0 goto error
				end
   
			if @transtype in ('E','W')
				begin
				/* validate the used on : group, cost code and cost type */
				select @switch_a_roo = convert(varchar(5),@emct)
				exec @rcode = bspEMCostTypeCostCodeVal @usedonequipgroup, @costcode, @switch_a_roo, @msg = @errmsg output
				if @rcode <> 0 goto error
				end
    
			if @transtype = 'W'
				begin
				/* validate the work order item */
				exec @rcode = dbo.bspEMWOItemVal @usedonequipco, @workorder, @woitem, @msg = @errmsg output
				if @rcode <> 0 goto error
				end

--  End SPECIAL Cost/Repaired item validation

			/* validate the transaction gl account */
			if @revglacct is not null
				begin
				exec @rcode = dbo.bspGLACfPostable @glco, @revglacct, 'E', @errmsg output
				if @rcode <> 0 goto error
     			end
    
			/* validate the offset gl account */
    		if @expglacct is not null
    	  		begin
           		select @parameter = case @transtype when 'J' then 'J' else 'E' end
           		exec @rcode = dbo.bspGLACfPostable @offsetglco, @expglacct, @parameter, @errmsg output
           		if @rcode <> 0 goto error
    			end
    
    
			/**************
			* NEW VALUES *
			*************/
			select @catgy = Category
			from bEMEM
			where EMCo = @emco and Equipment = @equip
    
			/* retrieve the update meter flag */
			select @updatehours = null
			select @updatehours = UpdtHrMeter from EMRH where EMCo = @emco and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
			if @@rowcount = 0
				begin
				select @updatehours = UpdtHrMeter from EMRR where EMCo = @emco and EMGroup = @emgroup and Category = @catgy and RevCode = @revcode
				end
    
			/* get the rev code information */
			select @factor = null
			select @basis = Basis, @factor = HrsPerTimeUM
			from bEMRC
			where EMGroup = @emgroup and RevCode = @revcode
    
			/* convert time units */
			select @convhours = case @updatehours when 'Y' then @timeunits * isnull(@factor,0) else 0 end
    
			/**************
			* OLD VALUES *
			*************/
			select @oldcatgy = Category
			from bEMEM
			where EMCo = @emco and Equipment = @oldequip
    
			/* retrieve the update meter flag */
			select @oldupdatehours = null
			select @oldupdatehours = UpdtHrMeter 
			from bEMRH 
			where EMCo = @emco and EMGroup = @emgroup and Equipment = @oldequip and RevCode = @oldrevcode
			if @@rowcount = 0
				begin
				select @oldupdatehours = UpdtHrMeter 
				from bEMRR 
				where EMCo = @emco and EMGroup = @emgroup and Category = @oldcatgy and RevCode = @oldrevcode
				end
    
			/* get the rev code information */
			select @oldfactor = null
			select @oldfactor = HrsPerTimeUM
			from bEMRC
			where EMGroup = @emgroup and RevCode = @oldrevcode

			/* convert time units */
			select @oldconvhours = case @oldupdatehours when 'Y' then @oldtimeunits * isnull(@oldfactor,0) else 0 end

			/* set the posting variable equal to the difference of the old and new values */
			select @posthours = @convhours - @oldconvhours, 
				@postunits = @workunits - @oldworkunits, 
				@postamt = @dollars - @olddollars,
				@miles = @odoreading - @oldodoreading, 
				@emar_hours = @timeunits - isnull(@oldtimeunits,0)
    
    
			-- SPECIAL UPDATES section

			/* 
              Record the monthly revenue for each posted revenue code 
              There sre two separate sections for this.  
              One for when the Equip and RevCode have not changed and one section for when either of them has changed.
    
              This section is not as efficient as i would prefer but because EMAR does not store EMRD's Trans #,
              it is the best we can do
			*/
    
			--Section for when Equipment and Revenue Code have not changed
			if @equip = @oldequip and @revcode = @oldrevcode
				begin
				update bEMAR
				set ActualWorkUnits = ActualWorkUnits + @postunits, 
					Actual_Time = Actual_Time + @emar_hours,
					ActualAmt = ActualAmt + @postamt
				where EMCo = @emco and Month = @mth and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
				if @@rowcount = 0
					begin
					insert into bEMAR(EMCo, Equipment, RevCode, Month, EMGroup,
						AvailableHrs, EstWorkUnits, EstTime, EstAmt, ActualWorkUnits, Actual_Time, ActualAmt)
					values (@emco, @equip, @revcode, @mth, @emgroup,
						0, 0, 0, 0, @postunits, @emar_hours, @postamt)
					end
				end
    
			--Section for when either Equipment or Revenue Code have changed
			if @equip <> @oldequip or @revcode <> @oldrevcode
				begin
				--back out the old amounts
				update bEMAR
				set ActualWorkUnits = ActualWorkUnits - @oldworkunits, 
				 Actual_Time = Actual_Time - isnull(@oldtimeunits,0),
				 ActualAmt = ActualAmt - @olddollars
				where EMCo = @emco and Month = @mth and EMGroup = @emgroup and Equipment = @oldequip and RevCode = @oldrevcode
    
				--update/insert the new
				update bEMAR
				set ActualWorkUnits = ActualWorkUnits + @workunits, 
					Actual_Time = Actual_Time + @timeunits,
					ActualAmt = ActualAmt + @dollars
				where EMCo = @emco and Month = @mth and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
				if @@rowcount = 0
					begin
					insert into bEMAR(EMCo, Equipment, RevCode, Month, EMGroup,
						AvailableHrs, EstWorkUnits, EstTime, EstAmt, ActualWorkUnits, Actual_Time, ActualAmt)
					values (@emco, @equip, @revcode, @mth, @emgroup,
						0, 0, 0, 0, @workunits, @timeunits, @dollars)
					end
				end

			/**** meter update section ****/
			-- if (@odoreading is not null and @odoreading <> 0 and @odoreading <> @oldodoreading) or
			--    (@convhours <> @oldconvhours)
   
   			--TV 23978 03/09/04 did not take into consideration a change in date. 
   	 		IF (ISNULL(@odoreading,0) <> @oldodoreading) OR
          		(@convhours <> @oldconvhours) OR (@actualdate <> @oldactualdate)
				BEGIN
				-- Update EMMR
				UPDATE mr
				SET 
					PostingDate = @postdate, 
					ReadingDate = @actualdate,
					CurrentHourMeter = CurrentHourMeter + @posthours, 
					CurrentTotalHourMeter = CASE WHEN (@actualdate < em.ReplacedHourDate) THEN CurrentTotalHourMeter + @posthours 
											ELSE CurrentTotalHourMeter + @posthours + em.ReplacedHourReading END,
					[Hours] = [Hours] + @posthours,
					CurrentOdometer = CASE WHEN (@odoreading = 0) THEN CurrentOdometer - Miles ELSE @odoreading END,
					CurrentTotalOdometer =	CASE WHEN (@odoreading = 0) THEN CurrentTotalOdometer - Miles
											ELSE 
												CASE WHEN (@actualdate < em.ReplacedOdoDate) THEN @odoreading
												ELSE @odoreading + em.ReplacedOdoReading END
											END,
					Miles = CASE WHEN (@odoreading = 0) THEN 0 ELSE Miles + @miles END					
				FROM bEMMR mr 
				INNER JOIN bEMEM em ON mr.EMCo = em.EMCo AND mr.Equipment = em.Equipment
				WHERE 
					mr.EMCo = @emco 
					AND mr.Mth = @mth 
					AND mr.EMTrans = @meter_trans
					AND mr.Equipment = @equip
				END
    
			/* update EMCD with component information.  The gl accts are reversed. */
			if @transtype in ('E','W') and @emcosttrans is not null
				begin
				update bEMCD
				set BatchId = @batchid, EMGroup = @usedonequipgroup,
					Equipment = @usedonequip, ComponentTypeCode = @componenttype, Component = @component,
					WorkOrder = @workorder, WOItem = @woitem, CostCode = @costcode, EMCostType = @emct, PostedDate = @postdate, ActualDate = @actualdate,
					Source = @source, EMTransType = 'Usage', 
					Description = 'Equipment Used: ' + @equip,
					GLCo = @glco, GLTransAcct = @expglacct,
					GLOffsetAcct = @revglacct, PRCo = @prco,
					UM = case @basis when 'H' then @timeum else @um end,
					Units = case @basis when 'H' then @timeunits else @postunits end,
					Dollars = Dollars + @postamt, CurrentHourMeter = @hourreading, CurrentOdometer = @odoreading
				where EMCo = @usedonequipco and Mth = @mth and EMTrans = @emcosttrans
				end
   		
   			--Update the Last Used date everytime usage is post Done through another proc bspEMEMJobLocDateUpdate
   			/*update bEMEM
       		set LastUsedDate = @actualdate
     		where EMCo = @emco and Equipment = @equip and LastUsedDate < @actualdate*/

			/* if the transtype has been changed from an 'E' to something else, delete existing record in EMCD */
			if @oldtranstype = 'E' and @transtype <> 'E'
				begin
				delete bEMCD 
				where EMCo = @oldusedonequipco and Mth = @mth and EMTrans = @emcosttrans
				end
    		
    
			if @oldtranstype = 'J' and
				@transtype <> 'J' and
					exists(select * from bEMEM where EMCo = @emco and Equipment = @equip and (JobDate is not null and JobDate <= @oldactualdate))
					and not exists(select * from bEMLH where EMCo = @emco and Equipment = @equip and DateIn >= @oldactualdate)
				begin
				update bEMEM
				set JCCo = null, Job = null, JobDate = null, 
				Location = case when @job <> @oldjob then null else Location end, UpdateYN = 'N' -- avoid HQ auditing
				where EMCo = @emco and Equipment = @equip
    	
				/* Reset UpdateYN to 'Y' - Ref GG 01/29/02 email. */
    			update bEMEM 
				set UpdateYN = 'Y' 
				where EMCo = @emco and Equipment = @equip
				end
    
			select @emtrans = min(Trans) from inserted where EMCo = @emco and Mth = @mth and Trans > @emtrans
			end
    
		select @mth = min(Mth) from inserted where EMCo = @emco and Mth > @mth
		end
    
	select @emco = min(EMCo) from inserted where EMCo > @emco
	end

SkipLoop:
    
Trigger_Skip:    
    
return
    
error:
select @errmsg = isnull(@errmsg,'') + ' - cannot update EMRD'

RAISERROR(@errmsg, 11, -1);
rollback transaction
    
    
    
    
    
    
    
    
    
    
    
    
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bEMRD] WITH NOCHECK ADD CONSTRAINT [CK_bEMRD_Source] CHECK (([Source]='SM' OR [Source]='MS' OR [Source]='PR' OR [Source]='EMRev'))
GO
ALTER TABLE [dbo].[bEMRD] WITH NOCHECK ADD CONSTRAINT [CK_bEMRD_TransType] CHECK (([TransType]='I' OR [TransType]='C' OR [TransType]='W' OR [TransType]='X' OR [TransType]='E' OR [TransType]='J'))
GO
CREATE UNIQUE CLUSTERED INDEX [biEMRD] ON [dbo].[bEMRD] ([EMCo], [Equipment], [Mth], [Trans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biEMRDTrans] ON [dbo].[bEMRD] ([EMCo], [Mth], [Trans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMRD] ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bEMRD_MthTransEquipmentUniqueAttach] ON [dbo].[bEMRD] ([Mth], [EMCo], [Trans], [Equipment], [UniqueAttchID]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biEMRDAttchID] ON [dbo].[bEMRD] ([UniqueAttchID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMRD] WITH NOCHECK ADD CONSTRAINT [FK_bEMRD_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
ALTER TABLE [dbo].[bEMRD] WITH NOCHECK ADD CONSTRAINT [FK_bEMRD_bEMCM_Category] FOREIGN KEY ([EMCo], [Category]) REFERENCES [dbo].[bEMCM] ([EMCo], [Category])
GO
ALTER TABLE [dbo].[bEMRD] WITH NOCHECK ADD CONSTRAINT [FK_bEMRD_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[bEMRD] WITH NOCHECK ADD CONSTRAINT [FK_bEMRD_bEMEM_UsedOnComponent] FOREIGN KEY ([EMCo], [UsedOnComponent]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment])
GO
ALTER TABLE [dbo].[bEMRD] WITH NOCHECK ADD CONSTRAINT [FK_bEMRD_bEMEM_UsedOnEquipment] FOREIGN KEY ([EMCo], [UsedOnEquipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment])
GO
ALTER TABLE [dbo].[bEMRD] WITH NOCHECK ADD CONSTRAINT [FK_bEMRD_bEMWH_WorkOrder] FOREIGN KEY ([EMCo], [WorkOrder]) REFERENCES [dbo].[bEMWH] ([EMCo], [WorkOrder])
GO
ALTER TABLE [dbo].[bEMRD] WITH NOCHECK ADD CONSTRAINT [FK_bEMRD_bEMWI_WOItem] FOREIGN KEY ([EMCo], [WorkOrder], [WOItem]) REFERENCES [dbo].[bEMWI] ([EMCo], [WorkOrder], [WOItem])
GO
ALTER TABLE [dbo].[bEMRD] WITH NOCHECK ADD CONSTRAINT [FK_bEMRD_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
ALTER TABLE [dbo].[bEMRD] WITH NOCHECK ADD CONSTRAINT [FK_bEMRD_bEMCT_EMCostType] FOREIGN KEY ([EMGroup], [EMCostType]) REFERENCES [dbo].[bEMCT] ([EMGroup], [CostType])
GO
ALTER TABLE [dbo].[bEMRD] WITH NOCHECK ADD CONSTRAINT [FK_bEMRD_bEMRC_RevCode] FOREIGN KEY ([EMGroup], [RevCode]) REFERENCES [dbo].[bEMRC] ([EMGroup], [RevCode])
GO
ALTER TABLE [dbo].[bEMRD] WITH NOCHECK ADD CONSTRAINT [FK_bEMRD_vSMWorkOrderScope] FOREIGN KEY ([SMCo], [SMWorkOrder], [SMScope]) REFERENCES [dbo].[vSMWorkOrderScope] ([SMCo], [WorkOrder], [Scope]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[bEMRD] NOCHECK CONSTRAINT [FK_bEMRD_bEMCO_EMCo]
GO
ALTER TABLE [dbo].[bEMRD] NOCHECK CONSTRAINT [FK_bEMRD_bEMCM_Category]
GO
ALTER TABLE [dbo].[bEMRD] NOCHECK CONSTRAINT [FK_bEMRD_bEMEM_Equipment]
GO
ALTER TABLE [dbo].[bEMRD] NOCHECK CONSTRAINT [FK_bEMRD_bEMEM_UsedOnComponent]
GO
ALTER TABLE [dbo].[bEMRD] NOCHECK CONSTRAINT [FK_bEMRD_bEMEM_UsedOnEquipment]
GO
ALTER TABLE [dbo].[bEMRD] NOCHECK CONSTRAINT [FK_bEMRD_bEMWH_WorkOrder]
GO
ALTER TABLE [dbo].[bEMRD] NOCHECK CONSTRAINT [FK_bEMRD_bEMWI_WOItem]
GO
ALTER TABLE [dbo].[bEMRD] NOCHECK CONSTRAINT [FK_bEMRD_bHQGP_EMGroup]
GO
ALTER TABLE [dbo].[bEMRD] NOCHECK CONSTRAINT [FK_bEMRD_bEMCT_EMCostType]
GO
ALTER TABLE [dbo].[bEMRD] NOCHECK CONSTRAINT [FK_bEMRD_bEMRC_RevCode]
GO
ALTER TABLE [dbo].[bEMRD] NOCHECK CONSTRAINT [FK_bEMRD_vSMWorkOrderScope]
GO
