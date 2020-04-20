CREATE TABLE [dbo].[bEMSH]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[StdMaintGroup] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Basis] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Interval] [int] NULL,
[IntervalDays] [smallint] NULL,
[Variance] [int] NULL,
[FixedDateMonth] [tinyint] NULL,
[FixedDateDay] [tinyint] NULL,
[AutoDelete] [dbo].[bYN] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CreateWOdaysprior] [smallint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMSHd    Script Date: 8/28/99 9:37:20 AM ******/
   CREATE   trigger [dbo].[btEMSHd] on [dbo].[bEMSH] for DELETE as
   

declare @errmsg varchar(255), @validcnt int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects delete in bEMSH (EM Std Maint Header) if  the following error condition exists:
    *
    *		Entry exists in EMSI - EM Std Maint Items by EMCo/Equipment/StdMaintGroup
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   /* Check EMSI. */
   if exists(select * from deleted d, bEMSI e where d.EMCo = e.EMCo and d.Equipment=e.Equipment and d.StdMaintGroup=e.StdMaintGroup)
   	begin
   	select @errmsg = 'Entries exist in bEMSI for this EMCo/Equipment/StdMaintGroup'
   	goto error
   	end
   
   /* Check EMSL. */
   if exists(select * from bEMSL e, deleted d where d.EMCo = e.EMCo and d.Equipment=e.Equipment and d.StdMaintGroup=e.StdMaintGroup)
   	begin
   	select @errmsg = 'Entries exist in bEMSL for this EMCo/Equipment/StdMaintGroup as StdMaintGroup'
   	goto error
   	end
   
   if exists(select * from bEMSL e, deleted d where d.EMCo = e.EMCo and d.Equipment=e.Equipment and d.StdMaintGroup=e.LinkedMaintGrp)
   	begin
   	select @errmsg = 'Entries exist in bEMSL for this EMCo/Equipment/StdMaintGroup as LinkedMaintGrp'
   	goto error
   	end
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Std Maint Header!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   

CREATE   trigger [dbo].[btEMSHu] on [dbo].[bEMSH] for UPDATE as

/*-----------------------------------------------------------------
*	CREATED BY: JM 5/19/99
*	MODIFIED By :  JM 6/11/99 - Restricted validation of AutoDelete only when that column is not null.
*				 TV 02/11/04 - 23061 added isnulls
*		 TRL 09/02/08 -- Issue 126196 add code to allow Equipment to change if
*		 the EM Equipment code is being changed
*		 GF 05/05/2013 TFS-49039
*
*
*	This trigger rejects update in bEMSH (EM Std Maint Header) if  the following error condition exists:
*
*		Change in key fields (EMCo, Equipment or StdMaintGroup)
*		Invalid Basis - not in (H, M, G, F)
*		Invalid AutoDelete - not in (Y, N)
*----------------------------------------------------------------*/
   
declare @autodelete bYN,@errmsg varchar(255),@numrows int,@validcnt int, @changeinprogress bYN
   
select @numrows = @@rowcount, @changeinprogress ='N'

if @numrows = 0 return
   
set nocount on
   
----TFS-49039  
SELECT @validcnt = COUNT(*) FROM dbo.bEMEM EMEM JOIN inserted i ON i.EMCo = EMEM.EMCo AND i.Equipment = EMEM.Equipment and EMEM.ChangeInProgress = 'Y'
IF @validcnt = @numrows RETURN

if update(Equipment)
begin
	/* Issue 126196 Check to see if equipment code is being changed.
	Select Where EMEM.LastUsedEquipmentCode = EMWH.Equipment*/
	select @changeinprogress=IsNull(ChangeInProgress,'N')
	from bEMEM e, inserted i where e.EMCo = i.EMCo and e.LastUsedEquipmentCode = i.Equipment
	and e.ChangeInProgress = 'Y'

	--Issue 126196 Only run code if Equipment Code is not being changed
	If @changeinprogress = 'N' 
	begin
   		select @errmsg = 'Cannot change Equipment'
   		goto error
   	end
end

if update(StdMaintGroup)
begin
   	select @errmsg = 'Cannot change StdMaintGroup'
   	goto error
end
   
   
return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Std Maint Header!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
  
 




GO
ALTER TABLE [dbo].[bEMSH] WITH NOCHECK ADD CONSTRAINT [CK_bEMSH_AutoDelete] CHECK (([AutoDelete]='N' OR [AutoDelete]='Y' OR [AutoDelete] IS NULL))
GO
ALTER TABLE [dbo].[bEMSH] WITH NOCHECK ADD CONSTRAINT [CK_bEMSH_Basis] CHECK (([Basis]='F' OR [Basis]='G' OR [Basis]='M' OR [Basis]='H'))
GO
CREATE UNIQUE CLUSTERED INDEX [biEMSH] ON [dbo].[bEMSH] ([EMCo], [Equipment], [StdMaintGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMSH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMSH] WITH NOCHECK ADD CONSTRAINT [FK_bEMSH_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
ALTER TABLE [dbo].[bEMSH] WITH NOCHECK ADD CONSTRAINT [FK_bEMSH_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[bEMSH] NOCHECK CONSTRAINT [FK_bEMSH_bEMCO_EMCo]
GO
ALTER TABLE [dbo].[bEMSH] NOCHECK CONSTRAINT [FK_bEMSH_bEMEM_Equipment]
GO
