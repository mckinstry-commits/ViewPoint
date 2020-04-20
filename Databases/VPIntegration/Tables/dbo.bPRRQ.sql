CREATE TABLE [dbo].[bPRRQ]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PostDate] [dbo].[bDate] NOT NULL,
[SheetNum] [smallint] NOT NULL,
[EMCo] [dbo].[bCompany] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[Employee] [dbo].[bEmployee] NULL,
[Phase1Usage] [dbo].[bHrs] NULL,
[Phase1CType] [dbo].[bJCCType] NULL,
[Phase1Rev] [dbo].[bRevCode] NULL,
[Phase2Usage] [dbo].[bHrs] NULL,
[Phase2CType] [dbo].[bJCCType] NULL,
[Phase2Rev] [dbo].[bRevCode] NULL,
[Phase3Usage] [dbo].[bHrs] NULL,
[Phase3CType] [dbo].[bJCCType] NULL,
[Phase3Rev] [dbo].[bRevCode] NULL,
[Phase4Usage] [dbo].[bHrs] NULL,
[Phase4CType] [dbo].[bJCCType] NULL,
[Phase4Rev] [dbo].[bRevCode] NULL,
[Phase5Usage] [dbo].[bHrs] NULL,
[Phase5CType] [dbo].[bJCCType] NULL,
[Phase5Rev] [dbo].[bRevCode] NULL,
[Phase6Usage] [dbo].[bHrs] NULL,
[Phase6CType] [dbo].[bJCCType] NULL,
[Phase6Rev] [dbo].[bRevCode] NULL,
[Phase7Usage] [dbo].[bHrs] NULL,
[Phase7CType] [dbo].[bJCCType] NULL,
[Phase7Rev] [dbo].[bRevCode] NULL,
[Phase8Usage] [dbo].[bHrs] NULL,
[Phase8CType] [dbo].[bJCCType] NULL,
[Phase8Rev] [dbo].[bRevCode] NULL,
[LineSeq] [smallint] NOT NULL CONSTRAINT [DF_bPRRQ_LineSeq] DEFAULT ((1)),
[TotalUsage] [dbo].[bHrs] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE        trigger [dbo].[btPRRQi] on [dbo].[bPRRQ] for INSERT as
   

	/*-----------------------------------------------------------------
    *   	Created by: EN 2/21/03
    *		Modified:	EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
	*					MH 02/06/09 - issue 131950 - Reject inserts if bPRRH.Status > 0
    *
    * Validates PRCo, Crew, PostDate, and SheetNum against bPRRH.
    * Validates EM company, EM Group, Equipment, Employee, Cost Types, and Revenue Codes.
    *
    */----------------------------------------------------------------

   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
	/*Reject updates if Timesheet is locked, no need to check anything else if locked or
	status is greater then zero*/

	if exists(select 1 from bPRRH h join inserted i on h.PRCo = i.PRCo and h.Crew = i.Crew and
	h.PostDate = i.PostDate and h.SheetNum = i.SheetNum and h.Status > 0)
	begin
		select @errmsg = 'Timesheet has been locked and cannot be edited.'
		goto error
	end

   /* validate PR Company, Crew, PostDate, and Sheet number against bPRRH */
   select @validcnt = count(*) from dbo.bPRRH c with (nolock)
   join inserted i on c.PRCo=i.PRCo and c.Crew=i.Crew and c.PostDate=i.PostDate and c.SheetNum=i.SheetNum
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Timesheet'
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
   
   /* validate employee */
   select @validcnt = count(*) from inserted where Employee is not null
   select @validcnt2 = count(*) from dbo.bPREH e with (nolock)
    	join inserted i on e.PRCo = i.PRCo and e.Employee = i.Employee
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid Employee'
    	goto error
    	end
   
   /* validate equipment cost types */
   --The following missing cost type validation commented out because cost type may be missing
   --due to PRCrewTSEntry hide cost type option being checked.  -- EN
   --select @validcnt = count(*) from inserted i
   --join bPRRH h on i.PRCo=h.PRCo and i.Crew=h.Crew and i.PostDate=h.PostDate and i.SheetNum=h.SheetNum
   --where (h.Phase1 is not null and Phase1CType is null) or (h.Phase2 is not null and Phase2CType is null) or
   --	(h.Phase3 is not null and Phase3CType is null) or (h.Phase4 is not null and Phase4CType is null) or
   --	(h.Phase5 is not null and Phase5CType is null) or (h.Phase6 is not null and Phase6CType is null) or
   --	(h.Phase7 is not null and Phase7CType is null) or (h.Phase8 is not null and Phase8CType is null)
   --if @validcnt>0
   --	begin
   --	select @errmsg = 'Missing equipment cost type'
   --	goto error
   --	end
   
   /*select @validcnt = count(*) from inserted where Phase1CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase1CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase1CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase2CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase2CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
   
    	where i.Phase2CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase3CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase3CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase3CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase4CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase4CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase4CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase5CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase5CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase5CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase6CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase6CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase6CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase7CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase7CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase7CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase8CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase8CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase8CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end*/
   
   /* validate revenue codes */
   --The following missing cost type validation commented out because cost type may be missing
   --due to PRCrewTSEntry hide rev code option being checked.  -- EN
   --select @validcnt = count(*) from inserted i
   --join bPRRH h on i.PRCo=h.PRCo and i.Crew=h.Crew and i.PostDate=h.PostDate and i.SheetNum=h.SheetNum
   --where (h.Phase1 is not null and Phase1Rev is null) or (h.Phase2 is not null and Phase2Rev is null) or
   --	(h.Phase3 is not null and Phase3Rev is null) or (h.Phase4 is not null and Phase4Rev is null) or
   --	(h.Phase5 is not null and Phase5Rev is null) or (h.Phase6 is not null and Phase6Rev is null) or
   --	(h.Phase7 is not null and Phase7Rev is null) or (h.Phase8 is not null and Phase8Rev is null)
   --if @validcnt>0
   --	begin
   --	select @errmsg = 'Missing revenue code'
   --	goto error
   --	end
   
   /*select @validcnt = count(*) from inserted where Phase1Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase1Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase1Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase2Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase2Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase2Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase3Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase3Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase3Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase4Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase4Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase4Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase5Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase5Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase5Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase6Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase6Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase6Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase7Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase7Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase7Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase8Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase8Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase8Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end*/
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Crew Timesheet Equipment Usage!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
	CREATE       trigger [dbo].[btPRRQu] on [dbo].[bPRRQ] for UPDATE as
   

	/*-----------------------------------------------------------------
    *  Created: EN 2/21/03
    *	Modified:	EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *				EN 11/22/04 - issue 22571  relabel "Post Date" to "Timecard Date"
	*				mh 02/06/09 - issue 131950 Reject updates if bPRRH.Status > 0
    *
    * Cannot change primary key.
    * Validate Employee, Cost Types, and Revenue Codes.
    */----------------------------------------------------------------

   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on

	/*Reject updates if Timesheet is locked, no need to check anything else if locked or
	status is greater then zero*/

	if exists(select 1 from bPRRH h join inserted i on h.PRCo = i.PRCo and h.Crew = i.Crew and
	h.PostDate = i.PostDate and h.SheetNum = i.SheetNum and h.Status > 0)
	begin
		select @errmsg = 'Timesheet has been locked and cannot be edited.'
		goto error
	end

   /* check for key changes */
   if update(PRCo)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change PR Company '
        	goto error
        	end
       end
   if update(Crew)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Crew '
        	goto error
        	end
       end
   if update(PostDate)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew and d.PostDate = i.PostDate
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Timecard Date '
        	goto error
        	end
       end
   if update(SheetNum)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew and d.PostDate = i.PostDate and d.SheetNum = i.SheetNum
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Sheet # '
        	goto error
        	end
       end
   if update(EMCo)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew and d.PostDate = i.PostDate and d.SheetNum = i.SheetNum
   			and d.EMCo = i.EMCo
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change EM company '
        	goto error
        	end
       end
   if update(EMGroup)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew and d.PostDate = i.PostDate and d.SheetNum = i.SheetNum
   			and d.EMCo = i.EMCo and d.EMGroup = i.EMGroup
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change EM Group '
        	goto error
        	end
       end
   if update(Equipment)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew and d.PostDate = i.PostDate and d.SheetNum = i.SheetNum
   			and d.EMCo = i.EMCo and d.EMGroup = i.EMGroup and d.Equipment = i.Equipment
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Equipment '
        	goto error
        	end
       end
   
   /* validate employee */
   select @validcnt = count(*) from inserted where Employee is not null
   select @validcnt2 = count(*) from dbo.bPREH e with (nolock)
    	join inserted i on e.PRCo = i.PRCo and e.Employee = i.Employee
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid Employee'
    	goto error
    	end
   
   /* validate equipment cost types */
   --The following missing cost type validation commented out because cost type may be missing
   --due to PRCrewTSEntry hide cost type option being checked.  -- EN
   --select @validcnt = count(*) from inserted i
   --join bPRRH h on i.PRCo=h.PRCo and i.Crew=h.Crew and i.PostDate=h.PostDate and i.SheetNum=h.SheetNum
   --where (h.Phase1 is not null and Phase1CType is null) or (h.Phase2 is not null and Phase2CType is null) or
   --	(h.Phase3 is not null and Phase3CType is null) or (h.Phase4 is not null and Phase4CType is null) or
   --	(h.Phase5 is not null and Phase5CType is null) or (h.Phase6 is not null and Phase6CType is null) or
   --	(h.Phase7 is not null and Phase7CType is null) or (h.Phase8 is not null and Phase8CType is null)
   --if @validcnt>0
   --	begin
   --	select @errmsg = 'Missing equipment cost type'
   --	goto error
   --	end
   
   /*select @validcnt = count(*) from inserted where Phase1CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase1CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase1CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase2CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase2CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase2CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase3CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase3CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase3CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase4CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase4CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase4CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase5CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase5CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase5CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase6CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase6CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase6CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase7CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase7CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase7CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase8CType is not null
   select @validcnt2 = count(*) from bJCCT c
    	join inserted i on c.CostType = i.Phase8CType
   	join PRRH h on h.PRCo=i.PRCo and h.Crew=i.Crew and h.PostDate=i.PostDate and h.SheetNum=i.SheetNum
   		and h.PhaseGroup=c.PhaseGroup
    	where i.Phase8CType is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid equipment cost type'
    	goto error
    	end*/
   
   /* validate revenue codes */
   --The following missing cost type validation commented out because cost type may be missing
   --due to PRCrewTSEntry hide rev code option being checked.  -- EN
   --select @validcnt = count(*) from inserted i
   --join bPRRH h on i.PRCo=h.PRCo and i.Crew=h.Crew and i.PostDate=h.PostDate and i.SheetNum=h.SheetNum
   --where (h.Phase1 is not null and Phase1Rev is null) or (h.Phase2 is not null and Phase2Rev is null) or
   --	(h.Phase3 is not null and Phase3Rev is null) or (h.Phase4 is not null and Phase4Rev is null) or
   --	(h.Phase5 is not null and Phase5Rev is null) or (h.Phase6 is not null and Phase6Rev is null) or
   --	(h.Phase7 is not null and Phase7Rev is null) or (h.Phase8 is not null and Phase8Rev is null)
   --if @validcnt>0
   --	begin
   --	select @errmsg = 'Missing revenue code'
   --	goto error
   --	end
   
   /*select @validcnt = count(*) from inserted where Phase1Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase1Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase1Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase2Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase2Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase2Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase3Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase3Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase3Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase4Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase4Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase4Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase5Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase5Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase5Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase6Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase6Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase6Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase7Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase7Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase7Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Phase8Rev is not null
   select @validcnt2 = count(*) from inserted i
       join EMEM e on e.EMCo=i.EMCo and e.Equipment=i.Equipment
       join EMRC c on c.EMGroup=i.EMGroup and c.RevCode=i.Phase8Rev
       join EMRR r on r.EMCo=i.EMCo and r.EMGroup=i.EMGroup and r.RevCode=i.Phase8Rev and r.Category=e.Category
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid revenue code'
    	goto error
    	end*/
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Crew Timesheet Equipment Usage!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRRQ] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRRQ] ON [dbo].[bPRRQ] ([PRCo], [Crew], [PostDate], [SheetNum], [EMCo], [EMGroup], [Equipment], [LineSeq]) ON [PRIMARY]
GO
