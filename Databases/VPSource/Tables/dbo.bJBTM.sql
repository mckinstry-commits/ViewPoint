CREATE TABLE [dbo].[bJBTM]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[SortOrder] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[LaborRateOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[LaborOverrideYN] [dbo].[bYN] NOT NULL,
[EquipRateOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[LaborCatYN] [dbo].[bYN] NOT NULL,
[EquipCatYN] [dbo].[bYN] NOT NULL,
[MatlCatYN] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[CopyInProgress] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBTM_CopyInProgress] DEFAULT ('N'),
[LaborEffectiveDate] [dbo].[bDate] NULL,
[EquipEffectiveDate] [dbo].[bDate] NULL,
[MatlEffectiveDate] [dbo].[bDate] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bJBTM] ADD
CONSTRAINT [CK_bJBTM_CopyInProgress] CHECK (([CopyInProgress]='Y' OR [CopyInProgress]='N'))
ALTER TABLE [dbo].[bJBTM] ADD
CONSTRAINT [CK_bJBTM_EquipCatYN] CHECK (([EquipCatYN]='Y' OR [EquipCatYN]='N'))
ALTER TABLE [dbo].[bJBTM] ADD
CONSTRAINT [CK_bJBTM_LaborCatYN] CHECK (([LaborCatYN]='Y' OR [LaborCatYN]='N'))
ALTER TABLE [dbo].[bJBTM] ADD
CONSTRAINT [CK_bJBTM_LaborOverrideYN] CHECK (([LaborOverrideYN]='Y' OR [LaborOverrideYN]='N'))
ALTER TABLE [dbo].[bJBTM] ADD
CONSTRAINT [CK_bJBTM_MatlCatYN] CHECK (([MatlCatYN]='Y' OR [MatlCatYN]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
CREATE  TRIGGER [dbo].[btJBTMd] ON [dbo].[bJBTM]
FOR DELETE AS
   
/*************************************************************************
*	This trigger rejects delete of bJBTM
*	 if the following error condition exists:
*		none
*
*  Created by: kb 8/28/00
*  Modified by: bc 09/12/00
*		ALLENN 11/16/2001 Issue #13667
*		TJL 07/09/03 - Issue #21800, Remove Record from bJBLO upon Delete
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		DANF 09/14/2004 - Issue 19246 added new login
*		TJL  09/11/06 - Issue #121618, Dis-allow the delete when Template value on Open/SoftClosed Contracts
*
**************************************************************************/
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
	@co bCompany, @template varchar(10)

select @numrows = @@rowcount

if @numrows = 0 return
set nocount on
   
select @co = min(JBCo) from deleted d
while @co is not null
	begin
	select @template = min(Template) from deleted d where JBCo = @co
	while @template is not null
 		begin

 		if @template in ('STD ACTDT','STD CONT','STD PHASE','STD SEQ') and SUSER_SNAME() <> 'bidtek' and SUSER_SNAME() <> 'viewpointcs'
   			begin
   			select @errmsg = 'Cannot delete standard templates'
   			goto error
   			end

		if exists(select 1
			from bJCCM m with (nolock)
			where m.JCCo = @co and m.ContractStatus in (1, 2) and m.JBTemplate = @template)
			begin
   			select @errmsg = 'Open or Soft Closed Contracts exist that are set to use this Template.'
			select @errmsg = @errmsg + char(10) + char(13) + 'Template will not be deleted.'
   			goto error
			end

		delete from bJBTS where JBCo = @co and Template = @template
		delete from bJBLR where JBCo = @co and Template = @template
		delete from bJBLO where JBCo = @co and Template = @template
		delete from bJBMO where JBCo = @co and Template = @template
		delete from bJBER where JBCo = @co and Template = @template

 		select @template = min(Template) 
		from deleted d 
		where JBCo = @co and Template > @template

 		if @@rowcount = 0 select @template = null
 		end
   
   	select @co = min(JBCo) from deleted d where JBCo > @co
	if @@rowcount = 0 select @co = null
	end
   
/*Issue 13667*/
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
Select 'bJBTM', 'JBCo: ' + convert(varchar(3),d.JBCo) + 'Template: ' + d.Template, d.JBCo, 'D', null, null, null, getdate(), SUSER_SNAME() 
From deleted d 
Join bJBCO c on c.JBCo = d.JBCo 
Where c.AuditTemplate = 'Y'
   
return

error:
select @errmsg = @errmsg + ' - cannot delete JBTM!'

RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE Trigger [dbo].[btJBTMi] ON [dbo].[bJBTM]
   For Insert
   As
   
    

/**************************************************************
     *  Created by: ALLENN 11/16/2001 Issue #13667
     *  Modified by:  TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
     **************************************************************/
   
   declare @errmsg varchar(255)
   set nocount on
   
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTM', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template, i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
        From inserted i 
        Join bJBCO c on c.JBCo = i.JBCo 
        Where c.AuditTemplate = 'Y'
   
   return
   
    error:
    select @errmsg = 'Cannot insert JBTM!'
   
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBTMu] ON [dbo].[bJBTM] FOR UPDATE AS
   

/**************************************************************
   *
   *  Created by: bc 10/24/00
   *  Modified by: ALLENN 11/16/2001 Issue #13667
   *		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   *		DANF 09/14/2004 - Issue 19246 added new login
   *		TJL 01/14/05 - Issue #17896, Add HQMA updates for new column called NewRate
   *
   **************************************************************/
     declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
             @co bCompany, @template varchar(10)
   
     select @numrows = @@rowcount
   
     if @numrows = 0 return
     set nocount on
   
   /*Issue 13667*/
   If Update(JBCo) 
        Begin
        select @errmsg = 'Cannot change JBCo'
        GoTo error
        End
   
   If Update(Template) 
        Begin
        select @errmsg = 'Cannot change Template'
        GoTo error
        End
   
   if not update(CopyInProgress)
   	begin
   	select @co = min(JBCo)
   	  from inserted
   	while @co is not null
   		begin
   	    select @template = min(Template)
   	    from inserted
   	    where JBCo = @co
   	    while @template is not null
   	      begin
   	
   	      if @template in ('STD ACTDT','STD CONT','STD PHASE','STD SEQ') and SUSER_SNAME() <> 'bidtek' and SUSER_SNAME() <> 'viewpointcs'
   	        begin
   	        select @errmsg = 'Cannot edit standard templates'
   	        goto error
   	        end
   	
   	      select @template = min(Template)
   	      from inserted
   	      where JBCo = @co and Template > @template
   	      if @@rowcount = 0 select @template = null
   	      end
   	
   	    select @co = min(JBCo) from inserted where JBCo > @co
   	    if @@rowcount = 0 select @co = null
   	    end
   	end
   
   /*Issue 13667*/
   If exists(select * from inserted i join bJBCO c on i.JBCo = c.JBCo where (c.AuditCo = 'Y' and c.AuditTemplate = 'Y'))
   BEGIN
   If Update(Description) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTM', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template, i.JBCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.Description,'') <> isnull(i.Description,'')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(SortOrder) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTM', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template, i.JBCo, 'C', 'SortOrder', d.SortOrder, i.SortOrder, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.SortOrder <> i.SortOrder
        and c.AuditTemplate = 'Y'
        End
   
   If Update(LaborRateOpt) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTM', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template, i.JBCo, 'C', 'LaborRateOpt', d.LaborRateOpt, i.LaborRateOpt, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.LaborRateOpt <> i.LaborRateOpt
        and c.AuditTemplate = 'Y'
        End
   
   If Update(LaborOverrideYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTM', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template, i.JBCo, 'C', 'LaborOverrideYN', d.LaborOverrideYN, i.LaborOverrideYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.LaborOverrideYN <> i.LaborOverrideYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(EquipRateOpt) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTM', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template, i.JBCo, 'C', 'EquipRateOpt', d.EquipRateOpt, i.EquipRateOpt, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.EquipRateOpt <> i.EquipRateOpt
        and c.AuditTemplate = 'Y'
        End
   
   If Update(LaborCatYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTM', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template, i.JBCo, 'C', 'LaborCatYN', d.LaborCatYN, i.LaborCatYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.LaborCatYN <> i.LaborCatYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(EquipCatYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTM', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template, i.JBCo, 'C', 'EquipCatYN', d.EquipCatYN, i.EquipCatYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.EquipCatYN <> i.EquipCatYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(MatlCatYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTM', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template, i.JBCo, 'C', 'MatlCatYN', d.MatlCatYN, i.MatlCatYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.MatlCatYN <> i.MatlCatYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(LaborEffectiveDate) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTM', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template, i.JBCo, 'C', 'LaborEffectiveDate', convert(varchar(12),d.LaborEffectiveDate), convert(varchar(12),i.LaborEffectiveDate), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.LaborEffectiveDate, '') <> isnull(i.LaborEffectiveDate, '')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(EquipEffectiveDate) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTM', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template, i.JBCo, 'C', 'EquipEffectiveDate', convert(varchar(12),d.EquipEffectiveDate), convert(varchar(12),i.EquipEffectiveDate), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.EquipEffectiveDate, '') <> isnull(i.EquipEffectiveDate, '')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(MatlEffectiveDate) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTM', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template, i.JBCo, 'C', 'MatlEffectiveDate', convert(varchar(12),d.MatlEffectiveDate), convert(varchar(12),i.MatlEffectiveDate), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.MatlEffectiveDate, '') <> isnull(i.MatlEffectiveDate, '')
        and c.AuditTemplate = 'Y'
        End
   END
   
     return
   
     error:
     select @errmsg = @errmsg + ' - cannot update JBTM!'
   
     RAISERROR(@errmsg, 11, -1);
     rollback transaction
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJBTM] ON [dbo].[bJBTM] ([JBCo], [Template]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBTM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTM].[LaborOverrideYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTM].[LaborCatYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTM].[EquipCatYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTM].[MatlCatYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTM].[CopyInProgress]'
GO
