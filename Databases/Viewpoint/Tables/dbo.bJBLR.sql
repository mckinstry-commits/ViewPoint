CREATE TABLE [dbo].[bJBLR]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[LaborCategory] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[RestrictByEarn] [dbo].[bYN] NOT NULL,
[EarnType] [dbo].[bEarnType] NULL,
[RestrictByFactor] [dbo].[bYN] NOT NULL,
[Factor] [dbo].[bRate] NULL,
[RestrictByShift] [dbo].[bYN] NOT NULL,
[Shift] [tinyint] NULL,
[RateOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Rate] [dbo].[bUnitCost] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[NewRate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJBLR_NewRate] DEFAULT ((0)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJBLR] ON [dbo].[bJBLR] ([JBCo], [Template], [LaborCategory], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biJBLR_EarnFactShift] ON [dbo].[bJBLR] ([JBCo], [LaborCategory], [Template], [RestrictByEarn], [EarnType], [RestrictByFactor], [Factor], [RestrictByShift], [Shift]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBLR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBLRd] ON [dbo].[bJBLR]
   FOR DELETE 
   AS
   
   

/**************************************************************
   *  Created by: ALLENN 11/16/2001 Issue #13667
   *  Modified by:  TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   
   **************************************************************/
   
   declare @errmsg varchar(255)
   set nocount on
   
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
   Select 'bJBLR', 'JBCo: ' + convert(varchar(3),d.JBCo) + 'Template: ' + d.Template + 'LaborCategory: ' + d.LaborCategory + 'Seq: ' + convert(varchar(10),d.Seq), d.JBCo, 'D', null, null, null, getdate(), SUSER_SNAME() 
   From deleted d 
   Join bJBCO c on c.JBCo = d.JBCo 
   Where c.AuditTemplate = 'Y'
   
   return
   
   error:
   select @errmsg = 'Cannot delete JBLR!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBLRi] ON [dbo].[bJBLR]
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
   Select 'bJBLR', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
   From inserted i 
   Join bJBCO c on c.JBCo = i.JBCo 
   Where c.AuditTemplate = 'Y'
   
   return
   
   error:
   select @errmsg = 'Cannot insert JBLR!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  TRIGGER [dbo].[btJBLRu] ON [dbo].[bJBLR]
   FOR UPDATE
   AS
   
   

/**************************************************************
   *  Created by: ALLENN 11/16/2001 Issue #13667
   *  Modified by: kb 2/13/2 - issue #16222 (got error if changed Factor,
   *		  changed the comparison between the inserted and deleted to be 0 is null instead of ''
   *		TJL 04/14/04 - Issue #24304, HQMA Audit for Factor (old & new), change to varchar(8)
   *		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   *		TJL 05/12/04 - Issue #24592, Corrected (where isnull(d.Factor,99.999999) <> isnull(i.Factor,99.999999)) during HQMA update
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
   
   If exists(select * from inserted i join bJBCO c on i.JBCo = c.JBCo where c.AuditCo = 'Y' )
   BEGIN
   If Update(RestrictByEarn)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLR', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'RestrictByEarn', d.RestrictByEarn, i.RestrictByEarn, getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.RestrictByEarn <> i.RestrictByEarn
        and c.AuditTemplate = 'Y'
        End
   
   If Update(EarnType)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLR', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'EarnType', convert(varchar(5), d.EarnType), convert(varchar(5), i.EarnType), getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where isnull(d.EarnType,-32768) <> isnull(i.EarnType,-32768)
        and c.AuditTemplate = 'Y'
        End
   
   If Update(RestrictByFactor)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLR', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'RestrictByFactor', d.RestrictByFactor, i.RestrictByFactor, getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.RestrictByFactor <> i.RestrictByFactor
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Factor)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLR', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Factor', convert(varchar(9), d.Factor), convert(varchar(9), i.Factor), getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where isnull(d.Factor,99.999999) <> isnull(i.Factor,99.999999)
        and c.AuditTemplate = 'Y'
        End
   
   If Update(RestrictByShift)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLR', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'RestrictByShift', d.RestrictByShift, i.RestrictByShift, getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.RestrictByShift <> i.RestrictByShift
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Shift)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLR', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Shift', convert(varchar(3), d.Shift), convert(varchar(3), i.Shift), getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where isnull(d.Shift,0) <> isnull(i.Shift,0)
        and c.AuditTemplate = 'Y'
        End
   
   If Update(RateOpt)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLR', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'RateOpt', d.RateOpt, i.RateOpt, getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.RateOpt <> i.RateOpt
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Rate)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLR', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Rate', convert(varchar(17), d.Rate), convert(varchar(17), i.Rate), getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.Rate <> i.Rate
        and c.AuditTemplate = 'Y'
        End
   
   If Update(NewRate)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLR', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'NewRate', convert(varchar(17), d.NewRate), convert(varchar(17), i.NewRate), getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.NewRate <> i.NewRate
        and c.AuditTemplate = 'Y'
        End
   
   END
   
   return
   
   error:
   select @errmsg = @errmsg + ' - cannot update JBLR!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBLR].[RestrictByEarn]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBLR].[RestrictByFactor]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBLR].[RestrictByShift]'
GO
