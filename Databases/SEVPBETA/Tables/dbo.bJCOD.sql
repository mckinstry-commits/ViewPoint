CREATE TABLE [dbo].[bJCOD]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[ACO] [dbo].[bACO] NOT NULL,
[ACOItem] [dbo].[bACOItem] NOT NULL,
[PhaseGroup] [tinyint] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[MonthAdded] [dbo].[bMonth] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[EstHours] [dbo].[bHrs] NOT NULL,
[EstUnits] [dbo].[bUnits] NOT NULL,
[EstCost] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
   
   
 CREATE   trigger [dbo].[btJCODd] on [dbo].[bJCOD] for delete as
    

/*-----------------------------------------------------------------
     *   This trigger rejects delete in bJCOD
     *    if the following error condition exists: none
     *
     *   deletes corresponding JCCD records
     *
     *   Author: JRE  Feb 28 1997  3:17PM
     *   Modified By:  GF 04/24/2001 - update status in bPMOA
     *                 GF 06/26/2001 - Issue #13735 - update phase cost type projection plugs, if UpdatePlugs='Y' in JCJM.
     *                 DANF 03/15/2002 - ISSUE #16678 Added ClosePurgeFlag to JCJM to speed up the delete trigger on JCCD.
     *			 GF 08/31/2004 - issue #25428 - format @date so HH:MM not included.
   *			GF 07/21/2011 - TK-06775 when projection plugged update the last projection month with plugged values.
   *			GF 10/28/2011 TK-09507 backed out TK-06775
   *
     *-----------------------------------------------------------------*/
   declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
       @date smalldatetime, @user bVPUserName, @rowsprocessed int, @tablename varchar(10),
       @opencursor tinyint, @field varchar(30), @old varchar(30), @new varchar(30),
       @key varchar(30), @rectype char(1), @JCCo bCompany, @Job bJob, @ACO bACO,
       @ACOItem bACOItem, @PhaseGroup tinyint, @Phase bPhase, @CostType bJCCType,
       @MonthAdded bMonth, @UM bUM, @UnitCost bUnitCost, @EstHours bHrs, @EstUnits bUnits,
       @EstCost bDollar, @updateplugs bYN, @plugged bYN, @jcchum bUM, @jctrans bTrans,
       @projhours bHrs, @projunits bUnits, @projcost bDollar,
		----TK-06775
		@projmaxmonth bMonth
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- If purging job no need to update JCCP
   select @validcnt = count(*) from bJCJM j 
                join deleted d
                on d.JCCo=j.JCCo and d.Job=j.Job
                where j.ClosePurgeFlag='Y'
   
   if @numrows = @validcnt  return
   
   
   select @date = convert(varchar(2),datepart(mm,getdate())) + '/' + convert(varchar(2),datepart(dd,getdate())) + '/' + convert(varchar(4),datepart(yy,getdate()))
   select @user = SUSER_SNAME(), @tablename='bJCCM', @rectype='C', @opencursor=0, @rowsprocessed=0
   
   if @numrows = 1
       select  @JCCo=JCCo, @Job=Job, @ACO=ACO, @ACOItem=ACOItem, @PhaseGroup=PhaseGroup, @Phase=Phase,
               @CostType=CostType, @MonthAdded=MonthAdded, @UM=UM, @UnitCost=UnitCost, @EstHours=EstHours,
               @EstUnits=EstUnits, @EstCost=EstCost
       from deleted
   else
       begin
       -- use a cursor to process each deleted row
       declare bJCOD_delete cursor
       for select JCCo, Job, ACO, ACOItem, PhaseGroup, Phase, CostType, MonthAdded, UM,
              UnitCost, EstHours, EstUnits, EstCost
       from deleted
   
       open bJCOD_delete
       select @opencursor=1
       end
   
   NEXTROW:
   if @opencursor=1
       begin
       fetch next from bJCOD_delete
       into @JCCo, @Job, @ACO, @ACOItem, @PhaseGroup, @Phase, @CostType, @MonthAdded, @UM,
            @UnitCost, @EstHours, @EstUnits, @EstCost
   
       if @@fetch_status = 0 goto update_check
   
       if @rowsprocessed=0
           begin
           select @errmsg = 'Cursor error'
           goto error
           end
       else
           goto TRIGGEREXIT
       end
   
   update_check:
   
   -- delete JCCD
   delete bJCCD
   where JCCo=@JCCo and Job=@Job and ACO=@ACO and ACOItem=@ACOItem and PhaseGroup=@PhaseGroup
   and Phase=@Phase and CostType=@CostType and Source='JC ChngOrd' and JCTransType='CO'
   
   -- update bPMOA Status flag
   update bPMOA set Status = 'N'
   from bPMOA a join bPMPA p on p.PMCo=a.PMCo and p.Project=a.Project and p.AddOn=a.AddOn
   join bPMOI i on a.PMCo=i.PMCo and a.Project=i.Project and a.PCOType=i.PCOType and a.PCO=i.PCO and a.PCOItem=i.PCOItem
   where i.PMCo=@JCCo and i.Project=@Job and i.ACO=@ACO and i.ACOItem=@ACOItem and p.Phase=@Phase and p.CostType=@CostType
   
   -- update bPMOL Interface date
   update bPMOL set InterfacedDate = null
   from bPMOL where PMCo=@JCCo and Project=@Job and ACO=@ACO and ACOItem=@ACOItem and Phase=@Phase and CostType=@CostType
   
   -- get update plug flag from bJCJM
   select @updateplugs=UpdatePlugs from bJCJM where JCCo=@JCCo and Job=@Job
   if @@rowcount <> 1 goto JCOD_AUDIT
   
   -- get plugged flag from bJCCH
   select @plugged=Plugged, @jcchum=UM from bJCCH
   where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType
   if @@rowcount <> 1 goto JCOD_AUDIT
   
   -- only update plugged projections if both flags are 'Y'
   if @updateplugs = 'Y' and @plugged = 'Y'
       BEGIN
		-- set projection values
		select @projhours = @EstHours * -1, @projcost = @EstCost * -1, @projunits = @EstUnits * -1
       
       	----TK-06775
		---- try to find the last projection month for plugged phase cost type
		SET @projmaxmonth = NULL
		--select @projmaxmonth = ISNULL(Max(Mth), @MonthAdded)
		--from dbo.bJCCD
		--where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType and
		--JCTransType='PF' and Source ='JC Projctn'  and Mth < @MonthAdded
		--group by JCCo,Job,PhaseGroup,Phase,CostType,JCTransType,Source, Mth

		---- if @projmaxmonth is null use month added
		IF @projmaxmonth IS NULL SET @projmaxmonth = @MonthAdded
		
   		---- get next available transaction # for JCCD
   		---- TK-06775 month added may be different from JCOD month added.
   		exec @jctrans = bspHQTCNextTrans 'bJCCD', @JCCo, @projmaxmonth, @errmsg output
   		if @jctrans = 0 goto JCOD_AUDIT
   
       -- insert JC Detail
       insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
               ActualDate, JCTransType, Source, Description, BatchId, InUseBatchId, UM, PostedUM,
               ProjHours, ProjUnits, ProjCost, ForecastHours, ForecastUnits, ForecastCost)
       values (@JCCo, 
   			   ----TK-06775
			   ----MonthAdded projection month or JCOD month added
			   @projmaxmonth,
			   @jctrans, @Job, @PhaseGroup, @Phase, @CostType,
			   ----PostedDate will be the system date if same month or use the month for first day of projection month
			   CASE WHEN @projmaxmonth = @MonthAdded THEN @date ELSE @projmaxmonth END,
               @date, 'PF', 'JC Projctn', 'Adjustment to plug from JCOD delete trigger',
               null, null, @jcchum, @jcchum, @projhours,
              	case when @UM=@jcchum then @projunits else 0 end,
               @projcost, 0, 0, 0)
       --if @@rowcount <> 1 goto JCOD_AUDIT
       end
   
   
   JCOD_AUDIT:
   -- Audit inserts
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       select 'bJCOD','ACO: ' + @ACO+ ' ACOItem: '+@ACOItem+' Phase '+@Phase+' CT '+ Convert(varchar(3),@CostType),
              @JCCo, 'D', null, null, null, getdate(), SUSER_SNAME() from bJCCO
       where JCCo=@JCCo and AuditChngOrders='Y'
   
   if @opencursor = 1
       begin
       select @rowsprocessed=@rowsprocessed +1
       goto NEXTROW
       end
   
   TRIGGEREXIT:
       if @opencursor = 1
           begin
           close bJCOD_delete
           deallocate bJCOD_delete
           end
       return
   
   error:
   
       if @opencursor = 1
           begin
           close bJCOD_delete
           deallocate bJCOD_delete
           end
   
       select @errmsg = @errmsg + ' - cannot update bJCOD!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
   
   
   /*********************************************************/
