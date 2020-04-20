CREATE TABLE [dbo].[bJCOP]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[Month] [dbo].[bMonth] NOT NULL,
[ProjCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCOP_ProjCost] DEFAULT ((0)),
[OtherAmount] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCOP_OtherAmount] DEFAULT ((0)),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   CREATE TRIGGER [dbo].[btJCOPd] ON [dbo].[bJCOP] FOR DELETE AS
   --CREATE TRIGGER [dbo].[btJCOPd] ON [dbo].[bJCOP] FOR DELETE AS
/*-----------------------------------------------------------------
    * Created By:	Dan So 03/18/09 - Issue: 132117 - Auditing
    * Modified By: 
    *
    *-----------------------------------------------------------------*/
	declare @numrows int, @validcnt int, @errmsg varchar(255) 
   
	select @numrows = @@rowcount
	if @numrows = 0 return
	set nocount on
   
   
	-------------------
	-- AUDIT INSERTS --
	-------------------
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCOP',' JC Co#: ' + convert(varchar(3),d.JCCo) + ' Job: ' + isnull(d.Job,'') + 
			' Month: ' + isnull(cast(d.Month as varchar(30)),''),
   		d.JCCo, 'D', NULL, NULL, NULL, getdate(), suser_sname()
	 from deleted d join bJCCO o on d.JCCo = o.JCCo
	where o.AuditProjectionOverrides = 'Y'
   
   

   return
   
--------------------
-- ERROR HANDLING --
--------------------
error:
	select @errmsg = @errmsg + ' - cannot delete from JCOP'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   CREATE TRIGGER [dbo].[btJCOPi] ON [dbo].[bJCOP] FOR INSERT AS
   --CREATE TRIGGER [dbo].[btJCOPi] ON [dbo].[bJCOP] FOR INSERT AS
/*-----------------------------------------------------------------
    * Created By:	Dan So 03/18/09 - Issue: 132117 - Auditing
    * Modified By: 
    *
    *-----------------------------------------------------------------*/
	declare @numrows int, @validcnt int, @errmsg varchar(255) 
   
	select @numrows = @@rowcount
	if @numrows = 0 return
	set nocount on
   

	----------------
	-- VALIDATION --
	----------------
	-- Validate Company
	select @validcnt = count(*) from bJCCO o JOIN inserted i ON i.JCCo = o.JCCo 
	if @validcnt <> @numrows
   		begin
   			select @errmsg = 'Company is Invalid '
   			goto error
   		end
   

	-- Validate Job
	select @validcnt = count(*) from bJCJM m JOIN inserted i ON i.JCCo = m.JCCo and i.Job = m.Job
	if @validcnt <> @numrows
   		begin
   			select @errmsg = 'Job is Invalid '
   			goto error
   		end


	-------------------
	-- AUDIT INSERTS --
	-------------------
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCOP',' JC Co#: ' + convert(varchar(3),i.JCCo) + ' Job: ' + isnull(i.Job,'') + 
			' Month: ' + isnull(cast(i.Month as varchar(30)),''),
   		i.JCCo, 'A', NULL, NULL, NULL, getdate(), suser_sname()
	 from inserted i join bJCCO o on i.JCCo = o.JCCo
	where o.AuditProjectionOverrides = 'Y'
   
   
   
   return
   
--------------------
-- ERROR HANDLING --
--------------------
error:
	select @errmsg = @errmsg + ' - cannot insert into JCOP'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

	CREATE TRIGGER [dbo].[btJCOPu] ON [dbo].[bJCOP] FOR UPDATE AS
	--CREATE TRIGGER [dbo].[btJCOPu] ON [dbo].[bJCOP] FOR UPDATE AS
/*-----------------------------------------------------------------
     * Created By:	Dan So 03/18/09 - Issue: 132117 - Auditing
     * Modified By: 
     *
     *
     *             
     *-----------------------------------------------------------------*/
    declare @errmsg varchar(255), @numrows int
     
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    
     
	----------------
	-- VALIDATION --
	----------------
    -- check for changes to JCCo
    if update(JCCo)
    	begin
    		select @errmsg = 'Cannot change JCCo'
    		goto error
    	end
     
    -- check for changes to Job
    if update(Job)
    	begin
    		select @errmsg = 'Cannot change Job'
    		goto error
    	end
     
    -- check for changes to Month
    if update(Month)
    	begin
    		select @errmsg = 'Cannot change Month'
    		goto error
    	end

    ------------------------------------------
	-- what about ProjCost and OtherAmount? --
	------------------------------------------
     
    -------------------
	-- AUDIT CHANGES --
	------------------- 
    if update(ProjCost)
    BEGIN
    	insert bHQMA select 'bJCOP', ' JC Co#: ' + convert(varchar(3),i.JCCo) + 
				' Job: ' + isnull(i.Job,'') + 
				' Month: ' + isnull(cast(i.Month as varchar(30)),''),
                i.JCCo, 'C', 'ProjCost', d.ProjCost, i.ProjCost, getdate(), SUSER_SNAME()
    	from inserted i 
    	join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Month=i.Month
    	join bJCCO o with (nolock) on o.JCCo = i.JCCo
    	where isnull(d.ProjCost,'') <> isnull(i.ProjCost,'') 
		  and o.AuditProjectionOverrides = 'Y'
    END
    
    if update(OtherAmount)
    BEGIN
    	insert bHQMA select 'bJCOP', ' JC Co#: ' + convert(varchar(3),i.JCCo) +
				'Job: ' + isnull(i.Job,'') + 
				' Month: ' + isnull(cast(i.Month as varchar(30)),''),
                i.JCCo, 'C', 'OtherAmount', d.OtherAmount, i.OtherAmount, getdate(), SUSER_SNAME()
    	from inserted i 
    	join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.Month=i.Month
    	join bJCCO o with (nolock) on o.JCCo = i.JCCo
    	where isnull(d.OtherAmount,'') <> isnull(i.OtherAmount,'') 
		  and o.AuditProjectionOverrides = 'Y'
    END
    	



	return
    
--------------------
-- ERROR HANDLING --
--------------------
error:
	select @errmsg = @errmsg + ' - cannot update Change Order!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [biJCOP] ON [dbo].[bJCOP] ([JCCo], [Job], [Month]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
