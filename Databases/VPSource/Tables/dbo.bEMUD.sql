CREATE TABLE [dbo].[bEMUD]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Sequence] [smallint] NOT NULL,
[RulesTable] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[EMGroup] [dbo].[bGroup] NULL,
[MoreThanHrs] [dbo].[bHrs] NOT NULL,
[LessThanHrs] [dbo].[bHrs] NOT NULL,
[RevCode] [dbo].[bRevCode] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bEMUD] ADD
CONSTRAINT [FK_bEMUD_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
ALTER TABLE [dbo].[bEMUD] ADD
CONSTRAINT [FK_bEMUD_bEMUR_RulesTable] FOREIGN KEY ([EMCo], [RulesTable]) REFERENCES [dbo].[bEMUR] ([EMCo], [RulesTable]) ON DELETE CASCADE
ALTER TABLE [dbo].[bEMUD] ADD
CONSTRAINT [FK_bEMUD_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
ALTER TABLE [dbo].[bEMUD] ADD
CONSTRAINT [FK_bEMUD_bEMRC_RevCode] FOREIGN KEY ([EMGroup], [RevCode]) REFERENCES [dbo].[bEMRC] ([EMGroup], [RevCode])
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

   CREATE   trigger [dbo].[btEMUDi] on [dbo].[bEMUD] for insert as
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMUD
    *  Created By:  bc  08/11/99
    *  Modified by:  TV 02/11/04 - 23061 added isnulls
	*				 GF 05/05/2013 TFS-49039
    *
    *
    *--------------------------------------------------------------*/
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @rcode int
   
   declare @emco bCompany, @seq int, @morethan bHrs, @lessthan bHrs
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
   
   
   
   /* validate time values */
   select @emco = min(EMCo) from inserted
   while @emco is not null
     begin
     select @seq = min(Sequence) from inserted where EMCo = @emco
     while @seq is not null
       begin
   	select @morethan = MoreThanHrs, @lessthan = LessThanHrs
   	from inserted
   	where EMCo = @emco and Sequence = @seq
   
   	if @morethan is not null and @lessthan is not null
   	  begin
           if @morethan > @lessthan
             begin
   	      select @errmsg = 'More than hours > Less than hours on a sequence '
   	      goto error
             end
   	  end
   
       select @seq = min(Sequence) from inserted where EMCo = @emco and Sequence > @seq
       end
     select @emco = min(EMCo) from inserted where EMCo > @emco
     end
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMUD'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

   CREATE   trigger [dbo].[btEMUDu] on [dbo].[bEMUD] for update as
   

/*--------------------------------------------------------------
    *
    *  Update trigger for EMUD
    *  Created By:  bc  08/11/99
    *  Modified by:  TV 02/11/04 - 23061 added isnulls
	*				 GF 05/05/1023 TFS-49039
    *
    *
    *--------------------------------------------------------------*/
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255),
           @validcnt int, @nullcnt int, @rcode int
   
   declare @emco bCompany, @rulestable varchar(10), @seq int, @morethan bHrs, @lessthan bHrs
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   if update(EMCo) or update(EMGroup) or update(RulesTable)
     begin
     select @validcnt = count(*) from inserted i join deleted d on i.EMCo = d.EMCo and i.EMGroup = d.EMGroup and i.RulesTable = d.RulesTable
       begin
       select @errmsg = 'Cannot change key fields '
       goto error
       end
     end
   
   
   /* validate time values */
   if update(MoreThanHrs) or update(LessThanHrs)
     begin
     select @emco = min(EMCo) from inserted
     while @emco is not null
       begin
       select @rulestable = min(RulesTable) from inserted where EMCo = @emco
       while @rulestable is not null
         begin
         select @seq = min(Sequence) from inserted where EMCo = @emco and RulesTable = @rulestable
         while @seq is not null
           begin
   	    select @morethan = MoreThanHrs, @lessthan = LessThanHrs
   	    from inserted
   	    where EMCo = @emco and Sequence = @seq
   
   	    if @morethan is not null and @lessthan is not null
   	      begin
             if @morethan > @lessthan
               begin
   	        select @errmsg = 'More than hours > Less than hours on a sequence '
   	        goto error
               end
   	      end
   
         select @seq = min(Sequence) from inserted where EMCo = @emco and RulesTable = @rulestable and  Sequence > @seq
         end
       select @rulestable = min(RulesTable) from inserted where EMCo = @emco and RulesTable > @rulestable
       end
     select @emco = min(EMCo) from inserted where EMCo > @emco
     end
   end
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot update EMUD'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO

CREATE UNIQUE CLUSTERED INDEX [biEMUD] ON [dbo].[bEMUD] ([EMCo], [Sequence], [RulesTable]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMUD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
