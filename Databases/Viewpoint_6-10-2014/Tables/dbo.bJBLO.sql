CREATE TABLE [dbo].[bJBLO]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[LaborCategory] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[RestrictByEmployee] [dbo].[bYN] NOT NULL,
[PRCo] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[RestrictByClass] [dbo].[bYN] NOT NULL,
[Class] [dbo].[bClass] NULL,
[RestrictByCraft] [dbo].[bYN] NOT NULL,
[Craft] [dbo].[bCraft] NULL,
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
[NewRate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJBLO_NewRate] DEFAULT ((0)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBLOd] ON [dbo].[bJBLO]
   FOR DELETE 
   AS
   
   

/**************************************************************
   *  Created by: ALLENN 11/16/2001 Issue #13667
   *  Modified by: TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   *
   **************************************************************/
   
   declare @errmsg varchar(255)
   set nocount on
   
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
   Select 'bJBLO', 'JBCo: ' + convert(varchar(3),d.JBCo) + 'Template: ' + d.Template + 'LaborCategory: ' + d.LaborCategory + 'Seq: ' + convert(varchar(10),d.Seq), d.JBCo, 'D', null, null, null, getdate(), SUSER_SNAME() 
   From deleted d 
   Join bJBCO c on c.JBCo = d.JBCo 
   Where c.AuditTemplate = 'Y'
   
   return
   
   error:
   select @errmsg = 'Cannot delete JBLO!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btJBLOi] ON [dbo].[bJBLO]
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
   Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
   From inserted i 
   Join bJBCO c on c.JBCo = i.JBCo 
   Where c.AuditTemplate = 'Y'
   
   return
   
   error:
   select @errmsg = 'Cannot insert JBLO!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  TRIGGER [dbo].[btJBLOu] ON [dbo].[bJBLO]
   FOR UPDATE
   AS
   