CREATE   trigger [dbo].[btJCODi] on [dbo].[bJCOD] for insert as
   

/*-----------------------------------------------------------------
   *   This trigger rejects insert in bJCOD
   *    if the following error condition exists:
   *
   * Created By:  JRE  Feb 28 1997 12:23PM
   * Modified By: GF 06/27/2001 - Issue #13735 - update phase cost type projection plugs, if UpdatePlugs='Y' in JCJM.
   *			GF 08/23/2001 - needed to part out get date by mm,dd,yy for actual date in JCCD
   *              	GF 10/20/2001 - Addition to update projection plug. If insert JCOD with no original estimates
   *                              and UpdatePlugs='Y' in JCJM create projection record in JCCD.
   *              	DANF 09/06/02 - 17738 Added Phase group to bspJCADDCOSTTYPE
   *			TV - 23061 added isnulls
   *			GF 09/08/2004 - issue #25500 problems with Job copy multiple records. Changed to a local fast forward cursor.
   *			GF 07/21/2011 - TK-06775 when projection plugged update the last projection month with plugged values.
   *			GF 10/28/2011 TK-09507 backed out TK-06775
   *
   *
   *-----------------------------------------------------------------*/
   declare @errmsg varchar(255), @validcnt int, @rcode int, @numrows int, @opencursor int,
   		@errstart varchar(80), @date bDate, @user bVPUserName, @costtrans bTrans,
   		@jcco bCompany, @job bJob, @aco bACO, @acoitem bACOItem, @phasegroup bGroup,
   		@phase bPhase, @costtype bJCCType, @monthadded bMonth, @um bUM, @unitcost bUnitCost,
   		@esthours bHrs, @estunits bUnits, @estcost bDollar, @item bContractItem, @actualdate bDate,
   		@updateplugs bYN, @plugged bYN, @jcchum bUM, @projhours bHrs, @projunits bUnits, 
   		@projcost bDollar, @orighours bHrs, @origunits bUnits, @origcost bDollar,
   		----TK-06775
		@projmaxmonth bMonth
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- extract the month, date and year values from getdate and insert into invdate to ensure that the time is defaulted to 12:00 am on all bills
	select @date = dbo.vfDateOnly()
     select @user = SUSER_SNAME(), @opencursor = 0
   
   
   -- -- -- validate ACO item
   select @validcnt = count(*) from inserted i 
   join bJCOI c on c.JCCo=i.JCCo and c.Job=i.Job and c.ACO=i.ACO and c.ACOItem=i.ACOItem
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid ACO Item'
   	goto error
   	end
   
   -- -- -- validate UM
   select @validcnt = count(*) from inserted i join bHQUM u on u.UM=i.UM
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Unit of Measure'
   	goto error
   	end
   
   
   -- -- -- create cursor on bJCOD inserted rows
   if @numrows = 1
   	select @jcco = JCCo, @job = Job, @aco = ACO, @acoitem = ACOItem, @phasegroup = PhaseGroup, 
   		@phase = Phase, @costtype = CostType, @monthadded = MonthAdded, @um = UM, 
   		@unitcost = UnitCost, @esthours = EstHours, @estunits = EstUnits, @estcost = EstCost
       from inserted
   else
   	begin
   	-- use a cursor to process each inserted row
   	declare bJCOD_insert cursor LOCAL FAST_FORWARD
   	for select JCCo, Job, ACO, ACOItem, PhaseGroup, Phase, CostType,
   			MonthAdded, UM, UnitCost, EstHours, EstUnits, EstCost
   	from inserted
   
   	open bJCOD_insert
   	set @opencursor = 1
   
   	fetch next from bJCOD_insert into @jcco, @job, @aco, @acoitem, @phasegroup, @phase, @costtype,
   			@monthadded, @um, @unitcost, @esthours, @estunits, @estcost
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   insert_check:
   select @errstart='Job:' + isnull(@job,'') + ' ACO: ' + isnull(@aco,'') + ' ACOItem: ' + isnull(@acoitem,'') + ' Phase: ' + isnull(@phase,'') + ' CT: '+isnull(STR(@costtype),'')
   
   -- -- -- get contract item from bJCOI
   select @item=Item from bJCOI with (nolock)
   where JCCo=@jcco and Job=@job and ACO=@aco and ACOItem=@acoitem
   
   -- -- -- validate standard phase - if it doesnt exist in JCJP try to add it
   exec @rcode = bspJCADDPHASE @jcco, @job, @phasegroup, @phase, 'Y', @item, @errmsg output
   if @rcode <> 0 goto error
   
   -- -- -- validate Cost Type - if JCCH doesnt exist try to add it
   exec @rcode = bspJCADDCOSTTYPE @jcco=@jcco, @job=@job, @phasegroup=@phasegroup, @phase=@phase,
   	               @costtype=@costtype, @um=@um, @override= 'Y', @msg=@errmsg output
   if @rcode<>0 goto error
   
   
   /****************************************************************************
   * update bJCCD records
   * note: this is an update instead of an insert because we do not wish
   * to keep history of changes to original estimates
   ****************************************************************************/
   update bJCCD set PostedUM=@um, UM=@um, EstHours=@esthours, EstUnits=@estunits, EstCost=@estcost
   where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
   and ACO=@aco and ACOItem=@acoitem and Source='JC ChngOrd' and JCTransType='CO'
   if @@rowcount = 0
   	begin
   	select @actualdate=convert(varchar(10), max(ApprovedDate),101)
   	from bPMOI where PMCo=@jcco and Project=@job and ACO=@aco and ACOItem=@acoitem
   	-- -- -- The following is the change
   	If @actualdate is null
   		begin
   	       select @actualdate = convert(varchar(10), max(h.ApprovalDate),101) 
   		from JCOD d
   	       join JCOI i on i.JCCo=d.JCCo and i.ACO=d.ACO and i.Job=d.Job and i.ACOItem=d.ACOItem
   	       join JCOH h on h.JCCo=i.JCCo and h.ACO=i.ACO and h.Job=i.Job
   	       where d.JCCo=@jcco and d.Job=@job and d.ACO=@aco
   	       end
   
   	exec @costtrans = bspHQTCNextTrans 'bJCCD', @jcco, @monthadded, @errmsg output
   	if @costtrans=0 goto error
   
   	-- -- -- insert into bJCCD
   	insert into bJCCD (JCCo, Mth,CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, 
   			ActualDate, JCTransType, Source, Description, PostedUM, UM, EstHours, EstUnits, EstCost, 
   			ACO, ACOItem)
   	select @jcco, @monthadded, @costtrans, @job, @phasegroup, @phase, @costtype, @date,
   			isnull(@actualdate, @monthadded), 'CO', 'JC ChngOrd', 'Change Order ' + isnull(@aco,''),
   			@um, @um, @esthours, @estunits, @estcost, @aco, @acoitem
   	if @@rowcount = 0
   		begin
   		select @errmsg = ' Unable to insert Cost Transaction in bJCCD'
   		goto error
   		end
   	end
   
   -- -- -- get update plug flag from bJCJM
   select @updateplugs=UpdatePlugs from dbo.bJCJM where JCCo=@jcco and Job=@job
   if @@rowcount <> 1 goto Next_Cursor_Row
   
   -- -- -- get plugged flag from bJCCH
   select @plugged=Plugged, @jcchum=UM, @orighours=OrigHours, @origunits=OrigUnits, @origcost=OrigCost
   from dbo.bJCCH where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup 
   and Phase=@phase and CostType=@costtype
   if @@rowcount <> 1 goto Next_Cursor_Row
   
   -- only update plugged projections if both flags are 'Y'
   if @updateplugs = 'Y' and @plugged = 'Y'
   	begin
   		---- set projection values
   		select @projhours = @esthours, @projcost = @estcost, @projunits = @estunits

		----TK-06775
		---- try to find the last projection month for plugged phase cost type
		SET @projmaxmonth = NULL
		--select @projmaxmonth = ISNULL(Max(Mth), @monthadded)
		--from dbo.bJCCD
		--where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype and
		--JCTransType='PF' and Source ='JC Projctn'  and Mth < @monthadded
		--group by JCCo,Job,PhaseGroup,Phase,CostType,JCTransType,Source, Mth

		---- if @projmaxmonth is null use month added
		IF @projmaxmonth IS NULL SET @projmaxmonth = @monthadded
		
   		---- get next available transaction # for JCCD
   		---- TK-06775 month added may be different from JCOD month added.
   		exec @costtrans = bspHQTCNextTrans 'bJCCD', @jcco, @projmaxmonth, @errmsg output
   		if @costtrans = 0 goto error
   
   		---- insert JC Detail
   		insert dbo.bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
   			ActualDate, JCTransType, Source, Description, UM, PostedUM,
   			ProjHours, ProjUnits, ProjCost, ForecastHours, ForecastUnits, ForecastCost)
   		select @jcco,
   			   ----TK-06775
			   ----MonthAdded projection month or JCOD month added
			   @projmaxmonth,
			   @costtrans, @job, @phasegroup, @phase, @costtype,
			   ----PostedDate will be the system date if same month or use the month for first day of projection month
			   CASE WHEN @projmaxmonth = @monthadded THEN @date ELSE @projmaxmonth END,
   			   @date, 'PF', 'JC Projctn', 'Adjustment to plug from JCOD insert trigger', @jcchum, @jcchum, 
			   @projhours, case when @um=@jcchum then @projunits else 0 end, @projcost, 0, 0, 0
   		if @@rowcount = 0
   			begin
   			select @errmsg = ' Unable to insert Cost Transaction in bJCCD '
   			goto error
   			end
   	end
   
   
   Next_Cursor_Row:
   if @numrows > 1
   	begin
   	fetch next from bJCOD_insert into @jcco, @job, @aco, @acoitem, @phasegroup, @phase, @costtype,
   			@monthadded, @um, @unitcost, @esthours, @estunits, @estcost
   	if @@fetch_status = 0
   		goto insert_check
   	else
   		begin
   		close bJCOD_insert
  
   		deallocate bJCOD_insert
   		set @opencursor = 0
   		end
   	end
   
   
   -- Audit inserts
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bJCOD', 'ACO: ' + isnull(i.ACO,'') + ' ACOItem: ' + isnull(i.ACOItem,'') + ' Phase: ' + isnull(i.Phase,'') + ' CT: ' + convert(varchar(3), isnull(i.CostType,0)),
   	i.JCCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
   from inserted i join bJCCO c with (nolock) on c.JCCo = i.JCCo
   where c.AuditChngOrders='Y'
   
   
   
   
   -- -- -- -- Pseudo cursor
   -- -- -- select @JCCo=min(JCCo) from inserted
   -- -- -- while @JCCo is not null
   -- -- -- begin
   -- -- -- select @Job=min(Job) from inserted where JCCo=@JCCo
   -- -- -- while @Job is not null
   -- -- -- begin
   -- -- -- select @ACO=min(ACO) from inserted where JCCo=@JCCo and Job=@Job
   -- -- -- while @ACO is not null
   -- -- -- begin
   -- -- -- select @ACOItem=min(ACOItem) from inserted where JCCo=@JCCo and Job=@Job and ACO=@ACO
   -- -- -- while @ACOItem is not null
   -- -- -- begin
   -- -- -- select @PhaseGroup=min(PhaseGroup) from inserted where JCCo=@JCCo and Job=@Job and ACO=@ACO
   -- -- -- and ACOItem=@ACOItem
   -- -- -- while @PhaseGroup is not null
   -- -- -- begin
   -- -- -- select @Phase=min(Phase) from inserted where JCCo=@JCCo and Job=@Job and ACO=@ACO
   -- -- -- and ACOItem=@ACOItem and PhaseGroup=@PhaseGroup
   -- -- -- while @Phase is not null
   -- -- -- begin
   -- -- -- select @CostType=min(CostType) from inserted where JCCo=@JCCo and Job=@Job and ACO=@ACO
   -- -- -- and ACOItem=@ACOItem and PhaseGroup=@PhaseGroup and Phase=@Phase
   -- -- -- while @CostType is not null
   -- -- -- begin
   -- -- -- 
   -- -- --     select @Item=Item from bJCOI where JCCo=@JCCo and Job=@Job and ACO=@ACO and ACOItem=@ACOItem
   -- -- -- 
   -- -- --     select @errstart='Job:' + isnull(@Job,'') + ' ACO: ' + isnull(@ACO,'') + ' ACOItem: ' + isnull(@ACOItem,'') + ' Phase: ' + isnull(@Phase,'') + ' CT: '+isnull(STR(@CostType),'')
   -- -- -- 
   -- -- --     select @MonthAdded=MonthAdded, @UM=UM, @UnitCost=UnitCost, @EstHours=EstHours, @EstUnits=EstUnits, @EstCost=EstCost
   -- -- --     from inserted where JCCo=@JCCo and Job=@Job and ACO=@ACO and ACOItem=@ACOItem
   -- -- --     and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType
   -- -- -- 
   -- -- --     -- Validate UM
   -- -- --     if not exists (select * from bHQUM where UM = @UM)
   -- -- --         begin
   -- -- --         select @errmsg =' Unit of Measure ' + isnull(@UM,'') + ' is Invalid '
   -- -- --         goto error
   -- -- --         end
   -- -- -- 
   -- -- --     -- Validate ACOItem
   -- -- --     if not exists(select * from bJCOI where JCCo=@JCCo and Job=@Job  and ACO=@ACO  and ACOItem=@ACOItem)
   -- -- --         begin
   -- -- --         select @errmsg = ' ACO Item is Invalid '
   -- -- --         goto error
   -- -- --         end
   -- -- -- 
   -- -- --     -- validate standard phase - if it doesnt exist in JCJP try to add it
   -- -- --     exec @rcode = bspJCADDPHASE @JCCo,@Job,@PhaseGroup,@Phase,'Y',@Item,@errmsg output
   -- -- --     if @rcode <> 0
   -- -- -- 	   begin
   -- -- -- 	   GoTo error
   -- -- -- 	   End
   -- -- -- 
   -- -- --     -- validate Cost Type - if JCCH doesnt exist try to add it
   -- -- --     exec @rcode = bspJCADDCOSTTYPE @jcco=@JCCo, @job=@Job, @phasegroup=@PhaseGroup, @phase=@Phase,
   -- -- -- 	               @costtype=@CostType, @um=@UM, @override= 'Y', @msg=@errmsg output
   -- -- --     if @rcode<>0
   -- -- -- 	   begin
   -- -- -- 	   GoTo error
   -- -- -- 	   End
   -- -- -- 
   -- -- -- 
   -- -- --  /************************
   -- -- --     * update bJCCD records
   -- -- --     * note: this is an update instead of an insert because we do not wish
   -- -- --     * to keep history of changes to original estimates
   -- -- --     ************************/
   -- -- --     update bJCCD set PostedUM=@UM, UM=@UM, EstHours=@EstHours, EstUnits=@EstUnits, EstCost=@EstCost
   -- -- -- 	where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType
   -- -- --     and ACO=@ACO and ACOItem=@ACOItem and Source='JC ChngOrd' and JCTransType='CO'
   -- -- --     if @@rowcount = 0
   -- -- -- 	   begin
   -- -- -- 
   -- -- -- 	   EXEC @costtrans = bspHQTCNextTrans 'bJCCD', @JCCo, @MonthAdded, @errmsg output
   -- -- -- 	   IF @costtrans=0 goto error
   -- -- -- 
   -- -- --        select @actualdate=convert(varchar(10),Max(ApprovedDate),101)
   -- -- --        from bPMOI where PMCo=@JCCo and Project=@Job and ACO=@ACO and ACOItem=@ACOItem
   -- -- -- 
   -- -- --        --The following is the change
   -- -- -- 	   If @actualdate is null
   -- -- -- 	       begin
   -- -- -- 	       select @actualdate = convert(varchar(10),MAX(h.ApprovalDate),101) from JCOD d
   -- -- -- 	       join JCOI i on i.JCCo=d.JCCo and i.ACO=d.ACO and i.Job=d.Job and i.ACOItem=d.ACOItem
   -- -- -- 	       join JCOH h on h.JCCo=i.JCCo and h.ACO=i.ACO and h.Job=i.Job
   -- -- -- 	       where d.ACO=@ACO
   -- -- -- 	       end
   -- -- -- 
   -- -- -- 	   INSERT INTO bJCCD (JCCo, Mth,CostTrans,Job,PhaseGroup,Phase,CostType,PostedDate,ActualDate,
   -- -- --             JCTransType,Source,Description,	PostedUM,UM,EstHours,EstUnits,EstCost,ACO,ACOItem)
   -- -- -- 	   SELECT @JCCo, @MonthAdded,@costtrans,@Job,@PhaseGroup,@Phase,@CostType,@date,
   -- -- --             isnull(@actualdate,@MonthAdded),'CO','JC ChngOrd','Change Order '+@ACO,
   -- -- --             @UM,@UM,@EstHours,@EstUnits,@EstCost,@ACO,@ACOItem
   -- -- --        if @@rowcount = 0
   -- -- --             begin
   -- -- --             select @errmsg = ' Unable to insert Cost Transaction in bJCCD '
   -- -- --             goto error
   -- -- --             end
   -- -- -- 	   end
   -- -- -- 
   -- -- --     -- get update plug flag from bJCJM
   -- -- --     select @updateplugs=UpdatePlugs from bJCJM where JCCo=@JCCo and Job=@Job
   -- -- --     if @@rowcount <> 1 goto JCOD_AUDIT
   -- -- -- 
   -- -- --     -- get plugged flag from bJCCH
   -- -- --     select @plugged=Plugged, @jcchum=UM, @orighours=OrigHours, @origunits=OrigUnits, @origcost=OrigCost
   -- -- --     from bJCCH where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType
   -- -- --     if @@rowcount <> 1 goto JCOD_AUDIT
   -- -- -- 
   -- -- --     -- only update plugged projections if both flags are 'Y'
   -- -- --     if @updateplugs = 'Y' and @plugged = 'Y'
   -- -- --         begin
   -- -- --         -- set projection values
   -- -- --         select @projhours = @EstHours, @projcost = @EstCost, @projunits = @EstUnits
   -- -- --         -- get next available transaction # for JCCD
   -- -- --         exec @jctrans = bspHQTCNextTrans 'bJCCD', @JCCo, @MonthAdded, @errmsg output
   -- -- --         if @jctrans = 0 goto error
   -- -- -- 
   -- -- --         -- insert JC Detail
   -- -- --         insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
   -- -- --                 ActualDate, JCTransType, Source, Description, BatchId, InUseBatchId, UM, PostedUM,
   -- -- --                 ProjHours, ProjUnits, ProjCost, ForecastHours, ForecastUnits, ForecastCost)
   -- -- --         values (@JCCo, @MonthAdded, @jctrans, @Job, @PhaseGroup, @Phase, @CostType, @date,
   -- -- --                 @date, 'PF', 'JC Projctn', 'Adjustment to plug from JCOD insert trigger',
   -- -- --                 null, null, @jcchum, @jcchum, @projhours,
   -- -- --            	    case when @UM=@jcchum then @projunits else 0 end,
   -- -- --                 @projcost, 0, 0, 0)
   -- -- --         if @@rowcount = 0
   -- -- --             begin
   -- -- --             select @errmsg = ' Unable to insert Cost Transaction in bJCCD '
   -- -- --             goto error
   -- -- --             end
   -- -- --         end
   -- -- -- 
   -- -- -- 
   -- -- -- 
   -- -- -- JCOD_AUDIT:
   -- -- -- -- Audit inserts
   -- -- -- insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   -- -- -- select 'bJCOD','ACO: ' + isnull(@ACO,'') + ' ACOItem: ' + isnull(@ACOItem,'') + ' Phase ' + isnull(@Phase,'') + ' CT ' + Convert(varchar(3),@CostType),
   -- -- --           @JCCo, 'A', null, null, null, getdate(), SUSER_SNAME() from bJCCO
   -- -- -- where JCCo=@JCCo and AuditChngOrders='Y'
   -- -- -- 
   -- -- -- 
   -- -- -- 
   -- -- -- select @CostType=min(CostType) from inserted where JCCo=@JCCo and Job=@Job and ACO=@ACO
   -- -- -- and ACOItem=@ACOItem and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType>@CostType
   -- -- -- end
   -- -- -- select @Phase=min(Phase) from inserted where JCCo=@JCCo and Job=@Job and ACO=@ACO
   -- -- -- and ACOItem=@ACOItem and PhaseGroup=@PhaseGroup and Phase>@Phase
   -- -- -- end
   -- -- -- select @PhaseGroup=min(PhaseGroup) from inserted where JCCo=@JCCo and Job=@Job and ACO=@ACO
   -- -- -- and ACOItem=@ACOItem and PhaseGroup>@PhaseGroup
   -- -- -- end
   -- -- -- select @ACOItem=min(ACOItem) from inserted where JCCo=@JCCo and Job=@Job and ACO=@ACO
   -- -- --  and ACOItem>@ACOItem
   -- -- -- end
   -- -- -- select @ACO=min(ACO) from inserted where JCCo=@JCCo and Job=@Job and ACO>@ACO
   -- -- -- end
   -- -- -- select @Job=min(Job) from inserted where JCCo=@JCCo and Job>@Job
   -- -- -- end
   -- -- -- select @JCCo=min(JCCo) from inserted where JCCo>@JCCo
   -- -- -- end
   
   
   
   return
   
   
   
   
   error:
   	select @errmsg = isnull(@errstart,'') + ' ' + isnull(@errmsg,'') + ' - cannot insert JCOD!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCODu    Script Date: 8/28/99 9:38:24 AM ******/
