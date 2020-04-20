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
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMUDd    Script Date: 8/28/99 9:37:24 AM ******/
   CREATE  trigger [dbo].[btEMUDd] on [dbo].[bEMUD] for delete as
   

/*--------------------------------------------------------------
    *
    *  Delete trigger for EMUD
    *  Created By:  bc  08/11/99
    *  Modified by:  bc 03/06/01 - removed rejection of delete if the rules table exists in EMUE or EMUC
    *				  TV 02/11/04 - 23061 added isnulls
    *
    *--------------------------------------------------------------*/
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
           @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
           @rcode int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMUD'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMUDi    Script Date: 8/28/99 9:37:24 AM ******/
   CREATE   trigger [dbo].[btEMUDi] on [dbo].[bEMUD] for insert as
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMUD
    *  Created By:  bc  08/11/99
    *  Modified by:  TV 02/11/04 - 23061 added isnulls
    *
    *
    *--------------------------------------------------------------*/
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
           @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
           @rcode int
   
   declare @emco bCompany, @seq int, @morethan bHrs, @lessthan bHrs
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   /* Validate EMCo */
   select @validcnt = count(*) from bEMCO r JOIN inserted i ON i.EMCo = r.EMCo
   if @validcnt <> @numrows
      begin
      select @errmsg = 'EM Company is Invalid '
      goto error
      end
   
   /* Validate EMGroup */
   select @validcnt = count(*) from bHQGP r JOIN inserted i ON i.EMGroup = r.Grp
   if @validcnt <> @numrows
      begin
      select @errmsg = 'EM Group is Invalid '
      goto error
      end
   
   
   /* Validate Rules Table*/
   select @validcnt = count(*) from bEMUR r JOIN inserted i ON i.EMCo = r.EMCo and i.RulesTable = r.RulesTable
   if @validcnt <> @numrows
      begin
      select @errmsg = 'The Rules Table is Invalid '
      goto error
      end
   
   /* Validate RevCode */
   select @validcnt = count(*) from bEMRC r JOIN inserted i ON i.EMGroup = r.EMGroup and i.RevCode = r.RevCode
   if @validcnt <> @numrows
      begin
      select @errmsg = 'RevCode is Invalid '
      goto error
      end
   
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
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMUDu    Script Date: 8/28/99 9:37:24 AM ******/
   CREATE   trigger [dbo].[btEMUDu] on [dbo].[bEMUD] for update as
   

/*--------------------------------------------------------------
    *
    *  Update trigger for EMUD
    *  Created By:  bc  08/11/99
    *  Modified by:  TV 02/11/04 - 23061 added isnulls
    *
    *
    *--------------------------------------------------------------*/
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
           @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
           @rcode int
   
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
   
   /* Validate RevCode */
   if update(RevCode)
   begin
   select @validcnt = count(*) from bEMRC r JOIN inserted i ON i.EMGroup = r.EMGroup and i.RevCode = r.RevCode
   if @validcnt <> @numrows
      begin
      select @errmsg = 'RevCode is Invalid '
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
CREATE UNIQUE CLUSTERED INDEX [biEMUD] ON [dbo].[bEMUD] ([EMCo], [Sequence], [RulesTable]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMUD] ([KeyID]) ON [PRIMARY]
GO
