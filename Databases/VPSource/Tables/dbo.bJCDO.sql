CREATE TABLE [dbo].[bJCDO]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[OpenWIPAcct] [dbo].[bGLAcct] NULL,
[ClosedExpAcct] [dbo].[bGLAcct] NULL,
[ExcludePR] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bJCDO] ADD
CONSTRAINT [CK_bJCDO_ExcludePR] CHECK (([ExcludePR]='Y' OR [ExcludePR]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btJCDOd] on [dbo].[bJCDO] for DELETE as
   

/**********************************************************************
    *  Created  : ?
    *  Modified : 08/21/02 CMW issue # 18334 - changed bJCCo to bJCCO.
    *
    *	This trigger logs delete of bJCDO (JC Department Phase Override)
    *	rows in bHQMA.
    *
    *********************************************************************/
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   /* Audit insert */
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJCDO', 'JCCo: ' + convert(varchar(3),d.JCCo) + 'Department: ' + convert(varchar(10),d.Department) + 'PhaseGroup: ' + convert(varchar(1),d.PhaseGroup) + 'Phase: ' + convert(varchar(20),d.Phase),d.JCCo, 'D', null, null, null, getdate(), SUSER_SNAME() 
        From deleted d 
        Join bJCCO c on c.JCCo = d.JCCo 
        where c.JCCo=d.JCCo and c.AuditDepts='Y'
   
   
      return
      error:
      	select @errmsg = @errmsg + ' - cannot delete JC Department Phase Override!'
      	RAISERROR(@errmsg, 11, -1);
      	rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  trigger [dbo].[btJCDOi] on [dbo].[bJCDO] for INSERT as
/**********************************************************************
*  Created  : ?
*  Modified : 08/20/02 CMW issue # 18203 - changed validation.
*				GF 10/8/2012 TK-18333 changed phase validation to consider valid part.
*
*
*	This trigger rejects insert in bJCDO (JC Department Phase Override)
*	 if the following error condition exists:
*
*		Invalid JCCo, Phase, or PhaseGroup.
*		Invalid OpenWIPAcct vs GLCo.GLAcct
*		Invalid ClosedExpAcct vs GLCo.GLAcct
*
*********************************************************************/
declare @errmsg varchar(255), @numrows int,  @rcode int,
		@validcnt int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
   

---- TK-18333 
---- validate the JCCo
IF NOT EXISTS(SELECT 1 FROM inserted i JOIN dbo.bHQCO h ON h.HQCo = i.JCCo)
	BEGIN
	SET @errmsg = 'Invalid JC Company'
	GOTO error
	END

----- validate open WIP account
select @nullcnt = count(*) from inserted i where i.OpenWIPAcct is null
select @validcnt = count(*) from inserted i JOIN dbo.bGLAC a ON i.JCCo=a.GLCo AND i.OpenWIPAcct = a.GLAcct
IF @validcnt + @nullcnt <> @numrows
	BEGIN
	SET @errmsg = 'Invalid GL Account selected for OpenWIPAcct'
	GOTO error
	END

---- validate closed wip account
select @nullcnt = count(*) from inserted i where i.ClosedExpAcct is null
select @validcnt = count(*) from inserted i JOIN dbo.bGLAC a ON i.JCCo=a.GLCo AND i.ClosedExpAcct = a.GLAcct
IF @validcnt + @nullcnt <> @numrows
	BEGIN
	SET @errmsg = 'Invalid GL Account selected for ClosedExpAcct'
	GOTO error
	END

---- validate phase group
IF NOT EXISTS(SELECT 1 FROM inserted i JOIN dbo.bHQCO h ON h.HQCo=i.JCCo WHERE i.PhaseGroup=h.PhaseGroup)
	BEGIN
	SET @errmsg = 'Invalid JC Phase Group'
	GOTO error
	END
	
---- validate Phase (exact match) then valid part Phase
IF NOT EXISTS(SELECT 1 FROM inserted i
			JOIN dbo.bJCPM p ON p.PhaseGroup=i.PhaseGroup AND p.Phase=i.Phase)
	BEGIN
	---- first check if we have valid phase characters
	IF EXISTS(SELECT 1 FROM inserted i
					JOIN dbo.bJCCO c ON c.JCCo=i.JCCo
					WHERE c.ValidPhaseChars = 0)
		BEGIN
		SET @errmsg = 'Invalid Phase'
		GOTO error
		END
		
	---- validate valid part phase
	IF NOT EXISTS(SELECT 1 FROM inserted i
					JOIN dbo.bJCCO c ON c.JCCo=i.JCCo
					JOIN dbo.bJCPM p ON p.PhaseGroup=i.PhaseGroup
					WHERE i.JCCo = c.JCCo
						AND p.PhaseGroup = i.PhaseGroup
						AND p.Phase LIKE SUBSTRING(i.Phase, 1, c.ValidPhaseChars) + '%') ----SUBSTRING(p.Phase,1,c.ValidPhaseChars) + '%' = )
		BEGIN
		SET @errmsg = 'Invalid Phase'
		GOTO error
		END
		
	END





---- audit insert
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
Select 'bJCDO', 'JCCo: ' + convert(varchar(3),i.JCCo) + 'Department: ' + convert(varchar(10),i.Department) + 'PhaseGroup: ' + convert(varchar(1),i.PhaseGroup) + 'Phase: ' + convert(varchar(20),i.Phase),i.JCCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
From inserted i Join dbo.bJCCO c on c.JCCo = i.JCCo 
where i.JCCo = c.JCCo
	AND c.AuditDepts = 'Y'



