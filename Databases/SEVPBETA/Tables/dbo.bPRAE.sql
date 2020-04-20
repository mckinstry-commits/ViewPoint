CREATE TABLE [dbo].[bPRAE]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[Seq] [tinyint] NOT NULL,
[PaySeq] [tinyint] NULL,
[PRDept] [dbo].[bDept] NULL,
[InsCode] [dbo].[bInsCode] NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[GLCo] [dbo].[bCompany] NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[UsageUnits] [dbo].[bHrs] NULL,
[StdHours] [dbo].[bYN] NOT NULL,
[Hours] [dbo].[bHrs] NULL,
[RateAmt] [dbo].[bUnitCost] NOT NULL,
[LimitOvrAmt] [dbo].[bDollar] NOT NULL,
[Frequency] [dbo].[bFreq] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[OvrStdLimitYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRAE_OvrStdLimitYN] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[MechanicsCC] [dbo].[bCostCode] NULL,
[EquipMechOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPRAE_EquipMechOpt] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UseRegRate] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRAE_UseRegRate] DEFAULT ('N'),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRAEd    Script Date: 8/28/99 9:38:11 AM ******/
   CREATE  trigger [dbo].[btPRAEd] on [dbo].[bPRAE] for DELETE as
   

/*-----------------------------------------------------------------
    *	Created by: EN 4/3/00
    *				EN 12/10/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	Adds HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   INSERT INTO dbo.bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
           SELECT 'bPRAE', 'Empl:' + convert(varchar(10), Employee) + ' Earn Code:' + convert(varchar(10),EarnCode) +
           ' Seq:' + convert(varchar(10),Seq), d.PRCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	    JOIN dbo.bPRCO a with (nolock) ON d.PRCo=a.PRCo
           where a.AuditEmployees='Y'
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Automatic Earnings!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Trigger dbo.btPRAEi    Script Date: 8/28/99 9:38:11 AM ******/
    CREATE      trigger [dbo].[btPRAEi] on [dbo].[bPRAE] for INSERT as
    