/**************************************************************
   *  Created by: ALLENN 11/16/2001 Issue #13667
   *  Modified by: kb 2/13/2 - issue #16222 (got error if changed Factor,
   *		  changed the comparison between the inserted and deleted to be 0 is null instead of ''
   *		TJL 04/14/04 - Issue #24304, HQMA Audit for Factor (old & new), change to varchar(8)
   *		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   *		TJL 05/12/04 - Issue #24592,  Corrected (where isnull(d.Factor,99.999999) <> isnull(i.Factor,99.999999)) during HQMA update
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
   
   
   If exists(select * from inserted i join bJBCO c on i.JBCo = c.JBCo where (c.AuditCo = 'Y' and c.AuditTemplate = 'Y') )
   BEGIN
   If Update(RestrictByEmployee)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'RestrictByEmployee', d.RestrictByEmployee, i.RestrictByEmployee, getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.RestrictByEmployee <> i.RestrictByEmployee
        and c.AuditTemplate = 'Y'
        End
   
   If Update(PRCo)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'PRCo', convert(varchar(3), d.PRCo), convert(varchar(3), i.PRCo), getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where isnull(d.PRCo,0) <> isnull(i.PRCo,0)
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Employee)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'Employee', convert(varchar(10), d.Employee), convert(varchar(10), i.Employee), getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where isnull(d.Employee,-2147483648) <> isnull(i.Employee,-2147483648)
        and c.AuditTemplate = 'Y'
        End
   
   If Update(RestrictByClass)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'RestrictByClass', d.RestrictByClass, i.RestrictByClass, getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.RestrictByClass <> i.RestrictByClass
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Class)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'Class', d.Class, i.Class, getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where isnull(d.Class,'') <> isnull(i.Class,'')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(RestrictByCraft)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'RestrictByCraft', d.RestrictByCraft, i.RestrictByCraft, getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.RestrictByCraft <> i.RestrictByCraft
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Craft)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Craft', d.Craft, i.Craft, getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where isnull(d.Craft,'') <> isnull(i.Craft,'')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(RestrictByEarn)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'RestrictByEarn', d.RestrictByEarn, i.RestrictByEarn, getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.RestrictByEarn <> i.RestrictByEarn
        and c.AuditTemplate = 'Y'
        End
   
   If Update(EarnType)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'EarnType', convert(varchar(5), d.EarnType), convert(varchar(5), i.EarnType), getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where isnull(d.EarnType,-32768) <> isnull(i.EarnType,-32768)
        and c.AuditTemplate = 'Y'
        End
   
   If Update(RestrictByFactor)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'RestrictByFactor', d.RestrictByFactor, i.RestrictByFactor, getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.RestrictByFactor <> i.RestrictByFactor
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Factor)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'Factor', convert(varchar(9), d.Factor), convert(varchar(9), i.Factor), getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where isnull(d.Factor,99.999999) <> isnull(i.Factor,99.999999)
        and c.AuditTemplate = 'Y'
        End
   
   If Update(RestrictByShift)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'RestrictByShift', d.RestrictByShift, i.RestrictByShift, getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.RestrictByShift <> i.RestrictByShift
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Shift)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'Shift', convert(varchar(3), d.Shift), convert(varchar(3), i.Shift), getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where isnull(d.Shift,0) <> isnull(i.Shift,0)
        and c.AuditTemplate = 'Y'
        End
   
   If Update(RateOpt)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'RateOpt', d.RateOpt, i.RateOpt, getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.RateOpt <> i.RateOpt
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Rate)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'Rate', convert(varchar(17), d.Rate), convert(varchar(17), i.Rate), getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.Rate <> i.Rate
        and c.AuditTemplate = 'Y'
        End
   
   If Update(NewRate)
        Begin
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBLO', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'LaborCategory: ' + i.LaborCategory + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'NewRate', convert(varchar(17), d.NewRate), convert(varchar(17), i.NewRate), getdate(), SUSER_SNAME()
        From inserted i
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.LaborCategory = i.LaborCategory and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
        Where d.NewRate <> i.NewRate
        and c.AuditTemplate = 'Y'
        End
   END
   
     return
   
     error:
     select @errmsg = @errmsg + ' - cannot update JBLO!'
   
     RAISERROR(@errmsg, 11, -1);
     rollback transaction
   
   
  
 



GO
ALTER TABLE [dbo].[bJBLO] WITH NOCHECK ADD CONSTRAINT [CK_bJBLO_RestrictByClass] CHECK (([RestrictByClass]='Y' OR [RestrictByClass]='N'))
GO
ALTER TABLE [dbo].[bJBLO] WITH NOCHECK ADD CONSTRAINT [CK_bJBLO_RestrictByCraft] CHECK (([RestrictByCraft]='Y' OR [RestrictByCraft]='N'))
GO
ALTER TABLE [dbo].[bJBLO] WITH NOCHECK ADD CONSTRAINT [CK_bJBLO_RestrictByEarn] CHECK (([RestrictByEarn]='Y' OR [RestrictByEarn]='N'))
GO
ALTER TABLE [dbo].[bJBLO] WITH NOCHECK ADD CONSTRAINT [CK_bJBLO_RestrictByEmployee] CHECK (([RestrictByEmployee]='Y' OR [RestrictByEmployee]='N'))
GO
ALTER TABLE [dbo].[bJBLO] WITH NOCHECK ADD CONSTRAINT [CK_bJBLO_RestrictByFactor] CHECK (([RestrictByFactor]='Y' OR [RestrictByFactor]='N'))
GO
ALTER TABLE [dbo].[bJBLO] WITH NOCHECK ADD CONSTRAINT [CK_bJBLO_RestrictByShift] CHECK (([RestrictByShift]='Y' OR [RestrictByShift]='N'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biJBLO_EmplClassCraft] ON [dbo].[bJBLO] ([JBCo], [Template], [LaborCategory], [RestrictByEmployee], [PRCo], [Employee], [RestrictByClass], [Class], [RestrictByCraft], [Craft], [RestrictByEarn], [EarnType], [RestrictByFactor], [Factor], [RestrictByShift], [Shift]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJBLO] ON [dbo].[bJBLO] ([JBCo], [Template], [LaborCategory], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBLO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
