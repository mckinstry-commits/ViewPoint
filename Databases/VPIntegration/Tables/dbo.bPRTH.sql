CREATE TABLE [dbo].[bPRTH]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[PostSeq] [smallint] NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[PostDate] [dbo].[bDate] NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[JCDept] [dbo].[bDept] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[EMCo] [dbo].[bCompany] NULL,
[WO] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[Equipment] [dbo].[bEquip] NULL,
[EMGroup] [tinyint] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[EquipCType] [dbo].[bJCCType] NULL,
[UsageUnits] [dbo].[bHrs] NULL,
[TaxState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[LocalCode] [dbo].[bLocalCode] NULL,
[UnempState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[InsState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[InsCode] [dbo].[bInsCode] NULL,
[PRDept] [dbo].[bDept] NOT NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Cert] [dbo].[bYN] NOT NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[Shift] [tinyint] NOT NULL,
[Hours] [dbo].[bHrs] NOT NULL,
[Rate] [dbo].[bUnitCost] NOT NULL,
[Amt] [dbo].[bDollar] NOT NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Memo] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[EquipPhase] [dbo].[bPhase] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NULL,
[SMWorkOrder] [int] NULL,
[SMScope] [int] NULL,
[SMPayType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SMCostType] [smallint] NULL,
[SMJCCostType] [dbo].[bJCCType] NULL,
[SMPhaseGroup] [dbo].[bGroup] NULL,
[PRTBKeyID] [bigint] NULL,
[udPaidDate] [smalldatetime] NULL,
[udCMCo] [tinyint] NULL,
[udCMAcct] [int] NULL,
[udCMRef] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[udTCSource] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[udSchool] [smallint] NULL,
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
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRTHd    Script Date: 8/28/99 9:38:15 AM ******/
   CREATE   trigger [dbo].[btPRTHd] on [dbo].[bPRTH] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 4/23/99
    *  Modified: GG 6/29/99
    *			  EN 2/18/02 - issue 13689 - do not allow delete if InUseBatchId is not null
    *			EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *										and corrected old style joins
	*			mh 05/14/09 - issue 133439/127603
    *
    *  This trigger restricts deletion of any PRTH records if
    *  lines exist in PRTA or PRTL.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   if exists(select * from deleted d where d.InUseBatchId is not null)
   	begin
   	select @errmsg='Timecard is currently in-use in a batch'
   	goto error
   	end
   
   if exists(select * from dbo.bPRTA a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
   		and a.PREndDate = d.PREndDate and a.Employee = d.Employee and a.PaySeq = d.PaySeq
   		and a.PostSeq = d.PostSeq and a.EarnCode = d.EarnCode)
   	begin
   	select @errmsg='Addon Earnings exist for this Timecard'
   	goto error
   	end
   
   if exists(select * from dbo.bPRTL a with (nolock) join deleted d on a.PRCo = d.PRCo and a.PRGroup = d.PRGroup
   		and a.PREndDate = d.PREndDate and a.Employee = d.Employee and a.PaySeq = d.PaySeq
   		and a.PostSeq = d.PostSeq)
   	begin
   	select @errmsg='Liabilities exist for this Timecard'
   	goto error
   	end
   
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
	select AttachmentID, suser_name(), 'Y' 
	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
	where d.UniqueAttchID is not null      
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PRTH!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Trigger dbo.btPRTHi    Script Date: 8/28/99 9:38:25 AM ******/
   
    CREATE    trigger [dbo].[btPRTHi] on [dbo].[bPRTH] for INSERT as
   

/*--------------------------------------------------------------
    *  Created By: EN 4/23/99
    *  Modified:   GG 6/14/99
    *  Modified:   EN 9/3/99
    *  Modified:   EN 10/30/99 - jcdept validation doesn't require PRUseJCDept set to 'Y' ... only that it's a job posting
    *              EN 3/10/00 - component type validation wasn't taking EMGroup into account causing error if same type was set up for two different groups
    *				EN 3/5/02 - issue 14181 added validation for EquipPhase
    *				SR 07/08/02 - issue 1738 declare and set @phasegroup and passing it into bspJCVPHASE
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
	*				EN 3/19/08 - #127081  modified HQST validation to include country for TaxState and UnempState
	*				MH 02/01/11 - 142827 Added support for SM.
    *
    * Insert trigger for PRTH
    *--------------------------------------------------------------*/
   declare @rcode int, @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int,
           @PRCo bCompany, @PRGroup bGroup, @PREndDate bDate, @Employee bEmployee,
           @PaySeq tinyint, @PostSeq smallint, @jcco bCompany, @job bJob,
           @phasegroup tinyint, @phase bPhase, @desc varchar(60), @contract bContract, @status tinyint,
           @lockphases bYN, @taxcode bTaxCode, @equipphase bPhase, @country char(2)
   
   select @numrows = @@rowcount, @validcnt=0, @validcnt2=0
   if @numrows = 0 return
   
   set nocount on
   
    /* validate PR Company */
    select @validcnt = count(*) from dbo.bPRCO c with (nolock)
    	join inserted i on c.PRCo = i.PRCo
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid PR Company'
    	goto error
    	end
   
    /* validate group */
    select @validcnt = count(*) from dbo.bPRGR g with (nolock)
    	join inserted i on g.PRCo = i.PRCo and g.PRGroup = i.PRGroup
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid PR Group'
    	goto error
    	end
   
    /* validate PREndDate */
    select @validcnt = count(*) from dbo.bPRPC p with (nolock)
    	join inserted i on p.PRCo = i.PRCo and p.PRGroup = i.PRGroup and p.PREndDate = i.PREndDate
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid PR Period Ending Date'
    	goto error
    	end
   
    /* validate employee */
    select @validcnt = count(*) from dbo.bPREH e with (nolock)
    	join inserted i on e.PRCo = i.PRCo and e.Employee = i.Employee
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Employee'
    	goto error
    	end
   
    /* validate pay sequence */
    select @validcnt = count(*) from dbo.bPRPS p with (nolock)
    	join inserted i on p.PRCo = i.PRCo and p.PRGroup = i.PRGroup and p.PREndDate = i.PREndDate
    	and p.PaySeq = i.PaySeq
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid pay period sequence'
    	goto error
   
    	end
   
    /* validate type */
    --142827 Added Type = 'S'
    select @validcnt = count(*) from inserted where Type = 'J' or Type = 'M' or Type = 'S'
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Type must be either J, M or S'
    	goto error
    	end
   
    /* validate phase group */
    select @validcnt = count(*) from inserted where Job is not null and Phase is not null
    	and PhaseGroup is null
   
    if @validcnt <> 0
    	begin
    	select @errmsg = 'Missing phase group'
    	goto error
    	end
    select @validcnt = count(*) from inserted where PhaseGroup is not null
    select @validcnt2 = count(*) from dbo.bHQGP g with (nolock)
    	join inserted i on g.Grp = i.PhaseGroup
    	where i.PhaseGroup is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid phase group'
    	goto error
    	end
   
    /* validate jcco/job/phase */
    -- 142827 
    select @validcnt = count(*) from inserted i where Job is not null and Phase is null
    	and Type not in ('M','S') and (select AllowNoPhase from dbo.PRCO with (nolock) where PRCo = i.PRCo) = 'N'
    if @validcnt <> 0
    	begin
    	select @errmsg = 'Missing phase'
    	goto error
    	end
    /*select @validcnt = count(*) from inserted where JCCo is not null and Job is not null
    	and Type <> 'M'
    select @validcnt2 = count(*) from bJCJP p
    	join inserted i on p.JCCo = i.JCCo and p.Job = i.Job and p.PhaseGroup = i.PhaseGroup
    	and p.Phase = i.Phase
    	where i.JCCo is not null and i.Job is not null and i.Type <> 'M'
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid phase'
    	goto error
    	end*/
    -- use standard Phase validation procedure to check Phase
    SELECT @PRCo=MIN(PRCo) from inserted
     WHILE @PRCo IS NOT NULL
     BEGIN
        SELECT @PRGroup=MIN(PRGroup) from inserted where PRCo=@PRCo
        WHILE @PRGroup IS NOT NULL
        BEGIN
           SELECT @PREndDate=MIN(PREndDate) from inserted where PRCo=@PRCo and PRGroup=@PRGroup
           WHILE @PREndDate IS NOT NULL
           BEGIN
              SELECT @Employee=MIN(Employee) from inserted
             where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDate
              WHILE @Employee IS NOT NULL
      BEGIN
                 SELECT @PaySeq=MIN(PaySeq) from inserted
                 where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDate
                 and Employee=@Employee
                 WHILE @PaySeq IS NOT NULL
                 BEGIN
                    SELECT @PostSeq=MIN(PostSeq) from inserted
                    where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDate
                    and Employee=@Employee and PaySeq=@PaySeq
                    WHILE @PostSeq IS NOT NULL
                    BEGIN
                       select @jcco=JCCo, @job=Job, @phasegroup=PhaseGroup, @phase=Phase, @equipphase=EquipPhase from inserted
                          where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDate
                          and Employee=@Employee and PaySeq=@PaySeq and PostSeq=@PostSeq
   		    /* jcco */
                       if @jcco is not null
    			begin
   			exec @rcode = bspJCCompanyVal @jcco, @errmsg output
   			if @rcode<>0 goto error
   			end
   		    /* job */
                       if @jcco is not null and @job is not null
    			begin

    			exec @rcode = bspJCJMPostVal @jcco, @job, @contract output, @status output, @lockphases output,
   				@taxcode output, @msg=@errmsg output
   			if @rcode = 1 goto error
   			if @status = 0
   				begin
   				select @errmsg = 'Job status cannot be pending'
   				goto error
   				end
   			end
   		    /* phase */
               if @jcco is not null and @job is not null and @phase is not null
                   begin
   		    	exec @rcode = bspJCVPHASE @jcco, @job, @phase, @phasegroup, 'N', @desc output, @errmsg output
   		    	if @rcode = 1 goto error
   		    	end
   		    -- issue 14181 validate equip phase
               if @jcco is not null and @job is not null and @equipphase is not null
                   begin
   		    	exec @rcode = bspJCVPHASE @jcco, @job, @equipphase, @phasegroup,'N', @desc output, @errmsg output
   		    	if @rcode = 1 goto error
   		    	end
   
                       SELECT @PostSeq=MIN(PostSeq) from inserted
   
                       where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDate
                       and Employee=@Employee and PaySeq=@PaySeq and PostSeq>@PostSeq
                    END
                    SELECT @PaySeq=MIN(PaySeq) from inserted
   
                    where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDate
                    and Employee=@Employee and PaySeq>@PaySeq
                 END
                 SELECT @Employee=MIN(Employee) from inserted
                 where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDate
                 and Employee>@Employee
              END
              SELECT @PREndDate=MIN(PREndDate) from inserted where PRCo=@PRCo
              and PRGroup=@PRGroup and PREndDate>@PREndDate
           END
           SELECT @PRGroup=MIN(PRGroup) from inserted where PRCo=@PRCo and PRGroup>@PRGroup
        END
        SELECT @PRCo=MIN(PRCo) from inserted where PRCo>@PRCo
     END
   
    /* validate JC department */
   
    /*select @validcnt = count(*) from inserted i where JCDept is not null
    	and ((Job is null and Phase is null)
    	or (select PRUseJCDept from JCCO where JCCo = i.JCCo) = 'N')
    if @validcnt <> 0
    	begin
   
    	select @errmsg = 'Invalid department'
    	goto error
    	end  - removed 10/30/99 because couldn't see how it fit in with jcdept validation scheme */
    select @validcnt = count(*) from inserted where Job is not null and Phase is not null
    select @validcnt2 = count(*) from dbo.bJCDM d with (nolock)
    	join inserted i on d.JCCo = i.JCCo and d.Department = i.JCDept
    	where i.Job is not null and i.Phase is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid department'
    	goto error
    	end
   
    /* validate GL company */
    select @validcnt = count(*) from inserted where GLCo is not null
    select @validcnt2 = count(*) from dbo.bGLCO c with (nolock)
    	join inserted i on c.GLCo = i.GLCo
    	where i.GLCo is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid GL company'
    	goto error
    	end
   
    /* validate EM company */
    select @validcnt = count(*) from inserted where EMCo is not null
    select @validcnt2 = count(*) from dbo.bEMCO c with (nolock)
    	join inserted i on c.EMCo = i.EMCo
    	where i.EMCo is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid EM company'
    	goto error
    	end
   
    /* validate equipment work order */
    select @validcnt = count(*) from inserted where WO is not null
    select @validcnt2 = count(*) from dbo.bEMWH h with (nolock)
    	join inserted i on h.EMCo = i.EMCo and h.WorkOrder = i.WO
    	where i.WO is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid work order'
    	goto error
    	end
   
    /* validate work order item */
   
    select @validcnt = count(*) from inserted where WO is not null
    select @validcnt2 = count(*) from dbo.bEMWI w with (nolock)
    	join inserted i on w.EMCo = i.EMCo and w.WorkOrder = i.WO and w.WOItem = i.WOItem
    	where i.WO is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid work order item'
    	goto error
    	end
   
    /* validate equipment code */
    select @validcnt = count(*) from inserted where Equipment is not null
    select @validcnt2 = count(*) from dbo.bEMEM e with (nolock)
    	join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Equipment
    	where i.Equipment is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment code'
    	goto error
    	end
   
    /* validate EM group */
    select @validcnt = count(*) from inserted where EMGroup is not null
    select @validcnt2 = count(*) from dbo.bHQGP g with (nolock)
   
    	join inserted i on g.Grp = i.EMGroup
    	where i.EMGroup is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid EM group'
    	goto error
    	end
   
    /* validate equipment cost code */
    select @validcnt = count(*) from inserted where Type = 'M'
    select @validcnt2 = count(*) from inserted where CostCode is not null and Type = 'M'
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Cost code is missing on Mechanic timecard'
    	goto error
    	end
    select @validcnt = count(*) from inserted where CostCode is not null and Type = 'M'
    select @validcnt2 = count(*) from dbo.bEMCC c with (nolock)
    	join inserted i on c.EMGroup = i.EMGroup and c.CostCode = i.CostCode
    	where i.CostCode is not null and Type = 'M'
    if @validcnt2 <> @validcnt
   
    	begin
    	select @errmsg = 'Invalid cost code on Mechanic timecard'
    	goto error
    	end
   
    /* validate component type */
    select @validcnt = count(*) from inserted where CompType is not null
    select @validcnt2 = count(*) from dbo.bEMTY t with (nolock)
    	join inserted i on t.ComponentTypeCode = i.CompType and t.EMGroup = i.EMGroup
    	where i.CompType is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid component type'
    	goto error
    	end
   
    /* validate component */
    select @validcnt = count(*) from inserted where CompType is not null
    select @validcnt2 = count(*) from dbo.bEMEM e with (nolock)
    	join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Component
    	where i.CompType is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid component'
    	goto error
    	end
   
    /* validate revenue code */
    select @validcnt = count(*) from inserted where Equipment is not null and Job is not null
    	and Type = 'J'
    select @validcnt2 = count(*) from inserted i
       join dbo.EMEM e with (nolock) on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join dbo.EMRC c with (nolock) on c.EMGroup=i.EMGroup and c.RevCode=i.RevCode
       join dbo.EMRR r with (nolock) on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.RevCode
           and r.Category=e.Category
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   
    /* validate equipment cost type */
    select @validcnt = count(*) from inserted where EquipCType is not null
    select @validcnt2 = count(*) from dbo.bJCCT c with (nolock)
    	join inserted i on c.PhaseGroup = i.PhaseGroup and c.CostType = i.EquipCType
    	where i.EquipCType is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
   
    	end
   
    /* validate tax state */
    select @validcnt = count(*) from inserted where TaxState is not null
    select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
		join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.TaxState
    	where i.TaxState is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid tax state'
    	goto error
    	end
   
    /* validate local code */
    select @validcnt = count(*) from inserted where LocalCode is not null
    select @validcnt2 = count(*) from dbo.bPRLI l with (nolock)
    	join inserted i on l.PRCo = i.PRCo and l.LocalCode = i.LocalCode
    	where i.LocalCode is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid local code'
    	goto error
    	end
   
    /* validate unemployment state */
    select @validcnt = count(*) from inserted where UnempState is not null
    select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
		join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.UnempState
    	where i.UnempState is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid unemployment state'
    	goto error
    	end
   
    /* validate insurance code */
    select @validcnt = count(*) from inserted where InsCode is not null
    select @validcnt2 = count(*) from dbo.bPRIN n with (nolock)
    	join inserted i on n.PRCo = i.PRCo and n.State = i.InsState and n.InsCode = i.InsCode
    	where i.InsCode is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid insurance code'
    	goto error
    	end
   
   
    /* validate PR department */
    select @validcnt = count(*) from dbo.bPRDP d with (nolock)
    	join inserted i on d.PRCo = i.PRCo and d.PRDept = i.PRDept
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid PR department'
    	goto error
    	end
   
   
    /* validate crew code */
    select @validcnt = count(*) from inserted where Crew is not null
    select @validcnt2 = count(*) from dbo.bPRCR c with (nolock)
    	join inserted i on c.PRCo = i.PRCo and c.Crew = i.Crew
    	where i.Crew is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid crew code'
    	goto error
    	end
   
    /* validate certified flag */
    select @validcnt = count(*) from inserted where Cert = 'Y' or Cert = 'N'
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Certified flag must be either Y or N'
    	goto error
    	end
   
    /* validate craft code */
    select @validcnt = count(*) from inserted where Craft is not null
    select @validcnt2 = count(*) from dbo.bPRCM c with (nolock)
    	join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft
    	where i.Craft is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid craft code'
    	goto error
    	end
   
    /* validate class code */
    select @validcnt = count(*) from inserted where Craft is not null
    select @validcnt2 = count(*) from inserted where Craft is not null and Class is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Missing class code'
    	goto error
    	end
    select @validcnt = count(*) from inserted where Craft is not null and Class is not null
    select @validcnt2 = count(*) from dbo.bPRCC c with (nolock)
    	join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft and c.Class = i.Class
    	where i.Craft is not null and i.Class is not null
    if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid class code'
    	goto error
    	end
   
    /* validate earnings code */
    select @validcnt = count(*) from dbo.bPREC e with (nolock)
    	join inserted i on e.PRCo = i.PRCo and e.EarnCode = i.EarnCode
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid earnings code'
    	goto error
    	end
   
    /* validate shift */
    select @validcnt = count(*) from inserted where Shift >= 1 and Shift <= 255
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Shift must be a number from 1 through 255'
    	goto error
    	end

   	/*142827 - Include SM Fields*/
   	IF UPDATE (SMCo)
   	BEGIN
   		SELECT @validcnt = count(1) FROM inserted WHERE SMCo is not null AND Type = 'S'
   		SELECT @validcnt2 = count(1) FROM dbo.vSMCO s 
   		JOIN inserted i on s.SMCo = i.SMCo where i.SMCo is not null AND i.Type = 'S'
   		
   		IF @validcnt2 <> @validcnt
   		BEGIN
   			SELECT @errmsg = 'Invalid SM Company.'
   			GOTO error
   		END
   	END
   		
	IF UPDATE (SMWorkOrder)
	BEGIN
		SELECT @validcnt = count(1) FROM inserted WHERE SMWorkOrder is not null
		SELECT @validcnt2 = count(1) FROM dbo.vSMWorkOrder s 
   		JOIN inserted i on s.SMCo = i.SMCo and s.WorkOrder = i.SMWorkOrder
   		WHERE i.SMWorkOrder is not null
	
	   	IF @validcnt2 <> @validcnt
   		BEGIN
   			SELECT @errmsg = 'Invalid SM Work Order.'
   			GOTO error
   		END
   	END

	IF UPDATE (SMScope)
	BEGIN
		SELECT @validcnt = count(1) FROM inserted WHERE SMScope is not null
		SELECT @validcnt2 = count(1) FROM dbo.vSMWorkOrderScope s 
   		JOIN inserted i on s.SMCo = i.SMCo and s.WorkOrder = i.SMWorkOrder and 
   		i.SMScope = s.Scope
   		WHERE i.SMScope is not null
	
	   	IF @validcnt2 <> @validcnt
   		BEGIN
   			SELECT @errmsg = 'Invalid SM Scope.'
   			GOTO error
   		END
   	END
   		
	IF UPDATE (SMPayType)
	BEGIN
		SELECT @validcnt = count(1) FROM inserted WHERE SMPayType is not null
		SELECT @validcnt2 = count(1) FROM dbo.vSMPayType s 
   		JOIN inserted i on s.SMCo = i.SMCo and s.PayType = i.SMPayType
   		WHERE i.SMPayType is not null
	
	   	IF @validcnt2 <> @validcnt
   		BEGIN
   			SELECT @errmsg = 'Invalid SM Pay Type.'
   			GOTO error
   		END
   	END   	
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot insert PRTH'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Trigger dbo.btPRTHu    Script Date: 8/28/99 9:38:26 AM ******/
   CREATE     trigger [dbo].[btPRTHu] on [dbo].[bPRTH] for UPDATE as
   
    

/***  basic declares for SQL Triggers ****/
   declare @rcode int, @numrows int, @errmsg varchar(255),
          @validcnt int, @validcnt2 int,
          @PRCo bCompany, @PRGroup bGroup, @PREndDate bDate, @Employee bEmployee,
          @PaySeq tinyint, @PostSeq smallint, @jcco bCompany, @job bJob,
          @phasegroup tinyint, @phase bPhase, @desc varchar(60), @contract bContract, @status tinyint,
           @lockphases bYN, @taxcode bTaxCode, @equipphase bPhase
   
   
   /*--------------------------------------------------------------
    *
    *  Update trigger for PRTH
    *  Created By: EN 4/23/99
    *  Modified:   EN 5/23/99
    *  Modified:   EN 9/21/99 - corrected rev code validation
    *  Modified;   GH,JC 10/6/99-corrected cost code validation for mechanic timecard
    *  Modified:   EN 10/30/99 - corrected jc dept validation
    *              EN 3/10/00 - component type validation wasn't taking EMGroup into account causing error if same type was set up for two different groups
    *			   EN 3/5/02 - issue 14181 validate EquipPhase
    *			   SR 07/08/02 - issue 1738 declare and set @phasegroup and passing it into bspJCVPHASE
    *			   EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *			   DANF 01/08/08 - issue 125049 speed up timecard batch posting process.
	*			   EN 3/19/08 - #127081  modified HQST validation to include country for TaxState and UnempState
	*			   JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
	*			   MH 02/01/11 - 142827 Added support for SM.
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount, @validcnt=0, @validcnt2=0
    if @numrows = 0 return
    set nocount on
   
    --If the only column that changed was UniqueAttachID, then skip validation.        
	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bPRTH', 'UniqueAttchID') = 1
	BEGIN 
		goto ExitTrigger
	END    
   
   /* verify primary key not changed */
   
   select @validcnt = count(*) from inserted i
   	join deleted d on d.PRCo = i.PRCo and d.PRGroup = i.PRGroup
   	and d.PREndDate = i.PREndDate and d.Employee = i.Employee
   	and d.PaySeq = i.PaySeq and d.PostSeq = i.PostSeq
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Cannot change Primary Key'
    	goto error
    	end
   
If update (Type) or update (PhaseGroup) or update (JCCo) or update (Job) or update (Phase) or update (EquipPhase) or
update (JCDept) or update (GLCo) or update (EMCo) or update (WO) or update (Equipment) or update (EMGroup) or
update (CostCode) or update (CompType) or update (RevCode) or update (EquipCType) or update (TaxState) or 
update (LocalCode) or update (UnempState) or update (InsCode) or update (PRDept) or update (Crew) or 
update (Cert) or update (Craft) or update (Class) or update (EarnCode) or update (Shift)
	goto BeginProcess
else
	goto ExitTrigger

	BeginProcess:

   /* validate type */
   --142827 Added Type = 'S'
   if update (Type)
   	begin
   	select @validcnt = count(*) from inserted where Type = 'J' or Type = 'M' or Type = 'S'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Type must be either J, M, or S'
   		goto error
   		end
   	end
   
   /* validate phase group */
   if update (PhaseGroup)
   	begin
   	select @validcnt = count(*) from inserted where Job is not null and Phase is not null
   		and PhaseGroup is null
   	if @validcnt <> 0
   		begin
   		select @errmsg = 'Missing phase group'
   		goto error
   		end
   	select @validcnt = count(*) from inserted where PhaseGroup is not null
   	select @validcnt2 = count(*) from dbo.bHQGP g with (nolock)
   		join inserted i on g.Grp = i.PhaseGroup
   		where i.PhaseGroup is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid phase group'
   		goto error
   		end
   	end
   
   /* validate jcco/job/phase */
   --142827 - Included Type = 'S' in exclusion.
   if update (JCCo) or update (Job) or update (Phase) or update (EquipPhase)
   	begin
   	select @validcnt = count(*) from inserted i where Job is not null and Phase is null
   		and Type not in ('M','S') and (select AllowNoPhase from PRCO where PRCo = i.PRCo) = 'N'
   	if @validcnt <> 0
   		begin
   		select @errmsg = 'Missing phase'
   		goto error
   		end

-----
   		-- use standard Phase validation procedure to check Phase
		if @numrows = 1
			select @jcco=JCCo, @job=Job, @phasegroup=PhaseGroup, @phase=Phase, @equipphase=EquipPhase from inserted
		else
			begin
			-- use a cursor to process each updated row
			declare PRTHUpdate cursor LOCAL FAST_FORWARD
			for select JCCo, Job, PhaseGroup, Phase, EquipPhase from inserted

			open PRTHUpdate

			fetch next from PRTHUpdate into @jcco, @job, @phasegroup, @phase, @equipphase

			if @@fetch_status <> 0
				begin
				select @errmsg = 'Cursor error'
				goto error
				end
			end
	  
	   ValidateNextRecord:

    		  /* jcco */
			if @jcco is not null
				begin
				exec @rcode = bspJCCompanyVal @jcco, @errmsg output
				if @rcode<>0 goto error
				end
    		  /* job */
			if @jcco is not null and @job is not null
				begin
				exec @rcode = bspJCJMPostVal @jcco, @job, @contract output, @status output, @lockphases output,
						@taxcode output, @msg=@errmsg output
				if @rcode = 1 goto error
				if @status = 0
					begin
					select @errmsg = 'Job status cannot be pending'
					goto error
					end
				end
    		  /* phase */
    		if @jcco is not null and @job is not null and @phase is not null
				begin
   				exec @rcode = bspJCVPHASE @jcco, @job, @phase, @phasegroup,'N', @desc output, @errmsg output
   				if @rcode = 1 goto error
				end
    		  -- issue 14181 validate equip phase
			if @jcco is not null and @job is not null and @equipphase is not null
				begin
   				exec @rcode = bspJCVPHASE @jcco, @job, @equipphase, @phasegroup,'N', @desc output, @errmsg output
   				if @rcode = 1 goto error
				end

	   FinishedVaidate:
	   if @numrows > 1
   		begin
   		fetch next from PRTHUpdate into @jcco, @job, @phasegroup, @phase, @equipphase
   		if @@fetch_status = 0
   			goto ValidateNextRecord
   		else
   			begin
   			close PRTHUpdate
   			deallocate PRTHUpdate
   			end
   		end
	end -- validate jcco/job/phase 

-----   
   /* validate JC department */
   if update (JCDept)
   	begin
   	/*select @validcnt = count(*) from inserted i where JCDept is not null
   		and ((Job is null and Phase is null)
   		or (select PRUseJCDept from JCCO where JCCo = i.JCCo) = 'N')
   	if @validcnt <> 0
   		begin
   		select @errmsg = 'Invalid department'
   		goto error
   		end*/
   	select @validcnt = count(*) from inserted where Job is not null and Phase is not null
   	select @validcnt2 = count(*) from dbo.bJCDM d with (nolock)
   		join inserted i on d.JCCo = i.JCCo and d.Department = i.JCDept
   		where i.Job is not null and i.Phase is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid department'
   		goto error
   		end
   	end
   
   /* validate GL company */
   if update (GLCo)
   	begin
   	select @validcnt = count(*) from inserted where GLCo is not null
   	select @validcnt2 = count(*) from dbo.bGLCO c with (nolock)
   		join inserted i on c.GLCo = i.GLCo
   		where i.GLCo is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid GL company'
   		goto error
   		end
   	end
   
   /* validate EM company */
   if update (EMCo)
   	begin
   	select @validcnt = count(*) from inserted where EMCo is not null
   	select @validcnt2 = count(*) from dbo.bEMCO c with (nolock)
   		join inserted i on c.EMCo = i.EMCo
   		where i.EMCo is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid EM company'
   		goto error
   		end
   	end
   
   /* validate equipment work order */
   
   if update (WO)
   	begin
   	select @validcnt = count(*) from inserted where WO is not null
   	select @validcnt2 = count(*) from dbo.bEMWH h with (nolock)
   		join inserted i on h.EMCo = i.EMCo and h.WorkOrder = i.WO
   		where i.WO is not null
   	if @validcnt2 <> @validcnt
   
   		begin
   		select @errmsg = 'Invalid work order'
   		goto error
   		end
   	end
   
   /* validate work order item */
   if update (WO)
   	begin
   	select @validcnt = count(*) from inserted where WO is not null
   	select @validcnt2 = count(*) from dbo.bEMWI w with (nolock)
   		join inserted i on w.EMCo = i.EMCo and w.WorkOrder = i.WO and w.WOItem = i.WOItem
   		where i.WO is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid work order item'
   		goto error
   		end
   	end
   
   /* validate equipment code */
   if update (Equipment)
   	begin
   	select @validcnt = count(*) from inserted where Equipment is not null
   	select @validcnt2 = count(*) from dbo.bEMEM e with (nolock)
   		join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Equipment
   		where i.Equipment is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid equipment code'
   		goto error
   		end
   	end
   
   /* validate EM group */
   if update (EMGroup)
   	begin
   	select @validcnt = count(*) from inserted where EMGroup is not null
   	select @validcnt2 = count(*) from dbo.bHQGP g with (nolock)
   		join inserted i on g.Grp = i.EMGroup
   		where i.EMGroup is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid EM group'
   		goto error
   		end
   	end
   
   
   /* validate equipment cost code */
   if update (CostCode)
   	begin
   	select @validcnt = count(*) from inserted where Type = 'M'
   	select @validcnt2 = count(*) from inserted where CostCode is not null and Type = 'M'
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Cost code is missing on Mechanic timecard'
   		goto error
   		end
   	select @validcnt = count(*) from inserted where CostCode is not null and Type = 'M'
   	select @validcnt2 = count(*) from dbo.bEMCC c with (nolock)
   		join inserted i on c.EMGroup = i.EMGroup and c.CostCode = i.CostCode
   		where i.CostCode is not null and Type = 'M'
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid cost code'
   		goto error
   		end
   	end
   
   /* validate component type */
   if update (CompType)
   	begin
   	select @validcnt = count(*) from inserted where CompType is not null
   	select @validcnt2 = count(*) from dbo.bEMTY t with (nolock)
   		join inserted i on t.ComponentTypeCode = i.CompType and t.EMGroup = i.EMGroup
   		where i.CompType is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid component type'
   		goto error
   		end
   	end
   
   /* validate component */
   if update (CompType)
   	begin
   	select @validcnt = count(*) from inserted where CompType is not null
   	select @validcnt2 = count(*) from dbo.bEMEM e with (nolock)
   		join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Component
   		where i.CompType is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid component'
   		goto error
   		end
   	end
   
   /* validate revenue code */
   if update (RevCode)
       begin
       select @validcnt = count(*) from inserted where Equipment is not null and Job is not null
        	and Type = 'J'
       select @validcnt2 = count(*) from inserted i
           join dbo.EMEM e with (nolock) on e.EMCo=i.EMCo and e.Equipment=i.Equipment
           join dbo.EMRC c with (nolock) on c.EMGroup=i.EMGroup and c.RevCode=i.RevCode
           join dbo.EMRR r with (nolock) on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.RevCode
               and r.Category=e.Category
       if @validcnt2 <> @validcnt
    	  begin
    	      select @errmsg = 'Invalid revenue code'
    	      goto error
    	  end
       end
   
   /* validate equipment cost type */
   if update (EquipCType)
   	begin
   	select @validcnt = count(*) from inserted where EquipCType is not null
   	select @validcnt2 = count(*) from dbo.bJCCT c with (nolock)
   		join inserted i on c.PhaseGroup = i.PhaseGroup and c.CostType = i.EquipCType
   		where i.EquipCType is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid equipment cost type'
   		goto error
   		end
   	end
   
   /* validate tax state */
   if update (TaxState)
   	begin
   	select @validcnt = count(*) from inserted where TaxState is not null
    select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
		join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.TaxState
   		where i.TaxState is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid tax state'
   		goto error
   		end
   	end
   
   /* validate local code */
   if update (LocalCode)
   	begin
   	select @validcnt = count(*) from inserted where LocalCode is not null
   	select @validcnt2 = count(*) from dbo.bPRLI l with (nolock)
   		join inserted i on l.PRCo = i.PRCo and l.LocalCode = i.LocalCode
   
   		where i.LocalCode is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid local code'
   		goto error
   		end
   	end
   
   /* validate unemployment state */
   if update (UnempState)
   	begin
   	select @validcnt = count(*) from inserted where UnempState is not null
    select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
		join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.UnempState
   		where i.UnempState is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid unemployment state'
   		goto error
   		end
   	end
   
   /* validate insurance code */
   if update (InsCode)
   	begin
   	select @validcnt = count(*) from inserted where InsCode is not null
   	select @validcnt2 = count(*) from dbo.bPRIN n with (nolock)
   		join inserted i on n.PRCo = i.PRCo and n.State = i.InsState and n.InsCode = i.InsCode
   		where i.InsCode is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid insurance code'
   		goto error
   		end
   	end
   
   /* validate PR department */
   if update (PRDept)
   	begin
   	select @validcnt = count(*) from dbo.bPRDP d with (nolock)
   		join inserted i on d.PRCo = i.PRCo and d.PRDept = i.PRDept
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid PR department'
   		goto error
   		end
   	end
   
   /* validate crew code */
   if update (Crew)
   	begin
   	select @validcnt = count(*) from inserted where Crew is not null
   	select @validcnt2 = count(*) from dbo.bPRCR c with (nolock)
   		join inserted i on c.PRCo = i.PRCo and c.Crew = i.Crew
   		where i.Crew is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid crew code'
   		goto error
   		end
   	end
   
   /* validate certified flag */
   if update (Cert)
   	begin
   	select @validcnt = count(*) from inserted where Cert = 'Y' or Cert = 'N'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Certified flag must be either Y or N'
   		goto error
   		end
   	end
   
   /* validate craft code */
   if update (Craft)
   	begin
   	select @validcnt = count(*) from inserted where Craft is not null
   	select @validcnt2 = count(*) from dbo.bPRCM c with (nolock)
   		join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft
   		where i.Craft is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid craft code'
   		goto error
   		end
   	end
   
   /* validate class code */
   if update (Class)
   	begin
   	select @validcnt = count(*) from inserted where Craft is not null
   	select @validcnt2 = count(*) from inserted where Craft is not null and Class is not null
   	if @validcnt2 <> @validcnt
    		begin
    		select @errmsg = 'Missing class code'
    		goto error
    		end
   	select @validcnt = count(*) from inserted where Craft is not null and Class is not null
   	select @validcnt2 = count(*) from dbo.bPRCC c with (nolock)
   		join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft and c.Class = i.Class
   		where i.Craft is not null and i.Class is not null
   	if @validcnt2 <> @validcnt
   		begin
   		select @errmsg = 'Invalid class code'
   		goto error
   		end
   	end
   
   /* validate earnings code */
   if update (EarnCode)
   	begin
   	select @validcnt = count(*) from dbo.bPREC e with (nolock)
   		join inserted i on e.PRCo = i.PRCo and e.EarnCode = i.EarnCode
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid earnings code'
   		goto error
   		end
   	end
   
   /* validate shift */
   if update (Shift)
   	begin
   	select @validcnt = count(*) from inserted where Shift >= 1 and Shift <= 255
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Shift must be a number from 1 through 255'
   		goto error
   		end
   	end
   	
   	/*142827 - Include SM Fields*/
   	IF UPDATE (SMCo)
   	BEGIN
   		SELECT @validcnt = count(1) FROM inserted WHERE SMCo is not null AND Type='S'
   		SELECT @validcnt2 = count(1) FROM dbo.vSMCO s 
   		JOIN inserted i on s.SMCo = i.SMCo where i.SMCo is not null AND i.Type='S'
   		
   		IF @validcnt2 <> @validcnt
   		BEGIN
   			SELECT @errmsg = 'Invalid SM Company.'
   			GOTO error
   		END
   	END
   		
	IF UPDATE (SMWorkOrder)
	BEGIN
		SELECT @validcnt = count(1) FROM inserted WHERE SMWorkOrder is not null
		SELECT @validcnt2 = count(1) FROM dbo.vSMWorkOrder s 
   		JOIN inserted i on s.SMCo = i.SMCo and s.WorkOrder = i.SMWorkOrder
   		WHERE i.SMWorkOrder is not null
	
	   	IF @validcnt2 <> @validcnt
   		BEGIN
   			SELECT @errmsg = 'Invalid SM Work Order.'
   			GOTO error
   		END
   	END

	IF UPDATE (SMScope)
	BEGIN
		SELECT @validcnt = count(1) FROM inserted WHERE SMScope is not null
		SELECT @validcnt2 = count(1) FROM dbo.vSMWorkOrderScope s 
   		JOIN inserted i on s.SMCo = i.SMCo and s.WorkOrder = i.SMWorkOrder and 
   		i.SMScope = s.Scope
   		WHERE i.SMScope is not null
	
	   	IF @validcnt2 <> @validcnt
   		BEGIN
   			SELECT @errmsg = 'Invalid SM Scope.'
   			GOTO error
   		END
   	END
   		
	IF UPDATE (SMPayType)
	BEGIN
		SELECT @validcnt = count(1) FROM inserted WHERE SMPayType is not null
		SELECT @validcnt2 = count(1) FROM dbo.vSMPayType s 
   		JOIN inserted i on s.SMCo = i.SMCo and s.PayType = i.SMPayType
   		WHERE i.SMPayType is not null
	
	   	IF @validcnt2 <> @validcnt
   		BEGIN
   			SELECT @errmsg = 'Invalid SM Pay Type.'
   			GOTO error
   		END
   	END   	



ExitTrigger: 
 
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot update PRTH'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRTH] ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPRTHEarnCode] ON [dbo].[bPRTH] ([PRCo], [Employee], [EarnCode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPRTHEmpPostDate] ON [dbo].[bPRTH] ([PRCo], [Employee], [PostDate], [InUseBatchId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPRTHEmpPREndDate] ON [dbo].[bPRTH] ([PRCo], [Employee], [PREndDate], [InUseBatchId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPRTHJobPostDate] ON [dbo].[bPRTH] ([PRCo], [JCCo], [Job], [PostDate], [InUseBatchId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPRTHJobEndDate] ON [dbo].[bPRTH] ([PRCo], [JCCo], [Job], [PREndDate], [InUseBatchId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ciPRTHJobCMRef] ON [dbo].[bPRTH] ([PRCo], [PREndDate], [Employee], [PaySeq], [Job], [udCMRef]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ciPRTHCMRef] ON [dbo].[bPRTH] ([PRCo], [PREndDate], [Employee], [PaySeq], [udCMRef]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRTH] ON [dbo].[bPRTH] ([PRCo], [PRGroup], [PREndDate], [Employee], [PaySeq], [PostSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPRTH_PRTBKeyID] ON [dbo].[bPRTH] ([PRTBKeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPRTHUniqueAttchID] ON [dbo].[bPRTH] ([UniqueAttchID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRTH].[Cert]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRTH].[Rate]'
GO