/*-----------------------------------------------------------------
     *   	Created by: EN 4/3/00
     *			Modified: SR 07/09/02- 17738 pass @phasegroup to bspJCVPHASE
     *					  GF 12/10/2002 - Issue #19618 - Found problem during CV not passing phasegroup to validation. Throws error.
     *					EN 12/10/03 - issue 23061  added isnull check, with (nolock), and dbo and corrected old syle joins
     *
     * Validate PR Company, Employee, Earn Code, PRDept, InsCode, Craft, Class,
     *     Phase Group, JC Company, Job, Phase, GL Company, EM Company, Equipment,
     *     EMGroup, RevCode and Frequency.
     *	Adds HQ Master Audit entry.
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, @PRCo bCompany, @Employee bEmployee,
           @EarnCode bEDLCode, @Seq tinyint, @jcco bCompany, @job bJob, @phase bPhase, @desc varchar(60),
           @contract bContract, @status tinyint, @lockphases bYN, @taxcode bTaxCode, @rcode int, @country char(2)
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* validate PR Company */
    select @validcnt = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Company# '
    	goto error
    	end
   
    /* validate Employee */
    select @validcnt = count(*) from dbo.bPREH c with (nolock) join inserted i on c.PRCo = i.PRCo
    	and c.Employee=i.Employee
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Employee # '
    	goto error
    	end
   
    /* validate Earn Code */
    select @validcnt = count(*) from inserted i join dbo.PREC a with (nolock) on a.PRCo=i.PRCo and i.EarnCode=a.EarnCode
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Earnings Code '
    	goto error
    	end
   
    /* validate PRDept */
    select @validcnt = count(*) from inserted where PRDept is not null
    select @validcnt2 = count(*) from inserted i join dbo.PRDP d with (nolock) on d.PRCo = i.PRCo and d.PRDept = i.PRDept
       where i.PRDept is not null
    if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Invalid Department Code '
    	goto error
    	end
   
    /* validate InsCode */
    select @validcnt = count(*) from inserted where InsCode is not null
    select @validcnt2 = count(*) from inserted i join dbo.HQIC c with (nolock) on c.InsCode = i.InsCode where i.InsCode is not null
    if @validcnt <> @validcnt2
       begin
       select @errmsg = 'Invalid Insurance Code '
       goto error
       end
   
    /* validate Craft */
    select @validcnt = count(*) from inserted where Craft is not null
    select @validcnt2 = count(*) from inserted i join dbo.PRCM c with (nolock) on c.PRCo = i.PRCo and c.Craft = i.Craft where i.Craft is not null
    if @validcnt <> @validcnt2
       begin
       select @errmsg = 'Invalid Craft Code '
       goto error
       end
   
    /* validate Class */
    select @validcnt = count(*) from inserted where Class is not null
    select @validcnt2 = count(*) from inserted i join dbo.PRCC c with (nolock) on c.PRCo = i.PRCo and c.Craft = i.Craft and c.Class = i.Class
       where i.Class is not null
    if @validcnt <> @validcnt2
       begin
       select @errmsg = 'Invalid Class Code '
       goto error
       end
   
    /* validate Phase Group */
    declare @phasegroup tinyint
    select @phasegroup=PhaseGroup from inserted
    select @validcnt = count(*) from inserted where PhaseGroup is not null
    select @validcnt2 = count(*) from dbo.bHQGP g with (nolock) join inserted i on g.Grp = i.PhaseGroup
    	where i.PhaseGroup is not null
    if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Invalid phase group '
    	goto error
    	end
   
    /* validate JC Company/Job/Phase */
    -- use standard Phase validation procedure to check Phase
    SELECT @PRCo=MIN(PRCo) from inserted
    WHILE @PRCo
    IS NOT NULL
       BEGIN
       SELECT @Employee=MIN(Employee) from inserted where PRCo=@PRCo
       WHILE @Employee IS NOT NULL
           BEGIN
           SELECT @EarnCode=MIN(EarnCode) from inserted where PRCo=@PRCo and Employee=@Employee
           WHILE @EarnCode IS NOT NULL
               BEGIN
               SELECT @Seq=MIN(Seq) from inserted where PRCo=@PRCo and Employee=@Employee and EarnCode=@EarnCode
               WHILE @Seq IS NOT NULL
                   BEGIN
                   select @jcco=JCCo, @job=Job, @phase=Phase, @phasegroup=PhaseGroup from inserted
                      where PRCo=@PRCo and Employee=@Employee and EarnCode=@EarnCode and Seq=@Seq
   	            /* jcco */
                   if @jcco is not null
   					begin
               		exec @rcode = bspJCCompanyVal @jcco, @errmsg output
   					if @rcode <> 0 goto error
               		end
           	    /* job */
                   if @jcco is not null and @job is not null
               		begin
               		exec @rcode = bspJCJMPostVal @jcco, @job, @contract output, @status output, @lockphases output,
               		      @taxcode output, @msg=@errmsg output
               		if @rcode <> 0 goto error
               		end
           	    /* phase */
                   if @jcco is not null and @job is not null and @phase is not null
                       begin
        	    		exec @rcode = bspJCVPHASE @jcco, @job, @phase,@phasegroup, 'N', @desc output, @errmsg output
           	    	if @rcode = 1 goto error
           	    	end
                   SELECT @Seq=MIN(Seq) from inserted where PRCo=@PRCo and Employee=@Employee and EarnCode=@EarnCode and Seq>@Seq
                   END
               SELECT @EarnCode=MIN(EarnCode) from inserted where PRCo=@PRCo and Employee=@Employee and EarnCode>@EarnCode
               END
           SELECT @Employee=MIN(Employee) from inserted where PRCo=@PRCo and Employee>@Employee
           END
       SELECT @PRCo=MIN(PRCo) from inserted where PRCo>@PRCo
       END
   
    /* validate GL Company */
    select @validcnt = count(*) from inserted where GLCo is not null
    select @validcnt2 = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.GLCo where i.GLCo is not null
    if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Invalid GL Company '
    	goto error
    	end
   
    /* validate EM Company */
    select @validcnt = count(*) from inserted where EMCo is not null
    select @validcnt2 = count(*)
    from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.EMCo where i.EMCo is not null
    if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Invalid EM Company '
    	goto error
    	end
   
    /* validate Equipment */
    select @validcnt = count(*) from inserted where Equipment
    is not null
    select @validcnt2 = count(*) from dbo.bEMEM e with (nolock) join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Equipment
    	where i.Equipment is not null
    if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Invalid Equipment Code '
    	goto error
    	end
   
    
   /* validate EM group */
    select @validcnt = count(*) from inserted where EMGroup is not null
    select @validcnt2 = count(*) from dbo.bHQGP g with (nolock) join inserted i on g.Grp = i.EMGroup where i.EMGroup is not null
    if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Invalid EM Group '
    	goto error
    	end
   
    /* validate Revenue Code */
    select @validcnt = count(*) from inserted where Equipment is not null and RevCode is not null
    select @validcnt2 = count(*) from inserted i
       join dbo.EMRR r with (nolock) on r.EMCo = i.EMCo and r.EMGroup = i.EMGroup and r.RevCode = i.RevCode
       join dbo.EMEM m with (nolock) on m.EMCo = i.EMCo and m.Category = r.Category and m.Equipment = i.Equipment
       where i.Equipment is not null and i.RevCode is not null
    if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Invalid Revenue Code '
    	goto error
    	end
   
    /* validate Frequency */
    select @validcnt = count(*) from inserted i join dbo.HQFC f with (nolock) on i.Frequency = f.Frequency
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Frequency Code '
    	goto error
    	end
   
    /* add HQ Master Audit entry */
    insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	 select 'bPRAE',  'Empl:' + convert(varchar(10), Employee) + ' Earn Code:' + convert(varchar(10),EarnCode) +
        ' Seq:' + convert(varchar(10),Seq), i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME()
        from inserted i join dbo.PRCO a with (nolock) on i.PRCo=a.PRCo where a.AuditEmployees = 'Y'
   
   
    return
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Automatic Earnings!'
   
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
 /****** Object:  Trigger dbo.btPRAEu    Script Date: 8/28/99 9:38:12 AM ******/
 CREATE       trigger [dbo].[btPRAEu] on [dbo].[bPRAE] for UPDATE as
 

