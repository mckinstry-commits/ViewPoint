CREATE TABLE [dbo].[bSLCO]
(
[SLCo] [dbo].[bCompany] NOT NULL,
[CmtdDetailToJC] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bSLCO_CmtdDetailToJC] DEFAULT ('Y'),
[AuditCoParams] [dbo].[bYN] NOT NULL,
[AuditSLs] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[AuditSLCompliance] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bSLCO_AuditSLCompliance] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bSLCO_AttachBatchReportsYN] DEFAULT ('N'),
[EnforceSLCatchup] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bSLCO_EnforceSLCatchup] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE trigger [dbo].[btSLCOd] on [dbo].[bSLCO] for DELETE as
/*--------------------------------------------------------------
* Created: EN  12/30/99
* Modified: GG 04/20/07 - #30116 - data security review
*
*  Delete trigger for SLCO
*
*  Reject if entries exist in bSLHD or bSLAD.
*  Insert audit entries into bHQMA.
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
   
/* check SL Header */
if exists(select top 1 1 from dbo.bSLHD s (nolock) join deleted d on s.SLCo = d.SLCo)
	begin
	select @errmsg = 'Subcontracts exist'
	goto error
	end
/* check SL Addons */
if exists(select top 1 1 from dbo.bSLAD s (nolock) join deleted d on s.SLCo = d.SLCo)
	begin
	select @errmsg = 'SL Addons exist'
	goto error
	end
   
/* Audit SL Company deletions */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bSLCO', 'SL Co#: ' + convert(varchar(3),SLCo), SLCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted
  
return

error:
	select @errmsg = @errmsg + ' - cannot remove SL Company'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btSLCOi] on [dbo].[bSLCO] for INSERT as
/*--------------------------------------------------------------
* Created: EN  12/30/99 
* Modified: GG 04/20/07 - #30116 - data security review
*			  TRL 02/18/08 --#21452	
*
*  Insert trigger for SLCO
*
*  Validate SL Company in bHQCo.
*  AuditCoParams must be 'Y'.
*
*  Insert audit entries for changed values into bHQMA.
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* validate HQ Company */
select @validcnt = count(*) from dbo.bHQCO c (nolock) join inserted i on c.HQCo = i.SLCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid SLCompany#, must setup in HQ first'
	goto error
	end
   
/* validate AuditCoParams */
select @validcnt = count(*) from inserted where AuditCoParams = 'Y'
if @validcnt <> @numrows
	begin
	select @errmsg = 'Option to audit company parameters must be checked.'
	goto error
	end
   
/* add HQ Master Audit entry */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bSLCO',  'SL Co#: ' + convert(char(3), SLCo), SLCo, 'A', null, null, null, getdate(), SUSER_SNAME()
from inserted

--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bSLCO',  'SL Co#: ' + convert(char(3), SLCo), SLCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted

--#30116 - initialize Data Security
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bSLCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bSLCo', i.SLCo, i.SLCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bSLCo' and s.Qualifier = i.SLCo 
						and s.Instance = convert(char(30),i.SLCo) and s.SecurityGroup = @dfltsecgroup)
	end 
   
return

error:
	select @errmsg = @errmsg + ' - cannot insert SL Company'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 

CREATE trigger [dbo].[btSLCOu] on [dbo].[bSLCO] for UPDATE as
/*--------------------------------------------------------------
*
*  Update trigger for SLCO
*  Created By: 	EN  12/30/99
*	Modified By:	MV 6/24/03 - #21560 - add flags to audit
*			  TRL 02/18/08 --#21452	
*				DC 3/24/09 - #129889 - AUS SL - Track Claimed  and Certified amounts
*				GF 10/18/2012 TK-18032 column removed - no audit
*				GF 12/19/2012 TK-20315 added EnforceSLCatchup column to table
*
*
*  Reject key changes.
*  AuditCoParams must be 'Y'.
*  Insert audit entries for changed values into bHQMA.
*--------------------------------------------------------------*/

declare @numrows int, @errmsg varchar(255), @validcount INT

select @numrows = @@rowcount
if @numrows = 0 return

select @validcount=0

set nocount on
   
/* check for key changes */
select @validcount = count(*) from deleted d, inserted i
where d.SLCo = i.SLCo
if @validcount <> @numrows
	begin
	select @errmsg = 'Cannot change SL Company'
	goto error
	end

/* validate AuditCoParams */
select @validcount = count(*) from inserted where AuditCoParams = 'Y'
if @validcount <> @numrows
	begin
	select @errmsg = 'Option to audit company parameters must be checked.'
	goto error
	end
   
/* HQMA audit posting */
If update(AuditSLs)
	BEGIN
	insert into bHQMA select 'bSLCO', 'SL Co#: ' + convert(char(3),i.SLCo), i.SLCo, 'C',
		'Audit SL :', d.AuditSLs, i.AuditSLs, getdate(), SUSER_SNAME()
	from inserted i, deleted d
	where i.SLCo = d.SLCo and i.AuditSLs <> d.AuditSLs
	END
If update(CmtdDetailToJC)
	BEGIN
	insert into bHQMA select 'bSLCO', 'SL Co#: ' + convert(char(3),i.SLCo), i.SLCo, 'C',
		'Update Cmtd Cost Detail to JC:', d.CmtdDetailToJC, i.CmtdDetailToJC, getdate(), SUSER_SNAME()
	from inserted i, deleted d
	where i.SLCo = d.SLCo and i.CmtdDetailToJC <> d.CmtdDetailToJC
	END
If update(AuditSLCompliance)
	BEGIN
	insert into bHQMA select 'bSLCO', 'SL Co#: ' + convert(char(3),i.SLCo), i.SLCo, 'C',
		'Audit SL Compliance: ', d.AuditSLCompliance, i.AuditSLCompliance, getdate(), SUSER_SNAME()
	from inserted i, deleted d
	where i.SLCo = d.SLCo and i.AuditSLCompliance <> d.AuditSLCompliance
	END
--#21452
If update(AttachBatchReportsYN)
	begin
	insert into bHQMA select 'bSLCO', 'SL Co#: ' + convert(char(3),i.SLCo), i.SLCo, 'C',
	'Attach Batch Reports: ', d.AttachBatchReportsYN, i.AttachBatchReportsYN, getdate(), SUSER_SNAME()
	from inserted i, deleted d
	where i.SLCo = d.SLCo and i.AttachBatchReportsYN <> d.AttachBatchReportsYN
	end

---- TK-20315
If update(EnforceSLCatchup)
	begin
	insert into bHQMA select 'bSLCO', 'SL Co#: ' + convert(char(3),i.SLCo), i.SLCo, 'C',
	'Enforce SL Catchup: ', d.EnforceSLCatchup, i.EnforceSLCatchup, getdate(), SUSER_SNAME()
	from inserted i, deleted d
	where i.SLCo = d.SLCo and i.EnforceSLCatchup <> d.EnforceSLCatchup
	end


return


error:
	select @errmsg = @errmsg + ' - cannot update SL Company '
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
   
   
  
 




GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bSLCO] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biSLCO] ON [dbo].[bSLCO] ([SLCo]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bSLCO].[CmtdDetailToJC]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bSLCO].[AuditCoParams]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bSLCO].[AuditSLs]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bSLCO].[AuditSLCompliance]'
GO
