CREATE TABLE [dbo].[bEMTE]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[RevTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[AllowOrideFlag] [char] (1) COLLATE Latin1_General_BIN NULL,
[Rate] [dbo].[bDollar] NOT NULL,
[DiscFromStdRate] [dbo].[bPct] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMTE] ON [dbo].[bEMTE] ([EMCo], [RevTemplate], [Equipment], [RevCode], [EMGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMTE] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMTEd    Script Date: 8/28/99 9:37:22 AM ******/
   
   
     CREATE  trigger [dbo].[btEMTEd] on [dbo].[bEMTE] for DELETE as
   
      

/***  basic declares for SQL Triggers ****/
     declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
             @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
     /*--------------------------------------------------------------
      *
      *  Delete trigger for EMTE
      *  Created By: bc 10/30/98
      *  Modified by: TV 02/11/04 - 23061 added isnulls
      *
      *
      *--------------------------------------------------------------*/
   
   
      /*** declare local variables ***/
   
     declare @count int
     select @numrows = @@rowcount, @count = 0
     if @numrows = 0 return
     set nocount on
   
     /* delete all rev bdown codes for this rev code */
     delete bEMTF
     from bEMTF e, deleted d
     where e.EMCo = d.EMCo and e.RevTemplate = d.RevTemplate and e.Equipment = d.Equipment and
     	e.EMGroup = d.EMGroup and e.RevCode = d.RevCode
   
   
   /* Audit insert */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMTE','EM Company: ' + convert(char(3), d.EMCo) + ' Equipment: ' + d.Equipment + ' Revtemplate: ' + d.RevTemplate +
       ' EMGroup: ' + convert(varchar(3),d.EMGroup) + ' RevCode: ' + d.RevCode,
       d.EMCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   	from deleted d, EMCO e
       where d.EMCo = e.EMCo and e.AuditRevenueRateEquip = 'Y'
   
   
     return
   
     error:
        select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMTE'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMTEi    Script Date: 8/28/99 9:37:22 AM ******/
   
    CREATE   trigger [dbo].[btEMTEi] on [dbo].[bEMTE] for insert as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  insert trigger for EMTE
     *  Created By: bc 10/27/98
     *  Modified by: TV 02/11/04 - 23061 added isnulls
	 *				 GP	06/03/2008	Issue #124676 - Add check for CopyFlag value before inserting default
	 *									record into bEMTF.
     *
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
    declare @revbdowncode varchar(10), @bdowncodedesc varchar(30), @copy_flag bYN, @type_flag char(1)
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
   
   /* validate EMCo */
   select @validcnt = count(*) from bEMCO e join inserted i on e.EMCo = i.EMCo
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid EM Company '
     goto error
     end
   
   /* validate RevTemplate */
   select @validcnt = count(*) from bEMTH e join inserted i on e.EMCo = i.EMCo and e.RevTemplate = i.RevTemplate
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid Revenue template '
     goto error
     end
   
   
   /* validate EMGroup */
   select @validcnt = count(*) from bHQGP e join inserted i on e.Grp = i.EMGroup
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid EM Group '
     goto error
     end
   
   /* validate Equipment */
   select @validcnt = count(*) from bEMEM e join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Equipment
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid Equipment '
     goto error
     end
   
   /* validate RevCode */
   select @validcnt = count(*) from bEMRC e join inserted i on e.EMGroup = i.EMGroup and e.RevCode = i.RevCode
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid Revenue Code '
     goto error
     end
   
   /* validate AllowPostOride */
   select @validcnt = count(*) from inserted i where AllowOrideFlag in('Y','N')
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Missing Allow posting overide Flag '
     goto error
     end
   
   /* snag the default revenue breakdown code rom EM Company file */
    select @revbdowncode = UseRevBkdwnCodeDefault
    from EMCO e, inserted i
    where e.EMCo = i.EMCo
   
    if @revbdowncode is null
      begin
      select @errmsg = 'Missing default revenue breakdown code in Company form!'
      goto error
      end
   
   /* the revbdowncode description for new EMTF entries */
    select @bdowncodedesc = Description
    from EMRT e, inserted i
    where e.EMGroup = i.EMGroup and e.RevBdownCode = @revbdowncode
   
	/* get the CopyFlag value so we know if we should insert a new record into EMTF below */
	select @copy_flag = CopyFlag
	from bEMTH e join inserted i 
	on e.EMCo = i.EMCo and e.RevTemplate = i.RevTemplate

   /* acquire the type flag from EMTH so we know whether or not to add row to breakdown code */
   select @type_flag = TypeFlag
   from EMTH e, inserted i
   where e.EMCo = i.EMCo and e.RevTemplate = i.RevTemplate
   
   if @type_flag = 'O' and @copy_flag = 'N'
   begin
   /* insert default Bdown code into EMTF when a new entry is made into EMTE */
    	insert into bEMTF (EMCo, EMGroup, RevTemplate, Equipment, RevCode, RevBdownCode, Description, Rate)
    	select i.EMCo, i.EMGroup, i.RevTemplate, i.Equipment, i.RevCode, @revbdowncode, @bdowncodedesc, i.Rate
    	from inserted i
   
    	if @@rowcount <> 1
    		begin
    		select @errmsg = 'Errors updating the revenue breakdown code'
    		goto error
    		end
   end
   
   /* Audit insert */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMTE','EM Company: ' + convert(char(3), i.EMCo) + ' Equipment: ' + i.Equipment + ' Revtemplate: ' + i.RevTemplate +
       ' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
       i.EMCo, 'A', null, null, null, getdate(), SUSER_SNAME()
   	from inserted i, EMCO e
       where i.EMCo = e.EMCo and e.AuditRevenueRateEquip = 'Y'
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMTE'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
   
/****** Object:  Trigger dbo.btEMTEu    Script Date: 8/28/99 9:37:22 AM ******/
 
CREATE   trigger [dbo].[btEMTEu] on [dbo].[bEMTE] for update as
  

/***  basic declares for SQL Triggers ****/
declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
@errno tinyint, @audit bYN, @validcnt int, @nullcnt int,@changeinprogress bYN
   
/*--------------------------------------------------------------
*
*  update trigger for EMTE
*  Created By: bc 05/20/99
*  Modified by: TV 02/11/04 - 23061 added isnulls
*
*
*--------------------------------------------------------------*/
   
/*** declare local variables ***/
declare @revbdowncode varchar(10), @bdowncodedesc varchar(30), @type_flag char(1), @rate bDollar,
@emco bCompany, @emgroup bGroup, @revtemp varchar(10), @equip bEquip, @revcode varchar(10)
   
select @numrows = @@rowcount, @changeinprogress ='N'

if @numrows = 0 return

set nocount on
   
   
if update(EMCo) or update(EMGroup) or update(RevTemplate) or update(Equipment) or update(RevCode)
begin
	/* Issue 126196 Check to see if equipment code is being changed.
	Select Where EMEM.LastUsedEquipmentCode = EMWH.Equipment*/
	select @changeinprogress=IsNull(ChangeInProgress,'N')
	from bEMEM e, inserted i where e.EMCo = i.EMCo and e.LastUsedEquipmentCode = i.Equipment
	and e.ChangeInProgress = 'Y'

	--Issue 126196 Only run code if Equipment Code is not being changed
	If @changeinprogress = 'N' 
	begin
		select @validcnt = count(*) from inserted i join deleted d on
		i.EMCo = d.EMCo and i.EMGroup = d.EMGroup and i.RevTemplate = d.RevTemplate and i.Equipment = i.Equipment and i.RevCode = d.RevCode
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Cannot change key fields '
			goto error
		end
	end
end
   
/* validate AllowOrideFlag */
if update(AllowOrideFlag)
begin
	select @validcnt = count(*) from inserted i where AllowOrideFlag in('Y','N')
	if @validcnt <> @numrows
    begin
		select @errmsg = 'Missing Allow posting overide Flag '
		goto error
	end
end
   
/* acquire the type flag from EMTH so we know whether or not to add row to breakdown code */
select @type_flag = TypeFlag from EMTH e, inserted i where e.EMCo = i.EMCo and e.RevTemplate = i.RevTemplate
   
if @type_flag = 'O'
begin
    if update(Rate)
	begin
		--Issue 126196 Only run code if Equipment Code is not being changed
		If @changeinprogress = 'N' 
		begin
			select @rate = i.Rate, @emco = i.EMCo, @emgroup = i.EMGroup,
			@revtemp = i.RevTemplate, @equip = i.Equipment, @revcode = i.RevCode
			from EMTF d, inserted i
			where d.EMCo = i.EMCo and d.EMGroup = i.EMGroup and d.RevTemplate = i.RevTemplate and d.Equipment = i.Equipment and
			d.RevCode = i.RevCode
			if @@rowcount = 1
			begin
				/* update lone Bdown code in EMTF when a change is made in EMTE */
				update bEMTF
				set Rate = @rate
				where EMCo = @emco and EMGroup = @emgroup and RevTemplate = @revtemp and Equipment = @equip and RevCode = @revcode
			end
		end
    end
end
   
/* Audit inserts */
if not exists (select * from inserted i, EMCO e where i.EMCo = e.EMCo and e.AuditRevenueRateEquip = 'Y')
	begin
		return
	end
else
--Issue 126196 Only run code if Equipment Code is not being changed
	If @changeinprogress = 'N' 
	begin
		insert into bHQMA select 'bEMTE', 'EM Company: ' + convert(char(3), i.EMCo) + ' RevTemplate: ' + i.RevTemplate + ' Equipment: ' + i.Equipment +
		' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
		i.EMCo, 'C', 'AllowOrideFlag', d.AllowOrideFlag, i.AllowOrideFlag, getdate(), SUSER_SNAME()
		from inserted i, deleted d, EMCO e
		where i.EMCo = d.EMCo and i.RevTemplate = d.RevTemplate and i.Equipment = d.Equipment and
		i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.AllowOrideFlag <> d.AllowOrideFlag and
		e.EMCo = i.EMCo and e.AuditRevenueRateEquip = 'Y'
   
		insert into bHQMA select 'bEMTE', 'EM Company: ' + convert(char(3), i.EMCo) + ' RevTemplate: ' + i.RevTemplate + ' Equipment: ' + i.Equipment +
		' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
		i.EMCo, 'C', 'Rate', d.Rate, i.Rate, getdate(), SUSER_SNAME()
		from inserted i, deleted d, EMCO e
		where i.EMCo = d.EMCo and i.RevTemplate = d.RevTemplate and i.Equipment = d.Equipment and
		i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.Rate <> d.Rate and
		e.EMCo = i.EMCo and e.AuditRevenueRateEquip = 'Y'
   
	    insert into bHQMA select 'bEMTE', 'EM Company: ' + convert(char(3), i.EMCo) + ' RevTemplate: ' + i.RevTemplate + ' Equipment: ' + i.Equipment +
		' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
		i.EMCo, 'C', 'DiscFromStdRate', d.Rate, i.Rate, getdate(), SUSER_SNAME()
		from inserted i, deleted d, EMCO e
		where i.EMCo = d.EMCo and i.RevTemplate = d.RevTemplate and i.Equipment = d.Equipment and
		i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.DiscFromStdRate <> d.DiscFromStdRate and
		e.EMCo = i.EMCo and e.AuditRevenueRateEquip = 'Y'
	end  

 return
   
 error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EMTE'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
  
 



GO