return
error:
	select @errmsg = @errmsg + ' - cannot insert JC Department Phase Override!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   trigger [dbo].[btJCDOu] on [dbo].[bJCDO] for UPDATE as
/**********************************************************************
*  Created  : ?
*  Modified : 08/20/02 CMW issue # 18203 - changed validation.
*				GF 10/08/2012 TK-18333 removed redundent validation
*
*	This trigger rejects insert in bJCDO (JC Department Phase Override)
*	 if the following error condition exists:
*
*		Invalid JCCo, Phase, or PhaseGroup.
*		Invalid OpenWIPAcct vs GLCo.GLAcct
*		Invalid ClosedExpAcct vs GLCo.GLAcct
*
*********************************************************************/
declare @errmsg varchar(255), @numrows int, @rcode int, @validcnt int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
   
   ----TK-18333
   
   If Update(JCCo) 
        Begin 
        select @errmsg = 'Cannot change JCCo'
        GoTo error
        End
   
   If Update(Department) 
        Begin 
        select @errmsg = 'Cannot change Department'
        GoTo error
        End
   
   If Update(PhaseGroup) 
        Begin 
        select @errmsg = 'Cannot change PhaseGroup'
        GoTo error
        End
   
   If Update(Phase) 
        Begin 
        select @errmsg = 'Cannot change Phase'
        GoTo error
        End
   
   
   
   select @nullcnt = count(*) from inserted i where i.OpenWIPAcct is null
   select @validcnt = count(*) from inserted i, bGLAC a
       where i.OpenWIPAcct = a.GLAcct and i.JCCo = a.GLCo
   if (@validcnt+@nullcnt) <> @numrows
   begin
   	select @errmsg = 'Invalid or Null GL Account selected for OpenWIPAcct'
   	goto error
   end
   
   select @nullcnt = count(*) from inserted i where i.ClosedExpAcct is null
   select @validcnt = count(*) from inserted i, bGLAC a
       where i.ClosedExpAcct = a.GLAcct and i.JCCo = a.GLCo
   if (@validcnt+@nullcnt) <> @numrows
   begin
   	select @errmsg = 'Invalid or Null GL Account selected for ClosedExpAcct'
   	goto error
   end
   

   
   If exists(select * from inserted i join bJCCO c on i.JCCo = c.JCCo where c.AuditDepts = 'Y')
   BEGIN
   If Update(GLCo) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJCDO', 'JCCo: ' + convert(varchar(3),i.JCCo) + 'Department: ' + convert(varchar(10),i.Department) + 'PhaseGroup: ' + convert(varchar(1),i.PhaseGroup) + 'Phase: ' + convert(varchar(20),i.Phase),i.JCCo, 'C', 'GLCo', convert(varchar(1), d.GLCo), convert(varchar(1), i.GLCo), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JCCo = i.JCCo and d.Department = i.Department and d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase
        Join bJCCO c on c.JCCo = i.JCCo 
        Where d.GLCo <> i.GLCo
        and c.AuditDepts = 'Y'
        End
   
   If Update(OpenWIPAcct) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJCDO', 'JCCo: ' + convert(varchar(3),i.JCCo) + 'Department: ' + convert(varchar(10),i.Department) + 'PhaseGroup: ' + convert(varchar(1),i.PhaseGroup) + 'Phase: ' + convert(varchar(20),i.Phase),i.JCCo, 'C', 'OpenWIPAcct', d.OpenWIPAcct, i.OpenWIPAcct, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JCCo = i.JCCo and d.Department = i.Department and d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase
        Join bJCCO c on c.JCCo = i.JCCo 
        Where isnull(d.OpenWIPAcct,'') <> isnull(i.OpenWIPAcct,'')
        and c.AuditDepts = 'Y'
        End
   
   If Update(ClosedExpAcct) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJCDO', 'JCCo: ' + convert(varchar(3),i.JCCo) + 'Department: ' + convert(varchar(10),i.Department) + 'PhaseGroup: ' + convert(varchar(1),i.PhaseGroup) + 'Phase: ' + convert(varchar(20),i.Phase),i.JCCo, 'C', 'ClosedExpAcct', d.ClosedExpAcct, i.ClosedExpAcct, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JCCo = i.JCCo and d.Department = i.Department and d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase
        Join bJCCO c on c.JCCo = i.JCCo 
        Where isnull(d.ClosedExpAcct,'') <> isnull(i.ClosedExpAcct,'')
        and c.AuditDepts = 'Y'
        End
   
   If Update(ExcludePR) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJCDO', 'JCCo: ' + convert(varchar(3),i.JCCo) + 'Department: ' + convert(varchar(10),i.Department) + 'PhaseGroup: ' + convert(varchar(1),i.PhaseGroup) + 'Phase: ' + convert(varchar(20),i.Phase),i.JCCo, 'C', 'ExcludePR', d.ExcludePR, i.ExcludePR, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JCCo = i.JCCo and d.Department = i.Department and d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase
        Join bJCCO c on c.JCCo = i.JCCo 
        Where d.ExcludePR <> i.ExcludePR
        and c.AuditDepts = 'Y'
        End
   END
   
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot update JC Department Phase Overrides!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
   
   
   
   
   
  
 




GO
CREATE UNIQUE CLUSTERED INDEX [biJCDO] ON [dbo].[bJCDO] ([JCCo], [Department], [PhaseGroup], [Phase]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCDO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCDO].[ExcludePR]'
GO
