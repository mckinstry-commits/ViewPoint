CREATE TABLE [dbo].[bINCO]
(
[INCo] [dbo].[bCompany] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[Jrnl] [dbo].[bJrnl] NOT NULL,
[GLAdjInterfaceLvl] [tinyint] NOT NULL,
[GLAdjSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLAdjDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLTrnsfrInterfaceLvl] [tinyint] NOT NULL,
[GLTrnsfrSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLTrnsfrDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLProdInterfaceLvl] [tinyint] NOT NULL,
[GLProdSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLProdDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ValMethod] [tinyint] NOT NULL,
[CostMethod] [tinyint] NOT NULL,
[BurdenCost] [dbo].[bYN] NOT NULL,
[MiscGLAcct] [dbo].[bGLAcct] NULL,
[TaxGLAcct] [dbo].[bGLAcct] NULL,
[CustPriceOpt] [tinyint] NOT NULL,
[JobPriceOpt] [tinyint] NOT NULL,
[InvPriceOpt] [tinyint] NOT NULL,
[EquipPriceOpt] [tinyint] NOT NULL,
[UsageOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[NegWarn] [dbo].[bYN] NOT NULL,
[CostOver] [dbo].[bYN] NOT NULL,
[AuditCoParams] [dbo].[bYN] NOT NULL,
[AuditLoc] [dbo].[bYN] NOT NULL,
[AuditMatl] [dbo].[bYN] NOT NULL,
[AuditBoM] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[OverrideGL] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bINCO_OverrideGL] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[AutoMO] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bINCO_AutoMO] DEFAULT ('N'),
[LastMO] [dbo].[bMO] NULL,
[CmtdDetailToJC] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bINCO_CmtdDetailToJC] DEFAULT ('N'),
[JCMOInterfaceLvl] [tinyint] NOT NULL CONSTRAINT [DF_bINCO_JCMOInterfaceLvl] DEFAULT ((0)),
[GLMOInterfaceLvl] [tinyint] NOT NULL CONSTRAINT [DF_bINCO_GLMOInterfaceLvl] DEFAULT ((0)),
[GLMOSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLMODetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[AuditMOs] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bINCO_AuditMOs] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bINCO_AttachBatchReportsYN] DEFAULT ('N'),
[ServicePriceOpt] [tinyint] NOT NULL CONSTRAINT [DF__bINCO__ServicePr__388D18D9] DEFAULT ((1))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
CREATE trigger [dbo].[btINCOd] on [dbo].[bINCO] for DELETE as
/*--------------------------------------------------------------
* Created: GR 03/07/00
* Modified: GG 04/20/07 - #30116 - data security review, added validation checks
*
* Delete trigger on IN Companies; rollback if any of the following conditions exist:
*	IN Location Groups exist
*
*	Audits deletions in bHQMA
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- check IN Locations
if exists(select top 1 1 from dbo.bINLM l (nolock) join deleted d on l.INCo = d.INCo)
    begin
   	select @errmsg = 'Inventory Locations exist'
   	goto error
   	end

-- check IN Location Groups
if exists(select top 1 1 from dbo.bINLG l (nolock) join deleted d on l.INCo = d.INCo)
    begin
   	select @errmsg = 'Inventory Location Groups exist'
   	goto error
   	end
   
-- HQ Auditing
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bINCO','INCo:' + convert(varchar(3),INCo), INCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted
 
return
   
error:
	select @errmsg = @errmsg + ' - cannot delete IN Company'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btINCOi] on [dbo].[bINCO] for INSERT as
/*--------------------------------------------------------------
* Created By: GR 03/07/00
* Modified: GG 03/13/00 - fixed insert into bHQMA
*			GG 04/20/07 - #30116 - data security review
*			  TRL 02/18/08 --#21452	
*
* This trigger rejects update in bINCO (IN Company) if the following error condition exists:
*		Invalid HQ Company number
*
* Adds to master audit table
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

/* validate IN Company */
select @validcnt = count(*) from inserted i join dbo.bHQCO h (nolock) on i.INCo = h.HQCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid IN Company, must be setup in HQ first.'
	goto error
	end
   
-- HQ Auditing
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bINCO',' INCo: ' + convert(varchar, INCo), INCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted

--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bINCO',  'IN Co#: ' + convert(char(3), INCo), INCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted

--#30116 - initialize Data Security
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bINCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bINCo', i.INCo, i.INCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bINCo' and s.Qualifier = i.INCo 
						and s.Instance = convert(char(30),i.INCo) and s.SecurityGroup = @dfltsecgroup)
	end 
   
return

error:
	select @errmsg = @errmsg + ' - cannot insert IN Company.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE   trigger [dbo].[btINCOu] on [dbo].[bINCO] for UPDATE as
   
   
   

/*-----------------------------------------------------------------
    *  Created: GR 02/29/00
    *	Modified: RM 01/18/02 - Added audits for Material Order Columns
    *			  TRL 02/18/08 --#21452	
    *
    * Validates and inserts HQ Master Audit entry.
    * Updates CostMethod in INLM - Location Master,
    * INLO - Location Category Override
    *
    * Cannot change primary key - IN Company
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int, @valmethod int
   
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   --check for key changes
   select @validcnt = count(*) from deleted d
       join inserted i on d.INCo = i.INCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change IN Company'
   	goto error
   	end
   
   -- validate GL Adjustment Interface Level
   if update (GLAdjInterfaceLvl)
   	begin
       select @validcnt = count(*) from inserted
           where GLAdjInterfaceLvl in (0,1,2)
       if @validcnt <> @numrows
           begin
   	   select @errmsg = 'Invalid GL Adjustment Interface Level'
   	   goto error
   	   end
   	end
   
   -- validate GL Transfer Interface Level
   if update (GLTrnsfrInterfaceLvl)
       begin
       select @validcnt = count(*) from inserted
           where GLTrnsfrInterfaceLvl in (0,1,2)
       if @validcnt <> @numrows
           begin
   	   select @errmsg = 'Invalid GL Transfer Interface Level'
   	   goto error
   	   end
       end
   
   -- validate Production Interface Level
   if update(GLProdInterfaceLvl)
       begin
       select @validcnt = count(*) from inserted
           where GLProdInterfaceLvl in (0,1,2)
       if @validcnt <> @numrows
           begin
   	   select @errmsg = 'Invalid Production Interface Level'
   	   goto error
   	   end
       end
   
   --update Location master and Location Override
   if update(ValMethod)
       begin
       select @valmethod = i.ValMethod from inserted i, deleted d
       where i.INCo = d.INCo and i.ValMethod <> d.ValMethod
       if @valmethod = 4
           begin
           update bINLM
             set bINLM.CostMethod=3
             from bINLM, inserted where inserted.INCo = bINLM.INCo
           update bINLO
             set bINLO.CostMethod=3
             from bINLO, inserted where inserted.INCo = bINLO.INCo
           end
       end
   
   
   --Insert records into HQMA for changes made to audited fields
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'GL Company', convert(char(3),d.GLCo), Convert(char(3),i.GLCo),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.INCo <> d.INCo
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Jrnl', d.Jrnl, i.Jrnl, getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.Jrnl <> d.Jrnl
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'GL Adj Interface', convert(char(1),d.GLAdjInterfaceLvl), Convert(char(1),i.GLAdjInterfaceLvl),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.GLAdjInterfaceLvl <> d.GLAdjInterfaceLvl
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'GL Adj Summary Desc', d.GLAdjSummaryDesc, i.GLAdjSummaryDesc,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.GLAdjSummaryDesc <> d.GLAdjSummaryDesc
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'GL Adj Detail Desc', d.GLAdjDetailDesc, i.GLAdjDetailDesc,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.GLAdjDetailDesc <> d.GLAdjDetailDesc
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'GL Transfer Interface', convert(char(1),d.GLTrnsfrInterfaceLvl), Convert(char(1),i.GLTrnsfrInterfaceLvl),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.GLTrnsfrInterfaceLvl <> d.GLTrnsfrInterfaceLvl
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'GL Transfer Summary Desc', d.GLTrnsfrSummaryDesc, i.GLTrnsfrSummaryDesc,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.GLTrnsfrSummaryDesc <> d.GLTrnsfrSummaryDesc
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'GL Transfer Detail Desc', d.GLTrnsfrDetailDesc, i.GLTrnsfrDetailDesc,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.GLTrnsfrDetailDesc <> d.GLTrnsfrDetailDesc
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'GL Prod Interface', convert(char(1),d.GLProdInterfaceLvl), Convert(char(1),i.GLProdInterfaceLvl),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.GLProdInterfaceLvl <> d.GLProdInterfaceLvl
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'GL Prod Summary Desc', d.GLProdSummaryDesc, i.GLProdSummaryDesc,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.GLProdSummaryDesc <> d.GLProdSummaryDesc
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'GL Prod Detail Desc', d.GLProdDetailDesc, i.GLProdDetailDesc,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.GLProdDetailDesc <> d.GLProdDetailDesc
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Valuation Method', d.ValMethod, i.ValMethod,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.ValMethod <> d.ValMethod
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Cost Method', d.CostMethod, i.CostMethod,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.CostMethod <> d.CostMethod
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Burden Cost', d.BurdenCost, i.BurdenCost,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.BurdenCost <> d.BurdenCost
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Misc GL Account', d.MiscGLAcct, i.MiscGLAcct,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.MiscGLAcct <> d.MiscGLAcct
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Tax GL Account', d.TaxGLAcct, i.TaxGLAcct,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.TaxGLAcct <> d.TaxGLAcct
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Customer Price Opt', d.CustPriceOpt, i.CustPriceOpt,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.CustPriceOpt <> d.CustPriceOpt
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Job Price Opt', d.JobPriceOpt, i.JobPriceOpt,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.JobPriceOpt <> d.JobPriceOpt
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Inventory Price Opt', d.InvPriceOpt, i.InvPriceOpt,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.InvPriceOpt <> d.InvPriceOpt
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Equip Price Opt', d.EquipPriceOpt, i.EquipPriceOpt,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.EquipPriceOpt <> d.EquipPriceOpt
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Usage Opt', d.UsageOpt, i.UsageOpt,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.UsageOpt <> d.UsageOpt
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Negative Warn', d.NegWarn, i.NegWarn,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.NegWarn <> d.NegWarn
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Cost Override', d.CostOver, i.CostOver,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.CostOver <> d.CostOver
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Audit Location', d.AuditLoc, i.AuditLoc,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.AuditLoc <> d.AuditLoc
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Audit Material', d.AuditMatl, i.AuditMatl,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.AuditMatl <> d.AuditMatl
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Audit Bill Of Materials', d.AuditBoM, i.AuditBoM,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.AuditBoM <> d.AuditBoM
   
   
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Auto Seq Material Orders', d.AutoMO, i.AutoMO,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.AutoMO <> d.AutoMO
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Last Material Order', d.LastMO, i.LastMO,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.LastMO <> d.LastMO
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Committed Detail to JC', d.CmtdDetailToJC, i.CmtdDetailToJC,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.CmtdDetailToJC <> d.CmtdDetailToJC
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'JCMO Interface Level', d.JCMOInterfaceLvl, i.JCMOInterfaceLvl,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.JCMOInterfaceLvl <> d.JCMOInterfaceLvl
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'GLMO Interface Level', d.GLMOInterfaceLvl, i.GLMOInterfaceLvl,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.GLMOInterfaceLvl <> d.GLMOInterfaceLvl
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'GLMO Summary Description', d.GLMOSummaryDesc, i.GLMOSummaryDesc,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.GLMOSummaryDesc <> d.GLMOSummaryDesc
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'GLMO Detail Description', d.GLMODetailDesc, i.GLMODetailDesc,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.GLMODetailDesc <> d.GLMODetailDesc
   
   insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Audit Material Orders', d.AuditMOs, i.AuditMOs,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.AuditMOs <> d.AuditMOs
   
--#21452
If update(AttachBatchReportsYN)
begin
	insert into bHQMA select 'bINCO', 'IN Co#: ' + convert(char(3),i.INCo), i.INCo, 'C',
   	'Attach Batch Reports YN', d.AttachBatchReportsYN, i.AttachBatchReportsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.INCo = d.INCo and i.AttachBatchReportsYN <> d.AttachBatchReportsYN
end

   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update IN Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biINCO] ON [dbo].[bINCO] ([INCo]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINCO] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINCO].[BurdenCost]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINCO].[NegWarn]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINCO].[CostOver]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINCO].[AuditCoParams]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINCO].[AuditLoc]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINCO].[AuditMatl]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINCO].[AuditBoM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINCO].[OverrideGL]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINCO].[AutoMO]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINCO].[CmtdDetailToJC]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINCO].[AuditMOs]'
GO
