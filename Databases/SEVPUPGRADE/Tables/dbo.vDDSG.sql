CREATE TABLE [dbo].[vDDSG]
(
[SecurityGroup] [int] NOT NULL,
[Name] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[GroupType] [tinyint] NOT NULL,
[Description] [varchar] (256) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  trigger [dbo].[vtDDSGd] on [dbo].[vDDSG] for DELETE 
/*-----------------------------------------------------------------
 * Created: GG 07/30/03
 * Modified: JonathanP  04/24/08 - See issue #127475. Added attachment type group type.
 *											AL 03/02/09 - Added HQMA auditing
 *	This trigger rejects delete in vDDSG (Security Groups) if  
 *	the following error condition exists:
 *
 *		Data Security entries exist
 *		Security Group User entries exist
 *		Program Security entries exist
 *		Report Security entries exist
 *
 */----------------------------------------------------------------
as



declare @errmsg varchar(512)

if @@rowcount = 0 return
set nocount on

/* check DD Data Security */
if exists(select top 1 1 from deleted d
		join vDDDS s on d.SecurityGroup = s.SecurityGroup)
	begin
	select @errmsg = 'Data Security entries exist in vDDDS'
	goto error
	end
/* check DD Security Users */
if exists(select top 1 1 from deleted d
		join vDDSU u on d.SecurityGroup = u.SecurityGroup)
	begin
	select @errmsg = 'Security Group Users entries exist'
	goto error
	end


-- VP 6.0 - Security Groups can now be used with Programs and Reports

-- check for use in Program Security
if exists(select top 1 1 from deleted d
		join vDDFS s on d.SecurityGroup = s.SecurityGroup)
	begin
	select @errmsg = 'Program Security entries exist in vDDFS'
	goto error
	end
-- check for use in Report Security
if exists(select top 1 1 from deleted d
		join vRPRS s on d.SecurityGroup = s.SecurityGroup)
	begin
	select @errmsg = 'Report Security entries exist in vRPRS'
	goto error
	end
 
 --check for use in Attachment Type Security
 if exists(select top 1 1 from deleted d
		join vVAAttachmentTypeSecurity s on d.SecurityGroup = s.SecurityGroup)
		begin
	select @errmsg = 'Attachment Type Security entries exist in vVAAttachmentTypeSecurity'
	goto error
	end
 
 -- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vDDSG', 'D', 'SecurityGroup: ' + rtrim(SecurityGroup), null, null,
	null, getdate(), SUSER_SNAME() from deleted


return

error:
 select @errmsg = @errmsg + ' - cannot delete Security Group(s)!'
 RAISERROR(@errmsg, 11, -1);
 rollback transaction
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   trigger [dbo].[vtDDSGi] on [dbo].[vDDSG] for INSERT
/*-----------------------------------------------------------------
 *     Created: GG 7/31/03
 *     Modified: JonathanP 04/24/08 - See issue #127475. Added attachment type group type.
 *                                                                         AL 03/02/09 - Added HQMA auditing
 *     This trigger rejects insert in vDDSG (Security Groups) if
 *     any of the following error conditions exist:
 *
 *            Invalid Security Group (must be 0 or positive)
 *            Invalid Group Type (0 = Data, 1 = Programs, 2 = Reports, 3= Attachment Types)
 *
 *
 */---------------------------------------------------------------- 
as



declare @numrows int, @errmsg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate Security Group
if exists(select top 1 1 from inserted where SecurityGroup < 0)
       begin
       select @errmsg = 'Invalid Security Group #, must be equal to or greater than 0'
       goto error
       end
-- validate Group Type
if exists(select top 1 1 from inserted where GroupType not in (0,1,2,3))
       begin
       select @errmsg = 'Invalid Group Type, must be 0, 1, 2, or 3'
       goto error
       end

-- HQMA Audit               
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
       NewValue, DateTime, UserName)
select 'vDDSG', 'I', 'SecurityGroup: ' + rtrim(SecurityGroup), null, null,
       null, getdate(), SUSER_SNAME() from inserted
       
