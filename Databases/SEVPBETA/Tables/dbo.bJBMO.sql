CREATE TABLE [dbo].[bJBMO]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[OverrideOpt] [char] (1) COLLATE Latin1_General_BIN NULL,
[Rate] [dbo].[bRate] NOT NULL,
[SpecificPrice] [dbo].[bUnitCost] NOT NULL,
[CostOpt] [char] (1) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[NewSpecificPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJBMO_NewSpecificPrice] DEFAULT ((0)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBMOd] ON [dbo].[bJBMO]
   FOR DELETE 
   AS
   
   

/**************************************************************
   *  Created by: ALLENN 11/16/2001 Issue #13667
   *  Modified by:
   **************************************************************/
   
   declare @errmsg varchar(255)
   set nocount on
   
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
   Select 'bJBMO', 'JBCo: ' + convert(varchar(3),d.JBCo) + 'Template: ' + d.Template + 'MatlGroup: ' + convert(varchar(3),d.MatlGroup) + 'Material: ' + d.Material, d.JBCo, 'D', null, null, null, getdate(), SUSER_SNAME() 
   From deleted d 
   Join bJBCO c on c.JBCo = d.JBCo 
   Where  c.AuditTemplate = 'Y'
   
   return
   
   error:
   select @errmsg = 'Cannot delete JBMO!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBMOi] ON [dbo].[bJBMO]
   FOR INSERT 
   AS
   
    

/**************************************************************
     *  Created by: ALLENN 11/16/2001 Issue #13667
     *  Modified by:
     **************************************************************/
   
   declare @errmsg varchar(255)
   set nocount on
   
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
   Select 'bJBMO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'MatlGroup: ' + convert(varchar(3),i.MatlGroup) + 'Material: ' + i.Material, i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
   From inserted i 
   Join bJBCO c on c.JBCo = i.JBCo 
   Where c.AuditTemplate = 'Y'
   
   return
   
   error:
   select @errmsg = 'Cannot insert JBMO!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  TRIGGER [dbo].[btJBMOu] ON [dbo].[bJBMO]
   FOR UPDATE 
   AS
   
   

/**************************************************************
   *  Created by: ALLENN 11/16/2001 Issue #13667
   *  Modified by:  TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
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
   
   If Update(MatlGroup) 
        Begin
        select @errmsg = 'Cannot change MatlGroup'
        GoTo error
        End
   
   If Update(Material) 
        Begin
        select @errmsg = 'Cannot change Material'
        GoTo error
        End
   
   If exists(select * from inserted i join bJBCO c on i.JBCo = c.JBCo where (c.AuditCo = 'Y' and c.AuditTemplate = 'Y') )
   BEGIN
   If Update(OverrideOpt) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBMO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'MatlGroup: ' + convert(varchar(3),i.MatlGroup) + 'Material: ' + i.Material, i.JBCo, 'C', 'OverrideOpt', d.OverrideOpt, i.OverrideOpt, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.MatlGroup = i.MatlGroup and d.Material = i.Material
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.OverrideOpt,'') <> isnull(i.OverrideOpt,'')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Rate) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBMO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'MatlGroup: ' + convert(varchar(3),i.MatlGroup) + 'Material: ' + i.Material, i.JBCo, 'C', 'Rate', convert(varchar(9), d.Rate), convert(varchar(9), i.Rate), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.MatlGroup = i.MatlGroup and d.Material = i.Material
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.Rate <> i.Rate
        and c.AuditTemplate = 'Y'
        End
   
   If Update(SpecificPrice) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBMO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'MatlGroup: ' + convert(varchar(3),i.MatlGroup) + 'Material: ' + i.Material, i.JBCo, 'C', 'SpecificPrice', convert(varchar(17), d.SpecificPrice), convert(varchar(17), i.SpecificPrice), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.MatlGroup = i.MatlGroup and d.Material = i.Material
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.SpecificPrice <> i.SpecificPrice
        and c.AuditTemplate = 'Y'
        End
   
   If Update(NewSpecificPrice) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBMO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'MatlGroup: ' + convert(varchar(3),i.MatlGroup) + 'Material: ' + i.Material, i.JBCo, 'C', 'NewSpecificPrice', convert(varchar(17), d.NewSpecificPrice), convert(varchar(17), i.NewSpecificPrice), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.MatlGroup = i.MatlGroup and d.Material = i.Material
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.NewSpecificPrice <> i.NewSpecificPrice
        and c.AuditTemplate = 'Y'
        End
   
   If Update(CostOpt) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBMO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'MatlGroup: ' + convert(varchar(3),i.MatlGroup) + 'Material: ' + i.Material, i.JBCo, 'C', 'CostOpt', d.CostOpt, i.CostOpt, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.MatlGroup = i.MatlGroup and d.Material = i.Material
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.CostOpt,'') <> isnull(i.CostOpt,'')
        and c.AuditTemplate = 'Y'
        End
   
   END
   
   return
   
   error:
   select @errmsg = @errmsg + ' - cannot update JBMO!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJBMO] ON [dbo].[bJBMO] ([JBCo], [Template], [MatlGroup], [Material]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBMO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
