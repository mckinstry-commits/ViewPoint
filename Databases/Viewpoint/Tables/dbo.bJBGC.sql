CREATE TABLE [dbo].[bJBGC]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[ProcessGroup] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[Contract] [dbo].[bContract] NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJBGC] ON [dbo].[bJBGC] ([JBCo], [ProcessGroup], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBGC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBGCd] ON [dbo].[bJBGC] FOR Delete AS
     

/**************************************************************
      *	This trigger rejects delete of bJBGC (JB Process Group Contracts)
      *	 if the following error condition exists:
      *		none
      *
      *              Updates corresponding fields in JBGC.
      *
      **************************************************************/
     declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int
   
     select @numrows = @@rowcount
   
     if @numrows = 0 return
     set nocount on
   
     /* update the process group in JCCM */
     if exists (select * from JCCM j join deleted d on j.JCCo = d.JBCo and j.Contract = d.Contract and j.ProcessGroup = d.ProcessGroup)
       begin
       update JCCM
       set ProcessGroup = null
       from deleted d, JCCM m
       where m.JCCo = d.JBCo and m.Contract = d.Contract
       end
   
     return
   
     error:
     select @errmsg = @errmsg + ' - cannot delete JB Process Group Contract!'
   
     RAISERROR(@errmsg, 11, -1);
     rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  TRIGGER [dbo].[btJBGCi] ON [dbo].[bJBGC] FOR INSERT AS
     

