CREATE TABLE [dbo].[bJCCP]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[ActualHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCCP_ActualHours] DEFAULT ((0)),
[ActualUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCCP_ActualUnits] DEFAULT ((0)),
[ActualCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCP_ActualCost] DEFAULT ((0)),
[OrigEstHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCCP_OrigEstHours] DEFAULT ((0)),
[OrigEstUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCCP_OrigEstUnits] DEFAULT ((0)),
[OrigEstCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCP_OrigEstCost] DEFAULT ((0)),
[CurrEstHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCCP_CurrEstHours] DEFAULT ((0)),
[CurrEstUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCCP_CurrEstUnits] DEFAULT ((0)),
[CurrEstCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCP_CurrEstCost] DEFAULT ((0)),
[ProjHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCCP_ProjHours] DEFAULT ((0)),
[ProjUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCCP_ProjUnits] DEFAULT ((0)),
[ProjCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCP_ProjCost] DEFAULT ((0)),
[ForecastHours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bJCCP_ForecastHours] DEFAULT ((0)),
[ForecastUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCCP_ForecastUnits] DEFAULT ((0)),
[ForecastCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCP_ForecastCost] DEFAULT ((0)),
[TotalCmtdUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCCP_TotalCmtdUnits] DEFAULT ((0)),
[TotalCmtdCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCP_TotalCmtdCost] DEFAULT ((0)),
[RemainCmtdUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCCP_RemainCmtdUnits] DEFAULT ((0)),
[RemainCmtdCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCP_RemainCmtdCost] DEFAULT ((0)),
[RecvdNotInvcdUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCCP_RecvdNotInvcdUnits] DEFAULT ((0)),
[RecvdNotInvcdCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCP_RecvdNotInvcdCost] DEFAULT ((0)),
[ProjPlug] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCP_ProjPlug] DEFAULT ('N'),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_bJCCP_JCCoJobPhase] ON [dbo].[bJCCP] ([JCCo], [Job], [Phase], [PhaseGroup], [CostType], [Mth]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE   trigger [dbo].[btJCCPi] on [dbo].[bJCCP] for insert as
   

/**************************************************************
   * Created: GG 06/24/02
   * Modified: DANF 09/06/02 - 17738 Added PhaseGroup to bspJCADDCOSTTYPE
   *
   *  Insert trigger on JC Cost by Period
   *
   *
   **************************************************************/
   declare @errmsg varchar(255), @numrows int, @jcco bCompany, @job bJob,
   	@phasegroup bGroup, @phase bPhase, @costtype bJCCType, @rcode int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validation
   if @numrows = 1
   	select @jcco = JCCo, @job = Job, @phasegroup = PhaseGroup, @phase = Phase, @costtype = CostType
   	from inserted
   else
   	begin
   	-- use a cursor to process each distinct Job, Phase, CostType combination
   	declare bJCCP_insert cursor for
   	select JCCo, Job, PhaseGroup, Phase, CostType
   	from inserted
   	group by JCCo, Job, PhaseGroup, Phase, CostType		
   
   	open bJCCP_insert
   
   	fetch next from bJCCP_insert into @jcco, @job, @phasegroup, @phase, @costtype
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   insert_check:
   	-- validate Phase - add to bJCJP if needed
   	if not exists(select 1 from bJCJP where JCCo = @jcco and Job = @job and
   						PhaseGroup = @phasegroup and Phase = @phase)
   		begin
   		exec @rcode = bspJCADDPHASE @jcco, @job, @phasegroup, @phase, @msg = @errmsg output
           if @rcode <> 0 goto error
   		end
   
   	-- validate Phase/CostType - add to bJCCH if needed
   	if not exists(select 1 from bJCCH where JCCo = @jcco and Job = @job and
   						PhaseGroup = @phasegroup and Phase = @phase and CostType = @costtype)
   		begin
   		exec @rcode = bspJCADDCOSTTYPE @jcco, @job, @phasegroup, @phase, @costtype, @msg = @errmsg output
           if @rcode <> 0 goto error
   		end
   
   	if @numrows > 1
   		begin
   	 	fetch next from bJCCP_insert into @jcco, @job, @phasegroup, @phase, @costtype
   	 	if @@fetch_status = 0
   			goto insert_check
   	 	else
   			begin
   		 	close bJCCP_insert
   		 	deallocate bJCCP_insert
   			end
   		end
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert JC Cost by Period' 
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCCPu    Script Date: 8/28/99 9:37:42 AM ******/
   CREATE  trigger [dbo].[btJCCPu] on [dbo].[bJCCP] for UPDATE as
   

declare @errmsg varchar(255), @errno int, @numrows int, 
   	@validcnt int, @validcnt2 int,
           @pp varchar(20),@rcode int,@desc varchar(30)
           
   /*-----------------------------------------------------------------
    *	This trigger rejects insertion in bJCCP
    *      (JC Cost by {Period) if the following error
    *      condition exists:
    *
    *	JCCO, Job, Phase, CostType, Month have changed.
    *	
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check if key values have changed */
   if update(JCCo) 
   	begin select @errmsg='Update to JC Company not allowed'
   		goto error
   	end
   if update(Job) 
   	begin select @errmsg='Update to Job not allowed'
   		goto error
   	end
   if update(PhaseGroup)
   	begin select @errmsg='Update to Phase Group not allowed'
   		goto error
   	end
   if update(Phase) 
   	begin select @errmsg='Update to Phase not allowed'
   		goto error
   	end
   if update(CostType)
   	begin select @errmsg='Update to Cost Type not allowed'
   		goto error
   	end
   if update(Mth)
   	begin select @errmsg='Update to Month not allowed'
   		goto error
   	end
   
   return
   
   
   error:
   	
       	select @errmsg = @errmsg + ' - cannot update JCCP!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
  
 



GO

EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[ActualHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[ActualUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[ActualCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[OrigEstHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[OrigEstUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[OrigEstCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[CurrEstHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[CurrEstUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[CurrEstCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[ProjHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[ProjUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[ProjCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[ForecastHours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[ForecastUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[ForecastCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[TotalCmtdUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[TotalCmtdCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[RemainCmtdUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[RemainCmtdCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[RecvdNotInvcdUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCP].[RecvdNotInvcdCost]'
GO
