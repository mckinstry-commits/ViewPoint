CREATE TABLE [dbo].[bJBLX]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[LaborCategory] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[RestrictByCraft] [dbo].[bYN] NOT NULL,
[Craft] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[RestrictByClass] [dbo].[bYN] NOT NULL,
[Class] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBLXd] ON [dbo].[bJBLX]
   FOR DELETE 
   AS
   
   

/**************************************************************
   *  Created by: ALLENN 11/16/2001 Issue #13667
   *  Modified by:  TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   *
   **************************************************************/
   
   declare @errmsg varchar(255)
   set nocount on
   
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
   Select 'bJBLX', 'JBCo: ' + convert(varchar(3),d.JBCo) + 'LaborCategory: ' + d.LaborCategory + 'Seq: ' + convert(varchar(10),d.Seq), d.JBCo, 'D', null, null, null, getdate(), SUSER_SNAME() 
   From deleted d 
   Join bJBCO c on c.JBCo = d.JBCo 
   Where c.AuditTemplate = 'Y'
   
   return
   
   error:
   select @errmsg = 'Cannot delete JBLX!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  TRIGGER [dbo].[btJBLXi] ON [dbo].[bJBLX]
   FOR INSERT 
   AS
   
   

/**************************************************************
   *  Created by: ALLENN 11/16/2001 Issue #13667
   *  Modified by:  TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   *
   **************************************************************/
   
   declare @errmsg varchar(255)
   set nocount on
   
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
   Select 'bJBLX', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
   From inserted i 
   Join bJBCO c on c.JBCo = i.JBCo 
   Where c.AuditTemplate = 'Y'
   
   return
   
   error:
   select @errmsg = 'Cannot insert JBLX!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBLXu] ON [dbo].[bJBLX]
   FOR UPDATE 
   AS
   
   

/**************************************************************
   *  Created by: ALLENN 11/16/2001 Issue #13667
   *  Modified by: TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   *
   **************************************************************/
   
   declare @errmsg varchar(255)
   set nocount on
   
   If Update(JBCo) 
        Begin
        select @errmsg = 'Cannot change JBCo'
        GoTo error
        End
   
   If Update(LaborCategory) 
        Begin
        select @errmsg = 'Cannot change LaborCategory'
        GoTo error
        End
   
   If Update(Seq) 
        Begin
        select @errmsg = 'Cannot change Seq'
        GoTo error
        End
   
   If exists(select * from inserted i join bJBCO c on i.JBCo = c.JBCo where (c.AuditCo = 'Y' and c.AuditTemplate = 'Y') )
   BEGIN
   If Update(RestrictByCraft) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLX', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'RestrictByCraft', d.RestrictByCraft, i.RestrictByCraft, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.RestrictByCraft <> i.RestrictByCraft
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Craft) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLX', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'Craft', d.Craft, i.Craft, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.Craft,'') <> isnull(i.Craft,'')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(RestrictByClass) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLX', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'RestrictByClass', d.RestrictByClass, i.RestrictByClass, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.RestrictByClass <> i.RestrictByClass
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Class) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLX', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Class', d.Class, i.Class, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.Class,'') <> isnull(i.Class,'')
        and c.AuditTemplate = 'Y'
        End
   END
   
   return
   
   error:
   select @errmsg = @errmsg + ' - cannot update JBLX!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
ALTER TABLE [dbo].[bJBLX] WITH NOCHECK ADD CONSTRAINT [CK_bJBLX_RestrictByClass] CHECK (([RestrictByClass]='Y' OR [RestrictByClass]='N'))
GO
ALTER TABLE [dbo].[bJBLX] WITH NOCHECK ADD CONSTRAINT [CK_bJBLX_RestrictByCraft] CHECK (([RestrictByCraft]='Y' OR [RestrictByCraft]='N'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biJBLX_CraftClass] ON [dbo].[bJBLX] ([JBCo], [Craft], [Class]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJBLX] ON [dbo].[bJBLX] ([JBCo], [LaborCategory], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBLX] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