return

error:
     select @errmsg = @errmsg + ' - cannot insert Security Group(s)!'
     RAISERROR(@errmsg, 11, -1);
     rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   trigger [dbo].[vtDDSGu] on [dbo].[vDDSG] for UPDATE 
/*-----------------------------------------------------------------
 * Created: GG 07/30/03
 * Modified: JonathanP 04/24/08 - See issue #127475. Added attachment type group type.
 *                                                                AL 03/02/09 - Added HQMA Auditing
 *    This trigger rejects update in vDDSG (Security Groups) if any
 *    of the following error conditions exist:
 *
 *          Cannot change Security Group index
 *          Validate Group Type (0 = Data, 1 = Program, 2 = Report)
 *          Cannot change Group Type if detail security entries exist
 *
 */----------------------------------------------------------------
as




declare @errmsg varchar(255), @numrows int, @validcnt int 

select @numrows = @@rowcount
if @numrows = 0 return 

set nocount on
 
/* check for changes to Security Group */
select @validcnt = count(*)
from inserted i
join deleted d on i.SecurityGroup = d.SecurityGroup 
if @validcnt <> @numrows
      begin
      select @errmsg = 'Cannot change Security Group'
      goto error
      end

if update(GroupType)
      begin
      -- validate Group Type 
      if exists(select top 1 1 from inserted where GroupType not in (0,1,2,3))
            begin
            select @errmsg = 'Group Type must be 0, 1, 2, or 3'
            goto error
            end
      -- restrict Group Type changes
      select @validcnt = count(*)
      from inserted i
      join deleted d on i.SecurityGroup = d.SecurityGroup 
      where i.GroupType <> d.GroupType and 
            ((d.GroupType = 0 and d.SecurityGroup in (select s.SecurityGroup from dbo.vDDDS s with (nolock) where s.SecurityGroup = d.SecurityGroup))
                  or (d.GroupType = 1 and d.SecurityGroup in (select s.SecurityGroup from dbo.vDDFS s with (nolock) where s.SecurityGroup = d.SecurityGroup))
                  or (d.GroupType = 2 and d.SecurityGroup in (select s.SecurityGroup from dbo.vRPRS s with (nolock) where s.SecurityGroup = d.SecurityGroup))
                  or (d.GroupType = 3 and d.SecurityGroup in (select s.SecurityGroup from dbo.vVAAttachmentTypeSecurity s with (nolock) where s.SecurityGroup = d.SecurityGroup)))
      if @validcnt > 0
            begin
            select @errmsg = 'Detail security entries exist, cannot change Group Type'
            goto error
            end
      end

--HQMA Audit
if update(GroupType)
      insert dbo.bHQMA(TableName, RecType, KeyString, FieldName,
            OldValue, NewValue, DateTime, UserName)
      select  'vDDSG', 'U', 'SecurityGroup: ' + rtrim(i.SecurityGroup), 'GroupType',
            d.GroupType, i.GroupType, getdate(), SUSER_SNAME()
      from inserted i
      join deleted d on i.SecurityGroup = d.SecurityGroup 
      where isnull(i.GroupType,'') <> isnull(d.GroupType,'')
      
if update(Description)
      insert dbo.bHQMA(TableName, RecType, KeyString, FieldName,
            OldValue, NewValue, DateTime, UserName)
      select  'vDDSG', 'U', 'SecurityGroup: ' + rtrim(i.SecurityGroup), 'Description',
            d.Description, i.Description, getdate(), SUSER_SNAME()
      from inserted i
      join deleted d on i.SecurityGroup = d.SecurityGroup 
      where isnull(i.Description,'') <> isnull(d.Description,'')

return
 
error:
      select @errmsg = @errmsg + ' - cannot update Security Group(s)!'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction


GO
CREATE UNIQUE CLUSTERED INDEX [viDDSG] ON [dbo].[vDDSG] ([SecurityGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
