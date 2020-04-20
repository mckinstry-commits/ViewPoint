CREATE TABLE [dbo].[bJBTC]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[APYN] [dbo].[bYN] NOT NULL,
[EMYN] [dbo].[bYN] NOT NULL,
[INYN] [dbo].[bYN] NOT NULL,
[JCYN] [dbo].[bYN] NOT NULL,
[MSYN] [dbo].[bYN] NOT NULL,
[PRYN] [dbo].[bYN] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[LiabilityType] [dbo].[bLiabilityType] NULL,
[EarnType] [dbo].[bEarnType] NULL,
[EarnLiabTypeOpt] [char] (1) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bJBTC] ADD
CONSTRAINT [CK_bJBTC_APYN] CHECK (([APYN]='Y' OR [APYN]='N'))
ALTER TABLE [dbo].[bJBTC] ADD
CONSTRAINT [CK_bJBTC_EMYN] CHECK (([EMYN]='Y' OR [EMYN]='N'))
ALTER TABLE [dbo].[bJBTC] ADD
CONSTRAINT [CK_bJBTC_INYN] CHECK (([INYN]='Y' OR [INYN]='N'))
ALTER TABLE [dbo].[bJBTC] ADD
CONSTRAINT [CK_bJBTC_JCYN] CHECK (([JCYN]='Y' OR [JCYN]='N'))
ALTER TABLE [dbo].[bJBTC] ADD
CONSTRAINT [CK_bJBTC_MSYN] CHECK (([MSYN]='Y' OR [MSYN]='N'))
ALTER TABLE [dbo].[bJBTC] ADD
CONSTRAINT [CK_bJBTC_PRYN] CHECK (([PRYN]='Y' OR [PRYN]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  TRIGGER [dbo].[btJBTCd] ON [dbo].[bJBTC]
   FOR DELETE 
   AS
   
    

/**************************************************************
     *  Created by: ALLENN 11/16/2001 Issue #13667
     *  Modified by:  TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
     **************************************************************/
   
   declare @errmsg varchar(255)
   set nocount on
   
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTC', 'JBCo: ' + convert(varchar(3),d.JBCo) + 'Template: ' + d.Template + 'Seq: ' + convert(varchar(10),d.Seq) + 'PhaseGroup: ' + convert(varchar(3),d.PhaseGroup) + 'CostType: ' + convert(varchar(3),d.CostType), d.JBCo, 'D', null, null, null, getdate(), SUSER_SNAME() 
        From deleted d 
        Join bJBCO c on c.JBCo = d.JBCo 
        Where c.AuditTemplate = 'Y'
   
     return
   
     error:
     select @errmsg = 'Cannot delete JBTC!'
   
     RAISERROR(@errmsg, 11, -1);
     rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  TRIGGER [dbo].[btJBTCi] ON [dbo].[bJBTC]
   FOR INSERT 
   AS
   
    

/**************************************************************
     *  Created by: ALLENN 11/16/2001 Issue #13667
     *  Modified by:  TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
     **************************************************************/
   
   declare @errmsg varchar(255)
   set nocount on
   
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTC', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq) + 'PhaseGroup: ' + convert(varchar(3),i.PhaseGroup) + 'CostType: ' + convert(varchar(3),i.CostType),i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
        From inserted i 
        Join bJBCO c on c.JBCo = i.JBCo 
        Where c.AuditTemplate = 'Y'
   
     return
   
     error:
     select @errmsg = 'Cannot insert JBTC!'
   
     RAISERROR(@errmsg, 11, -1);
     rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBTCu] ON [dbo].[bJBTC]
   FOR UPDATE 
   AS
   
    

/**************************************************************
     *  Created by: ALLENN 11/16/2001 Issue #13667
     *  Modified by:  TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
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
   
   If Update(Seq) 
        Begin
        select @errmsg = 'Cannot change Seq'
        GoTo error
        End
   
   If Update(PhaseGroup) 
        Begin
        select @errmsg = 'Cannot change PhaseGroup'
        GoTo error
        End
   
   If Update(CostType) 
        Begin
        select @errmsg = 'Cannot change CostType'
        GoTo error
        End
   
   If exists(select * from inserted i join bJBCO c on i.JBCo = c.JBCo where (c.AuditCo = 'Y' and c.AuditTemplate = 'Y') )
   BEGIN
   If Update(APYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTC', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq) + 'PhaseGroup: ' + convert(varchar(3),i.PhaseGroup) + 'CostType: ' + convert(varchar(3),i.CostType),i.JBCo, 'C', 'APYN', d.APYN, i.APYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq and d.PhaseGroup = i.PhaseGroup and d.CostType = i.CostType
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.APYN <> i.APYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(EMYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTC', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq) + 'PhaseGroup: ' + convert(varchar(3),i.PhaseGroup) + 'CostType: ' + convert(varchar(3),i.CostType),i.JBCo, 'C', 'EMYN', d.EMYN, i.EMYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq and d.PhaseGroup = i.PhaseGroup and d.CostType = i.CostType
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.EMYN <> i.EMYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(INYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTC', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq) + 'PhaseGroup: ' + convert(varchar(3),i.PhaseGroup) + 'CostType: ' + convert(varchar(3),i.CostType),i.JBCo, 'C', 'INYN', d.INYN, i.INYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq and d.PhaseGroup = i.PhaseGroup and d.CostType = i.CostType
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.INYN <> i.INYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(JCYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTC', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq) + 'PhaseGroup: ' + convert(varchar(3),i.PhaseGroup) + 'CostType: ' + convert(varchar(3),i.CostType),i.JBCo, 'C', 'JCYN', d.JCYN, i.JCYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq and d.PhaseGroup = i.PhaseGroup and d.CostType = i.CostType
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.JCYN <> i.JCYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(MSYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTC', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq) + 'PhaseGroup: ' + convert(varchar(3),i.PhaseGroup) + 'CostType: ' + convert(varchar(3),i.CostType),i.JBCo, 'C', 'MSYN', d.MSYN, i.MSYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq and d.PhaseGroup = i.PhaseGroup and d.CostType = i.CostType
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.MSYN <> i.MSYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(PRYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTC', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq) + 'PhaseGroup: ' + convert(varchar(3),i.PhaseGroup) + 'CostType: ' + convert(varchar(3),i.CostType),i.JBCo, 'C', 'PRYN', d.PRYN, i.PRYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq and d.PhaseGroup = i.PhaseGroup and d.CostType = i.CostType
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.PRYN <> i.PRYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Category) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTC', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq) + 'PhaseGroup: ' + convert(varchar(3),i.PhaseGroup) + 'CostType: ' + convert(varchar(3),i.CostType),i.JBCo, 'C', 'Category', d.Category, i.Category, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq and d.PhaseGroup = i.PhaseGroup and d.CostType = i.CostType
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.Category,'') <> isnull(i.Category,'')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(LiabilityType) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTC', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq) + 'PhaseGroup: ' + convert(varchar(3),i.PhaseGroup) + 'CostType: ' + convert(varchar(3),i.CostType),i.JBCo, 'C', 'LiabilityType', convert(varchar(5), d.LiabilityType), convert(varchar(5), i.LiabilityType), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq and d.PhaseGroup = i.PhaseGroup and d.CostType = i.CostType
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.LiabilityType,-32768) <> isnull(i.LiabilityType,-32768)
        and c.AuditTemplate = 'Y'
        End
   
   If Update(EarnType) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTC', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq) + 'PhaseGroup: ' + convert(varchar(3),i.PhaseGroup) + 'CostType: ' + convert(varchar(3),i.CostType),i.JBCo, 'C', 'EarnType', convert(varchar(5), d.EarnType), convert(varchar(5), i.EarnType), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq and d.PhaseGroup = i.PhaseGroup and d.CostType = i.CostType
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.EarnType,-32768) <> isnull(i.EarnType,-32768)
        and c.AuditTemplate = 'Y'
        End
   END
   
     return
   
     error:
     select @errmsg = @errmsg + ' - cannot update JBTC!'
   
     RAISERROR(@errmsg, 11, -1);
     rollback transaction
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biJBTC_SeqUnique] ON [dbo].[bJBTC] ([JBCo], [Template], [PhaseGroup], [CostType], [APYN], [EMYN], [INYN], [JCYN], [MSYN], [PRYN], [Category], [EarnLiabTypeOpt], [LiabilityType], [EarnType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJBTC] ON [dbo].[bJBTC] ([JBCo], [Template], [Seq], [PhaseGroup], [CostType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTC].[APYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTC].[EMYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTC].[INYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTC].[JCYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTC].[MSYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTC].[PRYN]'
GO
