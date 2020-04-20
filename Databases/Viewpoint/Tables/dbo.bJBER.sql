CREATE TABLE [dbo].[bJBER]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[EMCo] [dbo].[bCompany] NOT NULL,
[EquipCategory] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[RestrictByEquip] [dbo].[bYN] NOT NULL,
[Equipment] [dbo].[bEquip] NULL,
[RestrictByRevCode] [dbo].[bYN] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[RevCode] [dbo].[bRevCode] NULL,
[RateOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Rate] [dbo].[bUnitCost] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[NewRate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJBER_NewRate] DEFAULT ((0)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJBER] ON [dbo].[bJBER] ([JBCo], [Template], [EMCo], [EquipCategory], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biJBER_EquipRevCode] ON [dbo].[bJBER] ([JBCo], [Template], [EquipCategory], [RestrictByEquip], [EMCo], [Equipment], [RestrictByRevCode], [RevCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBER] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBERd] ON [dbo].[bJBER]
   FOR DELETE 
   AS
   
   

/**************************************************************
   *  Created by: ALLENN 11/16/2001 Issue #13667
   *  Modified by:	TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   *
   *
   **************************************************************/
   
   declare @errmsg varchar(255)
   set nocount on
   
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBER', 'JBCo: ' + convert(varchar(3),d.JBCo) + 'Template: ' + d.Template + 'EMCo: ' + convert(varchar(3),d.EMCo) + 'EquipCategory: ' + d.EquipCategory + 'Seq: ' + convert(varchar(10),d.Seq), d.JBCo, 'D', null, null, null, getdate(), SUSER_SNAME() 
        From deleted d 
        Join bJBCO c on c.JBCo = d.JBCo 
        Where c.AuditTemplate = 'Y'
   
   return
   
   error:
   select @errmsg = 'Cannot delete JBER!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBERi] ON [dbo].[bJBER]
   FOR INSERT 
   AS
   
   

/**************************************************************
   *  Created by: ALLENN 11/16/2001 Issue #13667
   *  Modified by:	TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   *
   **************************************************************/
   
   declare @errmsg varchar(255)
   set nocount on
   
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBER', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'EMCo: ' + convert(varchar(3),i.EMCo) + 'EquipCategory: ' + i.EquipCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
        From inserted i 
        Join bJBCO c on c.JBCo = i.JBCo 
        Where c.AuditTemplate = 'Y'
   
     return
   
     error:
     select @errmsg = 'Cannot insert JBER!'
   
     RAISERROR(@errmsg, 11, -1);
     rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  TRIGGER [dbo].[btJBERu] ON [dbo].[bJBER]
   FOR UPDATE 
   AS
   
   

/**************************************************************
   *  Created by: ALLENN 11/16/2001 Issue #13667
   *  Modified by:	TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   *		TJL 01/14/05 - Issue #17896, Add HQMA updates for new column called NewRate
   *
   **************************************************************/
   
   declare @errmsg varchar(255)
   set nocount on
   
   
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
   
   If Update(EMCo) 
        Begin
        select @errmsg = 'Cannot change EMCo'
        GoTo error
        End
   
   If Update(EquipCategory) 
        Begin
        select @errmsg = 'Cannot change EquipCategory'
        GoTo error
        End
   
   If Update(Seq) 
        Begin
        select @errmsg = 'Cannot change Seq'
        GoTo error
        End
   
   If exists(select * from inserted i join bJBCO c on i.JBCo = c.JBCo where (c.AuditCo = 'Y' and c.AuditTemplate = 'Y') )
   BEGIN
   If Update(RestrictByEquip) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBER', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'EMCo: ' + convert(varchar(3),i.EMCo) + 'EquipCategory: ' + i.EquipCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'RestrictByEquip', d.RestrictByEquip, i.RestrictByEquip, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.EMCo = i.EMCo and d.EquipCategory = i.EquipCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.RestrictByEquip <> i.RestrictByEquip
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Equipment) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBER', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'EMCo: ' + convert(varchar(3),i.EMCo) + 'EquipCategory: ' + i.EquipCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Equipment', d.Equipment, i.Equipment, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.EMCo = i.EMCo and d.EquipCategory = i.EquipCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.Equipment,'') <> isnull(i.Equipment,'')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(RestrictByRevCode) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBER', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'EMCo: ' + convert(varchar(3),i.EMCo) + 'EquipCategory: ' + i.EquipCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'RestrictByRevCode', d.RestrictByRevCode, i.RestrictByRevCode, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.EMCo = i.EMCo and d.EquipCategory = i.EquipCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.RestrictByRevCode <> i.RestrictByRevCode
        and c.AuditTemplate = 'Y'
        End
   
   If Update(EMGroup) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBER', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'EMCo: ' + convert(varchar(3),i.EMCo) + 'EquipCategory: ' + i.EquipCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'EMGroup', convert(varchar(3), d.EMGroup), convert(varchar(3), i.EMGroup), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.EMCo = i.EMCo and d.EquipCategory = i.EquipCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.EMGroup <> i.EMGroup
        and c.AuditTemplate = 'Y'
        End
   
   If Update(RevCode) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBER', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'EMCo: ' + convert(varchar(3),i.EMCo) + 'EquipCategory: ' + i.EquipCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'RevCode', d.RevCode, i.RevCode, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.EMCo = i.EMCo and d.EquipCategory = i.EquipCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.RevCode,'') <> isnull(i.RevCode,'')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(RateOpt) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBER', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'EMCo: ' + convert(varchar(3),i.EMCo) + 'EquipCategory: ' + i.EquipCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'RateOpt', d.RateOpt, i.RateOpt, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.EMCo = i.EMCo and d.EquipCategory = i.EquipCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.RateOpt <> i.RateOpt
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Rate) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBER', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'EMCo: ' + convert(varchar(3),i.EMCo) + 'EquipCategory: ' + i.EquipCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Rate', convert(varchar(17), d.Rate), convert(varchar(17), i.Rate), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.EMCo = i.EMCo and d.EquipCategory = i.EquipCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.Rate <> i.Rate
        and c.AuditTemplate = 'Y'
        End
   
   If Update(NewRate) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBER', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'EMCo: ' + convert(varchar(3),i.EMCo) + 'EquipCategory: ' + i.EquipCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'NewRate', convert(varchar(17), d.NewRate), convert(varchar(17), i.NewRate), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.EMCo = i.EMCo and d.EquipCategory = i.EquipCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.NewRate <> i.NewRate
        and c.AuditTemplate = 'Y'
        End
   END
   
     return
   
     error:
     select @errmsg = @errmsg + ' - cannot update JBER!'
   
     RAISERROR(@errmsg, 11, -1);
     rollback transaction
   
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBER].[RestrictByEquip]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBER].[RestrictByRevCode]'
GO
