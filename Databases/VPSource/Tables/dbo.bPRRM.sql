CREATE TABLE [dbo].[bPRRM]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Routine] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[ProcName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[LastUpdated] [dbo].[bDate] NULL,
[MiscAmt1] [dbo].[bDollar] NOT NULL,
[MiscAmt2] [dbo].[bDollar] NOT NULL,
[MiscAmt3] [dbo].[bDollar] NOT NULL,
[MiscAmt4] [dbo].[bDollar] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
CREATE trigger [dbo].[btPRRMi] on [dbo].[bPRRM] for INSERT as
/*-----------------------------------------------------------------
* Created:		EN 08/03/2004
* Modified:		EN 05/22/2012	B-09715/TK-15008 Made exception on rule to allow only one routine per stored proc
*										   for the bspPR_AU_ROSG and bspPR_AU_Allowance stored procs.
*										   Note that this change is temporary pending PR Routine procedure reforms
*										   that will cause that rule to become obsolete.
*				CHS	06/07/2012	B-09841 Ability to Use Meal and Crib Routines in multiple earn codes 
*				EN 08/16/2012 B-10534/TK-18448 added bspPR_AU_RDOAccrual and bspPR_AU_RDOAccrualDaily to list of routines
*												that can be setup multiple times
*
* Insert trigger on PR State Information
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate PR Company 
   select @validcnt = count(*)
   from dbo.bHQCO c with (nolock)
   join inserted i on c.HQCo = i.PRCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid PR Company# '
   	goto error
   	end
   
	-- Duplicate ProcName not allowed with the following exceptions ...
	select @validcnt = count(*) 
	from dbo.bPRRM r with (nolock) 
		join inserted i on r.PRCo = i.PRCo and r.Routine <> i.Routine and r.ProcName = i.ProcName

	where r.ProcName NOT IN ('bspPRExemptRateOfGross', 
							 'bspPR_AU_ROSG', 
							 'bspPR_AU_Allowance', 
							 'bspPR_AU_OTCribAllow', 
							 'bspPR_AU_OTMealAllow', 
							 'bspPR_AU_OTWeekendCrib',
							 'bspPR_AU_AmountPerDiemAward',
							 'bspPR_AU_RDOAccrual',
							 'bspPR_AU_RDOAccrualDaily')  
   if @validcnt > 0
   	begin
   	select @errmsg = 'Procedure name cannot be used in multiple routines '
   	goto error
   	end
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Routine Master!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE	trigger [dbo].[btPRRMu] on [dbo].[bPRRM] for UPDATE as
/*-----------------------------------------------------------------
* Created:		EN 08/03/2004
* Modified:		EN 05/22/2012	B-09715/TK-15008 Made exception on rule to allow only one routine per stored proc
*										   for the bspPR_AU_ROSG and bspPR_AU_Allowance stored procs.
*										   Note that this change is temporary pending PR Routine procedure reforms
*										   that will cause that rule to become obsolete.
*				CHS	06/07/2012	B-09841 Ability to Use Meal and Crib Routines in multiple earn codes 
*				EN 08/16/2012 B-10534/TK-18448 added bspPR_AU_RDOAccrual and bspPR_AU_RDOAccrualDaily to list of routines
*												that can be setup multiple times
*
* Update trigger on PR Routine Master
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- verify primary key not changed
   select @validcnt = count(*)
   from inserted i
   join deleted d on d.PRCo = i.PRCo and d.Routine = i.Routine
   if @validcnt <> @numrows
       	begin
    	select @errmsg = 'Cannot change PR Company # or Routine '
    	goto error
    	end
   
   if update(ProcName)
   	begin
   	-- Duplicate ProcName not allowed with the following exceptions ...
   	select @validcnt = count(*) 
   	from dbo.bPRRM r with (nolock) 
   		join inserted i on r.PRCo = i.PRCo and r.Routine <> i.Routine and r.ProcName = i.ProcName
	where r.ProcName NOT IN ('bspPRExemptRateOfGross', 
							 'bspPR_AU_ROSG', 
							 'bspPR_AU_Allowance', 
							 'bspPR_AU_OTCribAllow', 
							 'bspPR_AU_OTMealAllow', 
							 'bspPR_AU_OTWeekendCrib',
							 'bspPR_AU_AmountPerDiemAward',
							 'bspPR_AU_RDOAccrual',
							 'bspPR_AU_RDOAccrualDaily')  
   	if @validcnt > 0
   		begin
   		select @errmsg = 'Procedure name cannot be used in multiple routines '
   		goto error
   		end
   	end
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Routine Master!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRRM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRRM] ON [dbo].[bPRRM] ([PRCo], [Routine]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
