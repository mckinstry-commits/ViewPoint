CREATE TABLE [dbo].[bJCOR]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Month] [dbo].[bMonth] NOT NULL,
[RevCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCOR_RevCost] DEFAULT ((0)),
[OtherAmount] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCOR_OtherAmount] DEFAULT ((0)),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJCOR] ON [dbo].[bJCOR] ([JCCo], [Contract], [Month]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   CREATE TRIGGER [dbo].[btJCORd] ON [dbo].[bJCOR] FOR INSERT AS
   --CREATE TRIGGER [dbo].[btJCORd] ON [dbo].[bJCOR] FOR INSERT AS
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
	select 'bJCOR',' JC Co#: ' + convert(varchar(3),d.JCCo) + ' Contract: ' + isnull(d.Contract,'') + 
			' Month: ' + isnull(cast(d.Month as varchar(30)),''),
   		d.JCCo, 'D', null, null, null, getdate(), suser_sname()
	 from deleted d join bJCCO o on d.JCCo = o.JCCo
	where o.AuditProjectionOverrides = 'Y'
   
   
   
   return
   
--------------------
-- ERROR HANDLING --
--------------------
error:
	select @errmsg = @errmsg + ' - cannot delete from JCOR'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
     CREATE TRIGGER [dbo].[btJCORi] ON [dbo].[bJCOR] FOR INSERT AS
--   CREATE TRIGGER [dbo].[btJCORi] ON [dbo].[bJCOR] FOR INSERT AS
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
	select @validcnt = count(*) from bJCCM m JOIN inserted i ON i.JCCo = m.JCCo and i.Contract = m.Contract
	if @validcnt <> @numrows
   		begin
   			select @errmsg = 'Contract is Invalid '
   			goto error
   		end

   
	-------------------
	-- AUDIT INSERTS --
	-------------------
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCOR',' JC Co#: ' + convert(varchar(3),i.JCCo) + ' Contract: ' + isnull(i.Contract,'') + 
			' Month: ' + isnull(cast(i.Month as varchar(30)),''),
   		i.JCCo, 'A', null, null, null, getdate(), suser_sname()
	 from inserted i join bJCCO o on i.JCCo = o.JCCo
	where i.JCCo = o.JCCo and o.AuditProjectionOverrides = 'Y'
   
   
   
   return
   
--------------------
-- ERROR HANDLING --
--------------------
error:
	select @errmsg = @errmsg + ' - cannot insert into JCOR'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

	CREATE TRIGGER [dbo].[btJCORu] ON [dbo].[bJCOR] FOR UPDATE AS
	--CREATE TRIGGER [dbo].[btJCORu] ON [dbo].[bJCOR] FOR UPDATE AS
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
    if update(Contract)
    	begin
    		select @errmsg = 'Cannot change Contract'
    		goto error
    	end
     
    -- check for changes to Month
    if update(Month)
    	begin
    		select @errmsg = 'Cannot change Month'
    		goto error
    	end

     
    -------------------
	-- AUDIT CHANGES --
	------------------- 
    if update(RevCost)
    BEGIN
    	insert bHQMA select 'bJCOR', ' JC Co#: ' + convert(varchar(3),i.JCCo) +
				' Contract: ' + isnull(i.Contract,'') + 
				' Month: ' + isnull(cast(i.Month as varchar(30)),''),
                i.JCCo, 'C', 'RevCost', d.RevCost, i.RevCost, getdate(), SUSER_SNAME()
    	from inserted i 
    	join deleted d on d.JCCo=i.JCCo and d.Contract=i.Contract and d.Month=i.Month
    	join bJCCO o with (nolock) on o.JCCo = i.JCCo
    	where isnull(d.RevCost,'') <> isnull(i.RevCost,'') 
		  and o.AuditProjectionOverrides = 'Y'
    END
    
    if update(OtherAmount)
    BEGIN
    	insert bHQMA select 'bJCOR', ' JC Co#: ' + convert(varchar(3),i.JCCo) +
				' Contract: ' + isnull(i.Contract,'') + 
				' Month: ' + isnull(cast(i.Month as varchar(30)),''),
                i.JCCo, 'C', 'OtherAmount', d.OtherAmount, i.OtherAmount, getdate(), SUSER_SNAME()
    	from inserted i 
    	join deleted d on d.JCCo=i.JCCo and d.Contract=i.Contract and d.Month=i.Month
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