/**************************************************************
      * 	Created by: kb 7/1/2
      *	Modified by: 
      *
      *	This trigger rejects insert of bJBGC (JB Process Group Contracts)
      *	 if the following error condition exists:
      *		none
      *
      *              Updates corresponding fields in JBGC.
      *
      **************************************************************/
     declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
   	@jbco bCompany, @procgroup varchar(10), @customer bCustomer, @custgroup bGroup, 
   	@oldprocgroup varchar(10)
   
     select @numrows = @@rowcount
   
     if @numrows = 0 return
     set nocount on
   
     /* update the process group in JCCM */
     /* since the JCCM update trigger can update JBGC, make sure it doesn't already exist in JCCM before inserting */
     if not exists (select * from bJCCM m join inserted i on i.JBCo = m.JCCo and i.Contract = m.Contract and i.ProcessGroup = m.ProcessGroup)
       begin
       update bJCCM
       set ProcessGroup = i.ProcessGroup
       from inserted i, bJCCM m
       where m.JCCo = i.JBCo and m.Contract = i.Contract
       end
   
     select @jbco = min(JBCo) from inserted i where i.Customer is not null
     while @jbco is not null
   	begin
   	select @procgroup = min(ProcessGroup) from inserted i
   		where i.JBCo = @jbco and i.Customer is not null
   	while @procgroup is not null
   		begin
   		select @custgroup = min(CustGroup) from inserted i
   		  where i.JBCo = @jbco and ProcessGroup = @procgroup 
   		  and i.Customer is not null
   		while @custgroup is not null
   			begin
   			select @customer = min(Customer) from inserted i
   			  where i.JBCo = @jbco and ProcessGroup = @procgroup 
   			  and i.CustGroup = @custgroup and i.Customer is not null
   			while @customer is not null
   				begin
   				select @oldprocgroup = ProcessGroup from bJBGC where JBCo = @jbco 
   				  and ProcessGroup <> @procgroup and CustGroup = @custgroup 
   				  and Customer = @customer and Customer is not null
   				if @@rowcount <> 0 
   					begin
   					delete from bJBGC where JBCo = @jbco and ProcessGroup <> @procgroup
   					  and Customer = @customer
   					end
   			select @customer = min(Customer) from inserted i
   			  where i.JBCo = @jbco and ProcessGroup = @procgroup 
   			  and i.CustGroup = @custgroup and i.Customer > @customer 
   			  and i.Customer is not null
   			end
   		select @custgroup = min(CustGroup) from inserted i
   		  where i.JBCo = @jbco and i.ProcessGroup = @procgroup 
   		  and i.CustGroup >@custgroup
   		end
   	select @procgroup = min(ProcessGroup) from inserted i
   		where i.JBCo = @jbco and i.ProcessGroup > @procgroup and 
   		i.Customer is not null
   	end
     select @jbco = min(JBCo) from inserted i where i.JBCo > @jbco
   	and i.Customer is not null
   end
     return
   
     error:
     select @errmsg = @errmsg + ' - cannot insert JB Process Group Contract!'
   
     RAISERROR(@errmsg, 11, -1);
     rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btJBGCu    Script Date: 8/28/99 9:38:18 AM ******/
   CREATE trigger [dbo].[btJBGCu] on [dbo].[bJBGC] for UPDATE as
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), @validcount int,
   @jbco bCompany, @procgroup varchar(10), @customer bCustomer, @custgroup bGroup, 
   	@oldprocgroup varchar(10)
   
   /*--------------------------------------------------------------
    *
    *  Update trigger for JBGC
    *  Created By: kb 7/1/2
    *
    *  Reject key changes.
    *  AuditCoParams must be 'Y'.
    *  Insert audit entries for changed values into bHQMA.
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount
    if @numrows = 0 return
   
    select @validcount=0
   
    set nocount on
   
   /* check for key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.JBCo = i.JBCo
   if @validcount <> @numrows
   	begin
   	select @errmsg = 'Cannot change JB Company'
   	goto error
   	end
   
   select @validcount = count(*) from deleted d, inserted i
   	where d.JBCo = i.JBCo and d.ProcessGroup = i.ProcessGroup
   if @validcount <> @numrows
   	begin
   	select @errmsg = 'Cannot change Process Group'
   	goto error
   	end
   
   select @validcount = count(*) from deleted d, inserted i
   	where d.JBCo = i.JBCo and d.ProcessGroup = i.ProcessGroup and d.Seq = i.Seq
   if @validcount <> @numrows
   	begin
   	select @errmsg = 'Cannot change JB Company'
   	goto error
   	end
   
   if update(Contract)
   	  /* update the process group in JCCM */
     /* since the JCCM update trigger can update JBGC, make sure it doesn't already exist in JCCM before inserting */
     if not exists (select * from bJCCM m join inserted i on i.JBCo = m.JCCo and i.Contract = m.Contract and i.ProcessGroup = m.ProcessGroup)
       begin
       update bJCCM
       set ProcessGroup = i.ProcessGroup
       from inserted i, bJCCM m
       where m.JCCo = i.JBCo and m.Contract = i.Contract
       end
   
   if update(Customer)
   	begin
   	select @jbco = min(JBCo) from inserted i where i.Customer is not null
   	  while @jbco is not null
   		begin
   		select @procgroup = min(ProcessGroup) from inserted i
   			where i.JBCo = @jbco and i.Customer is not null
   		while @procgroup is not null
   			begin
   			select @custgroup = min(CustGroup) from inserted i
   			  where i.JBCo = @jbco and ProcessGroup = @procgroup 
   			  and i.Customer is not null
   			while @custgroup is not null
   				begin
   				select @customer = min(Customer) from inserted i
   				  where i.JBCo = @jbco and ProcessGroup = @procgroup 
   				  and i.CustGroup = @custgroup and i.Customer is not null
   				while @customer is not null
   					begin
   					select @oldprocgroup = ProcessGroup from bJBGC where JBCo = @jbco 
   					  and ProcessGroup <> @procgroup and CustGroup = @custgroup 
   					  and Customer = @customer and Customer is not null
   					if @@rowcount <> 0 
   						begin
   						delete from bJBGC where JBCo = @jbco and ProcessGroup <> @procgroup
   						  and Customer = @customer
   						end
   				select @customer = min(Customer) from inserted i
   				  where i.JBCo = @jbco and ProcessGroup = @procgroup 
   				  and i.CustGroup = @custgroup and i.Customer > @customer 
   				  and i.Customer is not null
   				end
   			select @custgroup = min(CustGroup) from inserted i
   			  where i.JBCo = @jbco and i.ProcessGroup = @procgroup 
   			  and i.CustGroup >@custgroup
   			end
   		select @procgroup = min(ProcessGroup) from inserted i
   			where i.JBCo = @jbco and i.ProcessGroup > @procgroup and 
   			i.Customer is not null
   		end
   	  select @jbco = min(JBCo) from inserted i where i.JBCo > @jbco
   		and i.Customer is not null
   	end
   	end
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update JB Processing Group '
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