CREATE   trigger [dbo].[btJCODu] on [dbo].[bJCOD] for update as
   

/*-----------------------------------------------------------------
    *   This trigger rejects update in bJCOD
    *    if the following error condition exists:
    *
    *   Author: JRE  Feb 28 1997  1:22PM
    *   Modified: JM 7/10/98 - Revised definition of @date to convert to current date at midnight, per Issue 2500.
    *             GF 06/26/2001 - Issue #13735 - update phase cost type projection plugs, if UpdatePlugs='Y' in JCJM.
    *             GF 08/23/2001 - needed to part out get date by mm,dd,yy for actual date in JCCD
    *				TV - 23061 added isnulls
   *			GF 07/21/2011 - TK-06775 when projection plugged update the last projection month with plugged values.
   *			GF 10/28/2011 TK-09507 backed out TK-06775
   *
    *-----------------------------------------------------------------*/
   
   declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int, @costtrans int,
           @date smalldatetime, @user bVPUserName,@rowsprocessed int, @tablename varchar(10), @opencursor tinyint,
           @field varchar(30), @old varchar(30), @new varchar(30), @key varchar(30), @rectype char(1),
           @JCCo bCompany, @Job bJob, @ACO bACO, @ACOItem bACOItem, @PhaseGroup tinyint, @Phase bPhase,
           @CostType bJCCType, @MonthAdded bMonth, @UM bUM, @UnitCost bUnitCost, @EstHours bHrs, @EstUnits bUnits,
           @EstCost bDollar, @oldJCCo bCompany, @oldJob bJob, @oldACO bACO, @oldACOItem bACOItem,
           @oldPhaseGroup tinyint, @oldPhase bPhase, @oldCostType bJCCType, @oldMonthAdded bMonth, @oldUM bUM,
           @oldUnitCost bUnitCost, @oldEstHours bHrs, @oldEstUnits bUnits, @oldEstCost bDollar,
           @updateplugs bYN, @plugged bYN, @jcchum bUM, @jctrans bTrans, @projhours bHrs,
           @projunits bUnits, @projcost bDollar,
			----TK-06775
			@projmaxmonth bMonth
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- extract the month, date and year values from getdate and insert into invdate to ensure that the time is defaulted to 12:00 am on all bills
   select @date = convert(varchar(2),datepart(mm,getdate())) + '/' + convert(varchar(2),datepart(dd,getdate())) + '/' + convert(varchar(4),datepart(yy,getdate()))
   
   select @user = SUSER_SNAME(), @tablename='bJCOD', @rectype='C',
          @opencursor = 0, @rowsprocessed=0
   
   if update(JCCo)
         begin select @errmsg = 'Company may not be changed' goto error end
   if update(Job)
         begin select @errmsg = 'Job may not be changed' goto error end
   if update(ACO)
         begin select @errmsg = 'ACO may not be changed' goto error end
   if update(ACOItem)
         begin select @errmsg = 'ACO Item may not be changed' goto error end
   if update(PhaseGroup)
         begin select @errmsg = 'Phase Group may not be changed' goto error end
   if update(Phase)
         begin select @errmsg = 'Phase may not be changed' goto error end
   if update(CostType)
         begin select @errmsg = 'Cost Type may not be changed' goto error end
   
   if @numrows = 1
      select  @JCCo=JCCo, @Job=Job, @ACO=ACO, @ACOItem=ACOItem, @PhaseGroup=PhaseGroup, @Phase=Phase,
              @CostType=CostType, @MonthAdded=MonthAdded, @UM=UM, @UnitCost=UnitCost, @EstHours=EstHours,
              @EstUnits=EstUnits, @EstCost=EstCost
      from inserted
   else
       begin
       -- use a cursor to process each updated row
       declare bJCOD_update cursor
       for select JCCo, Job, ACO, ACOItem, PhaseGroup, Phase, CostType, MonthAdded,
                  UM, UnitCost, EstHours, EstUnits, EstCost
       from inserted
   
       open bJCOD_update
       select @opencursor=1
       end
   
   NEXTROW:
   
   if @opencursor=1
       begin
       fetch next from bJCOD_update
           into @JCCo, @Job, @ACO, @ACOItem, @PhaseGroup, @Phase, @CostType, @MonthAdded,
                @UM, @UnitCost, @EstHours, @EstUnits, @EstCost
   
       if @@fetch_status = 0 goto update_check
   
       if @rowsprocessed=0
           begin
           select @errmsg = 'Cursor error'
           goto error
           end
       else
           goto TRIGGEREXIT
       end
   
   update_check:
   
   -- get old values
   select @oldMonthAdded=MonthAdded, @oldUM=UM, @oldUnitCost=UnitCost,
          @oldEstHours=EstHours, @oldEstUnits=EstUnits, @oldEstCost=EstCost
   from deleted where JCCo=@JCCo and Job=@Job and ACO=@ACO and ACOItem=@ACOItem
   and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType
   if @@rowcount <> 1
       begin
       select @errmsg = 'Cannot retrieve original values'
       goto error
       end
   
   -- Validate UM
   if not exists (select * from bHQUM where UM = @UM)
       begin
       select @errmsg = 'UM ' + isnull(@UM,'') + ' is Invalid '
       goto error
       end
   
   update bJCCD set PostedUM=@UM, UM=@UM, EstHours=@EstHours, EstUnits=@EstUnits, EstCost=@EstCost
   where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType
   and ACO=@ACO and ACOItem=@ACOItem and Source='JC ChngOrd' and JCTransType='CO'
   if @@rowcount = 0
       BEGIN
       -- insert bJCCD record
       EXEC @costtrans = bspHQTCNextTrans 'bJCCD', @JCCo, @MonthAdded, @errmsg output
       IF @costtrans=0 goto error
   
       INSERT INTO bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
               ActualDate, JCTransType, Source, Description, PostedUM, UM,
               EstHours, EstUnits, EstCost, ACO, ACOItem)
       SELECT @JCCo, @MonthAdded, @costtrans, @Job, @PhaseGroup, @Phase, @CostType, @MonthAdded,
              CONVERT (varchar(8), getdate(), 1), 'CO', 'JC ChngOrd', 'Change Order '+@ACO, @UM, @UM,
              @EstHours, @EstUnits, @EstCost, @ACO ,@ACOItem
       END
   
   -- get update plug flag from bJCJM
   select @updateplugs=UpdatePlugs from bJCJM where JCCo=@JCCo and Job=@Job
   if @@rowcount <> 1 goto JCOD_AUDIT
   
   -- get plugged flag from bJCCH
   select @plugged=Plugged, @jcchum=UM from bJCCH
   where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType
   if @@rowcount <> 1 goto JCOD_AUDIT
   
   -- only update plugged projections if both flags are 'Y'
   if @updateplugs = 'Y' and @plugged = 'Y'
       begin
       -- step one: create JCCD entry to backout old values
       select @projhours = @oldEstHours * -1, @projcost = @oldEstCost * -1, @projunits = @oldEstUnits * -1
       
       	----TK-06775
		---- try to find the last projection month for plugged phase cost type
		SET @projmaxmonth = NULL
		--select @projmaxmonth = ISNULL(Max(Mth), @MonthAdded)
		--from dbo.bJCCD
		--where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType and
		--JCTransType='PF' and Source ='JC Projctn'  and Mth < @MonthAdded
		--group by JCCo,Job,PhaseGroup,Phase,CostType,JCTransType,Source, Mth

		---- if @projmaxmonth is null use month added
		IF @projmaxmonth IS NULL SET @projmaxmonth = @MonthAdded
		
   		---- get next available transaction # for JCCD
   		---- TK-06775 month added may be different from JCOD month added.
   		exec @jctrans = bspHQTCNextTrans 'bJCCD', @JCCo, @projmaxmonth, @errmsg output
   		if @jctrans = 0 goto error
       
       -- get next available transaction # for JCCD
       --select @tablename = 'bJCCD'
       --exec @jctrans = bspHQTCNextTrans @tablename, @JCCo, @MonthAdded, @errmsg output
       --if @jctrans = 0 goto error
       -- insert JC Detail for old values
       insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
               ActualDate, JCTransType, Source, Description, BatchId, InUseBatchId, UM, PostedUM,
               ProjHours, ProjUnits, ProjCost, ForecastHours, ForecastUnits, ForecastCost)
       values (@JCCo, 
   			   ----TK-06775
			   ----MonthAdded projection month or JCOD month added
			   @projmaxmonth,
			   @jctrans, @Job, @PhaseGroup, @Phase, @CostType,
			   ----PostedDate will be the system date if same month or use the month for first day of projection month
			   CASE WHEN @projmaxmonth = @MonthAdded THEN @date ELSE @projmaxmonth END,
               @date, 'PF', 'JC Projctn', 'Adjustment to plug from JCOD update trigger - old values',
               null, null, @jcchum, @jcchum, @projhours,
              	case when @oldUM=@jcchum then @projunits else 0 end,
               @projcost, 0, 0, 0)
       if @@rowcount = 0
           begin
           select @errmsg = ' Unable to insert Cost Transaction in bJCCD '
           goto error
           end
   
   
       -- step two: create JCCD entry to update new values
       select @projhours = @EstHours, @projcost = @EstCost, @projunits = @EstUnits
       -- get next available transaction # for JCCD
       exec @jctrans = bspHQTCNextTrans 'bJCCD', @JCCo, @projmaxmonth, @errmsg output
       if @jctrans = 0 goto error
       -- insert JC Detail
       insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
               ActualDate, JCTransType, Source, Description, BatchId, InUseBatchId, UM, PostedUM,
               ProjHours, ProjUnits, ProjCost, ForecastHours, ForecastUnits, ForecastCost)
       values (@JCCo, 
   			   ----TK-06775
			   ----MonthAdded projection month or JCOD month added
			   @projmaxmonth,
			   @jctrans, @Job, @PhaseGroup, @Phase, @CostType,
			   ----PostedDate will be the system date if same month or use the month for first day of projection month
			   CASE WHEN @projmaxmonth = @MonthAdded THEN @date ELSE @projmaxmonth END,
               @date, 'PF', 'JC Projctn', 'Adjustment to plug from JCOD update trigger - new values',
               null, null, @jcchum, @jcchum, @projhours,
              	case when @UM=@jcchum then @projunits else 0 end,
               @projcost, 0, 0, 0)
       if @@rowcount = 0
           begin
           select @errmsg = ' Unable to insert Cost Transaction in bJCCD '
           goto error
           end
       end
   
   
   JCOD_AUDIT:
   -- Audit inserts
   if (select AuditChngOrders from bJCCO where JCCo = @JCCo) = 'Y'
       begin
       select @key='Job: '+ isnull(@Job, '')+' ACO: ' + isnull(@ACO,'') + ' ACOItem: ' + isnull(@ACOItem,'') + ' Phase: ' + isnull(@Phase,'') + ' CT '+ isnull(Convert(varchar(3),@CostType),'')
   
       if @MonthAdded <> @oldMonthAdded
           begin
           exec @errno = bspHQMAInsert @tablename, @key, @JCCo,'C','MonthAdded', @oldMonthAdded, @MonthAdded, @date, @user, @errmsg output
           if @errno <> 0 goto error
           end
   
       if @UM <> @oldUM
           begin
           exec @errno = bspHQMAInsert @tablename, @key, @JCCo,'C','UM', @oldUM, @UM, @date, @user, @errmsg output
           if @errno <> 0 goto error
           end
   
       if @UnitCost <> @oldUnitCost
           begin
           select @old=convert(varchar(18),@oldUnitCost), @new=convert(varchar(18),@UnitCost)
           exec @errno = bspHQMAInsert @tablename, @key, @JCCo,'C','UnitCost', @old, @new, @date, @user, @errmsg output
           if @errno <> 0 goto error
           end
   
       if @EstHours <> @oldEstHours
           begin
           select @old=convert(varchar(12),@oldEstHours), @new=convert(varchar(12),@EstHours)
           exec @errno = bspHQMAInsert @tablename, @key, @JCCo,'C','EstHours', @old, @new, @date, @user, @errmsg output
           if @errno <> 0 goto error
           end
   
       if @EstUnits <> @oldEstUnits
           begin
           select @old=convert(varchar(14),@oldEstUnits), @new=convert(varchar(14),@EstUnits)
           exec @errno = bspHQMAInsert @tablename, @key, @JCCo, 'C', 'EstUnits', @old, @new, @date, @user, @errmsg output
           if @errno <> 0 goto error
           end
   
       if @EstCost <> @oldEstCost
           begin
           select @old=convert(varchar(14),@oldEstCost), @new=convert(varchar(14),@EstCost)
           exec @errno = bspHQMAInsert @tablename, @key, @JCCo, 'C', 'EstCost', @old, @new, @date, @user, @errmsg output
           if @errno <> 0 goto error
           end
       end
   
   if @opencursor = 1
       begin
       select @rowsprocessed=@rowsprocessed+1
       goto NEXTROW
       end
   
   TRIGGEREXIT:
   
   if @opencursor = 1
       begin
       close bJCOD_update
       deallocate bJCOD_update
       end
   
   return
   
   error:
   
   if @opencursor = 1
       begin
       close bJCOD_update
       deallocate bJCOD_update
       end
   
       select @errmsg = @errmsg + ' - cannot update bJCOD!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJCOD] ON [dbo].[bJCOD] ([JCCo], [Job], [ACO], [ACOItem], [PhaseGroup], [Phase], [CostType]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCOD] ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCOD].[UnitCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCOD].[EstHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCOD].[EstUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCOD].[EstCost]'
GO