/*-----------------------------------------------------------------
  *   	Created by: EN 4/3/00
  *                              EN 10/09/00 - Checking for key changes incorrectly
  *					SR 07/09/02 SR - 17738 pass @phasegroup to bspJCVPHASE
  *					EN 12/10/03 - issue 23061  added isnull check, with (nolock), and dbo
  *					mh 1/9/06 - issue 119758/119804 - removed the length from the convert(varchar(x), y).
  *
  *	Reject key changes
  *  Validate PRDept, InsCode, Craft, Class, Phase Group, JC Company, Job,
  *      Phase, GL Company, EM Company, Equipment, EMGroup, RevCode and Frequency.
  *	Adds HQ Master Audit entry.
  */----------------------------------------------------------------
 declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, @PRCo bCompany, @Employee bEmployee,
         @EarnCode bEDLCode, @Seq tinyint, @jcco bCompany, @job bJob, @phase bPhase, @desc varchar(60),
         @contract bContract, @status tinyint, @lockphases bYN, @taxcode bTaxCode, @rcode int
 select @numrows = @@rowcount
 if @numrows = 0 return
 set nocount on
 
 /* check for key changes */
 if update(PRCo)
     begin
     select @validcnt = count(*) from deleted d join inserted i on d.PRCo = i.PRCo
     if @validcnt <> @numrows
       	begin
       	select @errmsg = 'Cannot change PR Company '
       	goto error
       	end
     end
 if update(Employee)
     begin
     select @validcnt = count(*) from deleted d join inserted i on d.PRCo = i.PRCo
         and d.Employee = i.Employee
     if @validcnt <> @numrows
       	begin
       	select @errmsg = 'Cannot change Employee '
       	goto error
       	end
     end
 if update(EarnCode)
     begin
     select @validcnt = count(*) from deleted d join inserted i on d.PRCo = i.PRCo
         and d.Employee = i.Employee and d.EarnCode = i.EarnCode
     if @validcnt <> @numrows
       	begin
       	select @errmsg = 'Cannot change Earnings Code '
       	
 goto error
       	end
     end
 if update(Seq)
     begin
     select @validcnt = count(*) from deleted d join inserted i on d.PRCo = i.PRCo
         and d.Employee = i.Employee and d.EarnCode = i.EarnCode and d.Seq = i.Seq
     if @validcnt <> @numrows
       	
 begin
       	select @errmsg = 'Cannot change Seq '
       	goto error
       	end
     end
 
  /* validate PRDept */
  if update(PRDept)
     begin
      select @validcnt = count(*) from inserted where PRDept is not null
      select @validcnt2 = count(*) from inserted i join dbo.PRDP d with (nolock) on d.PRCo = i.PRCo and d.PRDept = i.PRDept
         where i.PRDept is not null
      if @validcnt <> @validcnt2
      	begin
      	select @errmsg = 'Invalid Department Code '
      	goto error
      	end
     end
 
  /* validate InsCode */
  if
  update(InsCode)
     begin
      select @validcnt = count(*) from inserted where InsCode is not null
      select @validcnt2 = count(*) from inserted i join dbo.HQIC c with (nolock) on c.InsCode = i.InsCode where i.InsCode is not null
      if @validcnt <> @validcnt2
       begin
         select @errmsg = 'Invalid Insurance Code '
         goto error
         end
     end
 
  /* validate Craft */
  if update(Craft)
     begin
      select @validcnt = count(*) from inserted where Craft is not null
      select @validcnt2 = count(*) from inserted i join dbo.PRCM c with (nolock) on c.PRCo = i.PRCo and c.Craft = i.Craft where i.Craft is not null
      if @validcnt <> @validcnt2
         begin
         select @errmsg = 'Invalid Craft Code '
         goto error
         end
     end
 
  /* validate Class */
  if update(Class)
     begin
      select @validcnt = count(*) from inserted where Class is not null
      select @validcnt2 = count(*) from inserted i join dbo.PRCC c with (nolock) on c.PRCo = i.PRCo and c.Craft = i.Craft and c.Class = i.Class
         where i.Class is not null
      
 
 if @validcnt <> @validcnt2
         begin
         select @errmsg = 'Invalid Class Code '
         goto error
         end
     end
 
  /* validate Phase Group */
 declare @phasegroup tinyint
 select @phasegroup=PhaseGroup from inserted
  if update(PhaseGroup)
     begin
      select @validcnt = count(*) from inserted where PhaseGroup is not null
      select @validcnt2 = count(*) from dbo.bHQGP g with (nolock) join inserted i on g.Grp = i.PhaseGroup
      	where i.PhaseGroup is not null
      if @validcnt <> @validcnt2
      	begin
      	select @errmsg = 'Invalid phase group '
      	goto error
      	end
     end
 
  /* validate JC Company/Job/Phase */
  if update(JCCo) or update(Job) or update(Phase)
     begin
      -- use standard Phase validation procedure to check Phase
      SELECT @PRCo=MIN(PRCo) from inserted
      WHILE @PRCo IS NOT NULL
         BEGIN
       
   SELECT @Employee=MIN(Employee) from inserted where PRCo=@PRCo
         WHILE @Employee IS NOT NULL
             BEGIN
             SELECT @EarnCode=MIN(EarnCode) from inserted where PRCo=@PRCo and Employee=@Employee
             WHILE @EarnCode IS NOT NULL
 
                 BEGIN
                 SELECT @Seq=MIN(Seq) from inserted where PRCo=@PRCo and Employee=@Employee and EarnCode=@EarnCode
                 WHILE @Seq IS NOT NULL
                     BEGIN
                     select @jcco=JCCo, @job=Job, @phase=Phase from inserted
                        where PRCo=@PRCo and Employee=@Employee and EarnCode=@EarnCode and Seq=@Seq
     	            /* jcco */
                     if @jcco is not null
                 		begin
                 		exec @rcode = bspJCCompanyVal @jcco, @errmsg output
                 		if @rcode <> 0 goto error
                 		end
             	    /* job */
                     if @jcco is not null and @job is not null
                 		begin
                 		exec @rcode = bspJCJMPostVal @jcco, @job, @contract output, @status output, @lockphases output,
                 		      @taxcode output, @msg=@errmsg output
                 		if @rcode <> 0 goto error
                 		end
             	    /* phase */
                     if @jcco is not null and @job is not null and @phase is not null
                         begin
             	    	exec @rcode = bspJCVPHASE @jcco, @job, @phase, @phasegroup,'N', @desc output, @errmsg output
             	    	if @rcode = 1 goto error
             	    	end
 
        
              SELECT @Seq=MIN(Seq) from inserted where PRCo=@PRCo and Employee=@Employee and EarnCode=@EarnCode and Seq>@Seq
                     END
                 SELECT @EarnCode=MIN(EarnCode) from inserted where PRCo=@PRCo and Employee=@Employee and EarnCode>@EarnCode
                 END
             SELECT @Employee=MIN(Employee) from inserted where PRCo=@PRCo and Employee>@Employee
             END
         SELECT @PRCo=MIN(PRCo) from inserted where PRCo>@PRCo
         END
     end
 
  /* validate GL Company */
  if update(GLCo)
     begin
      select @validcnt = count(*) from inserted where GLCo is not null
      select @validcnt2 = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.GLCo where i.GLCo is not null
      if @validcnt <> @validcnt2
      	begin
   
    	select @errmsg = 'Invalid GL Company '
      	goto error
      	end
     end
 
  /* validate EM Company */
  if update(EMCo)
     begin
      select @validcnt = count(*) from inserted where EMCo is not null
      select @validcnt2 = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.EMCo where i.EMCo is not null
      if @validcnt <> @validcnt2
      	begin
      	select @errmsg = 'Invalid EM Company '
      	goto error
      	end
     end
 
  /* validate Equipment */
  if update(Equipment)
     begin
      select @validcnt = count(*) from inserted where Equipment is not null
      select @validcnt2 = count(*) from dbo.bEMEM e with (nolock) join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Equipment
      	where i.Equipment is not null
      if @validcnt <> @validcnt2
      	begin
      
 	select @errmsg = 'Invalid Equipment Code '
      	goto error
      	end
     end
 
  /* validate EM group */
  if update(EMGroup)
     begin
      select @validcnt = count(*) from inserted where EMGroup is not null
      select @validcnt2 = count(*) from dbo.bHQGP g with (nolock) join inserted i on g.Grp = i.EMGroup where i.EMGroup is not null
      if @validcnt <> @validcnt2
      	begin
      	select @errmsg = 'Invalid EM Group '
      	goto error
      	end
     end
 
  /* validate Revenue Code */
  if update(RevCode)
     begin
      select @validcnt = count(*) from inserted where Equipment is not null and RevCode is not null
   select @validcnt2 = count(*) from inserted i
         join dbo.EMRR r with (nolock) on r.EMCo = i.EMCo and r.EMGroup = i.EMGroup and r.RevCode = i.RevCode
         join dbo.EMEM m with (nolock) on m.EMCo = i.EMCo and m.Category = r.Category and m.Equipment = i.Equipment
         where i.Equipment is not null and i.RevCode is not null
      if @validcnt <> @validcnt2
      	begin
      	select @errmsg = 'Invalid Revenue Code '
      	goto error
      	end
   
   end
 
  /* validate Frequency */
  if update(Frequency)
     begin
      select @validcnt = count(*) from inserted i join dbo.HQFC f with (nolock) on i.Frequency = f.Frequency
      if @validcnt <> @numrows
      	begin
      	select @errmsg = 'Invalid Frequency Code '
      	goto error
      	end
     end
 
 /* add HQ Master Audit entry */
 if exists (select * from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditEmployees = 'Y')
 	begin
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' EarnCode:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','Pay Seq', convert(varchar,d.PaySeq), convert(varchar,i.PaySeq),
         getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.PaySeq,0) <> isnull(i.PaySeq,0) and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','PR Dept', d.PRDept, i.PRDept,
         getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.PRDept,'') <> isnull(i.PRDept,'') and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','Insurance Code', d.InsCode, i.InsCode,
         getdate(), SUSER_SNAME() from inserted i
      
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.InsCode,'') <> isnull(i.InsCode,'') and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','Craft', d.Craft, i.Craft,
         getdate(), SUSER_SNAME() from inserted i
 
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.Craft,'') <> isnull(i.Craft,'') and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','Class', d.Class, i.Class,
         getdate(), SUSER_SNAME() from inserted i
 
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.Class,'') <> isnull(i.Class,'') and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','JC Company', convert(varchar(3),d.JCCo), convert(varchar(3),i.JCCo),
     
     getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.JCCo,0) <> isnull(i.JCCo,0) and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','Job', d.Job, i.Job,
         getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.Job,'') <> isnull(i.Job,'') and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','Phase Group', convert(varchar(3),d.PhaseGroup), convert(varchar(3),i.PhaseGroup),
         getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.PhaseGroup,0) <> isnull(i.PhaseGroup,0) and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','Phase', d.Phase, i.Phase,
         getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
   
       where isnull(d.Phase,'') <> isnull(i.Phase,'') and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','GL Company', convert(varchar(3),d.GLCo), convert(varchar(3),i.GLCo),
         getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.GLCo,0) <> isnull(i.GLCo,0) and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','EM Company', convert(varchar(3),d.EMCo), convert(varchar(3),i.EMCo),
         getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.EMCo,0) <> isnull(i.EMCo,0) and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','Equipment', d.Equipment, i.Equipment,
         getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.Equipment,'') <> isnull(i.Equipment,'') and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','EM Group', convert(varchar(3),d.EMGroup), convert(varchar(3),i.EMGroup),
         getdate(), SUSER_SNAME() from inserted i        
 join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.EMGroup,0) <> isnull(i.EMGroup,0) and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','Revenue Code', d.RevCode, i.RevCode,
         getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.RevCode,'') <> isnull(i.RevCode,'') and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','Usage Units', convert(varchar,d.UsageUnits), convert(varchar,i.UsageUnits),
         getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.UsageUnits,0) <> isnull(i.UsageUnits,0) and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','Standard Hours', convert(varchar,d.StdHours), convert(varchar,i.StdHours),
         getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
     
     join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where d.StdHours <> i.StdHours and a.AuditEmployees = 'Y'
      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','Hours', convert(varchar,d.Hours), convert(varchar,i.Hours),
         getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.Hours,0) <> isnull(i.Hours,0) and a.AuditEmployees = 'Y'

      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','RateAmt', convert(varchar,d.RateAmt), convert(varchar,i.RateAmt),
         getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.RateAmt,0) <> isnull(i.RateAmt,0) and a.AuditEmployees = 'Y'

      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','Limit Override Amount', convert(varchar,d.LimitOvrAmt), convert(varchar,i.LimitOvrAmt),
         getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.LimitOvrAmt,0) <> isnull(i.LimitOvrAmt,0) and a.AuditEmployees = 'Y'

      insert into dbo.bHQMA select 'bPRAE', 'Empl:' + convert(varchar, i.Employee) + ' Earn Code:' +
         convert(varchar,i.EarnCode) + ' Seq:' + convert(varchar,i.Seq),
      	i.PRCo, 'C','Frequency', d.Frequency, i.Frequency,        
 		getdate(), SUSER_SNAME() from inserted i
         join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.EarnCode = d.EarnCode and i.Seq = d.Seq
         join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
         where isnull(d.Frequency,'') <> isnull(i.Frequency,'') and a.AuditEmployees = 'Y'
     end
 
 
 return
 error:
 	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Automatic Earnings!'
 	RAISERROR(@errmsg, 11, -1);
 	rollback transaction
 
 
 
 
 
 
 
 
 
 





GO
ALTER TABLE [dbo].[bPRAE] ADD CONSTRAINT [PK_bPRAE_KeyID] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRAE] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRAE] ON [dbo].[bPRAE] ([PRCo], [Employee], [EarnCode], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRAE].[StdHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRAE].[RateAmt]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRAE].[OvrStdLimitYN]'
GO
