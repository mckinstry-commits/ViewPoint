CREATE TABLE [dbo].[bCMCO]
(
[CMCo] [dbo].[bCompany] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[Jrnl] [dbo].[bJrnl] NOT NULL,
[GLDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLInterfaceLvl] [tinyint] NOT NULL,
[ChangeBegBal] [dbo].[bYN] NOT NULL,
[AuditCoParams] [dbo].[bYN] NOT NULL,
[AuditAccts] [dbo].[bYN] NOT NULL,
[AuditDetail] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bCMCO_AttachBatchReportsYN] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bCMCO] ADD
CONSTRAINT [CK_bCMCO_AuditAccts] CHECK (([AuditAccts]='Y' OR [AuditAccts]='N'))
ALTER TABLE [dbo].[bCMCO] ADD
CONSTRAINT [CK_bCMCO_AuditCoParams] CHECK (([AuditCoParams]='Y' OR [AuditCoParams]='N'))
ALTER TABLE [dbo].[bCMCO] ADD
CONSTRAINT [CK_bCMCO_AuditDetail] CHECK (([AuditDetail]='Y' OR [AuditDetail]='N'))
ALTER TABLE [dbo].[bCMCO] ADD
CONSTRAINT [CK_bCMCO_ChangeBegBal] CHECK (([ChangeBegBal]='Y' OR [ChangeBegBal]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btCMCOd] on [dbo].[bCMCO] for DELETE as
/*----------------------------------------------------------
* Created: ??
* Modified: MH 03/14/04 - #23061
			AR 12/1/2010  - #142311 - adding foreign keys, removing trigger look ups
*
*	This trigger rejects delete in bCMCO (CM Companies) if a
*	dependent record is found in:
*
*		CM Accounts (bCMAC)
*		CM Clearing Entries (bCMCE)
*
*	Adds HQ Master Audit entry.
*/---------------------------------------------------------
declare @errmsg varchar(255)

/* Audit CM Company deletions */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bCMCO', 'CM Co#: ' + convert(varchar(3),isnull(CMCo, '')),
	CMCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted

return
   
error:
   	select @errmsg = @errmsg + ' - cannot delete CM Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btCMCOi] on [dbo].[bCMCO] for INSERT as
/*-----------------------------------------------------------------
* Created: ??
* Modified: MH 3/14/04 - #23061
*			GG 04/18/07 - #30116 - data security
*			TRL 02/18/08 --@21452
			AR 12/1/2010  - #142311 - adding foreign keys, removing trigger look ups

*
*	This trigger rejects insertion in bCMCO (Companies) if the
*	following error condition exists:
*
*		Invalid HQ Company number
*
*	Adds HQ Master Audit entry.
*
*/----------------------------------------------------------------
declare @errmsg varchar(255)


/* add HQ Master Audit entry */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bCMCO',  'CM Co#: ' + convert(char(3), isnull(CMCo, '')), CMCo, 'A',
		 null, null, null, getdate(), SUSER_SNAME()
from inserted
   
--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bCMCO',  'CM Co#: ' + convert(char(3), CMCo), CMCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted

--#30116 - initialize Data Security
declare @dfltsecgroup int
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bCMCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bCMCo', i.CMCo, i.CMCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bCMCo' and s.Qualifier = i.CMCo 
						and s.Instance = convert(char(30),i.CMCo) and s.SecurityGroup = @dfltsecgroup)
	end 

return

error:
   	select @errmsg = @errmsg + ' - cannot insert CM Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/************************************************************************
* CREATED:	
* MODIFIED:	AR 12/1/2010  - #142311 - adding foreign keys, removing trigger look ups
*
* Purpose:

* returns 1 and error msg if failed
*
*************************************************************************/   
   /****** Object:  Trigger dbo.btCMCOu    Script Date: 8/28/99 9:38:20 AM ******/
   CREATE    trigger [dbo].[btCMCOu] on [dbo].[bCMCO] for UPDATE as
   
   

declare @co bCompany, @date bDate, @errmsg varchar(255),
   	@errno int, @field char(30), @cmco bCompany,
   	@key varchar(60), @new varchar(30),
   	@newglco bCompany, @newjrnl bJrnl, @newgldetaildesc varchar(60),
   	@newglsummarydesc varchar(60), @newglinterfacelvl tinyint,
   	@newchangebegbal bYN, @newauditcoparams bYN, @newauditaccts bYN,
   	@newauditdetail bYN, @numrows int, @old varchar(30), 
   	@oldglco bCompany, @oldjrnl bJrnl, @oldgldetaildesc varchar(60),
   	@oldglsummarydesc varchar(60), @oldglinterfacelvl tinyint,
   	@oldchangebegbal bYN, @oldauditcoparams bYN,
   	@oldauditaccts bYN,@oldauditdetail bYN, @opencursor tinyint, @rectype char(1), 
   	@tablename char(20), @user bVPUserName, @validcount int
   
   
   /*-----------------------------------------------------------------
   
    *	This trigger rejects update in bCMCO (CM Companies) if the 
    *	following error condition exists:
    *
    *		Cannot change CM Company
    *
    *		23061 mh 3/14/04
    *
	*			  TRL 02/18/08 --#21452	
	*
    *	Adds record to HQ Master Audit.
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   select @opencursor = 0	/* initialize open cursor flag */
   
   /* check for key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.CMCo = i.CMCo
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change CM Company'
   	goto error
   	end

--#21452
If update(AttachBatchReportsYN)
begin
	insert into bHQMA select 'bCMCO', 'CM Co#: ' + convert(char(3),i.CMCo), i.CMCo, 'C',
   	'Attach Batch Reports YN', d.AttachBatchReportsYN, i.AttachBatchReportsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.CMCo = d.CMCo and i.AttachBatchReportsYN <> d.AttachBatchReportsYN
end 

   if @numrows = 1
   	select @cmco = i.CMCo, 
   		@newglco = i.GLCo, @oldglco = d.GLCo,
   		@newjrnl = i.Jrnl, @oldjrnl = d.Jrnl,
   		@newgldetaildesc = i.GLDetailDesc, @oldgldetaildesc = d.GLDetailDesc,
   		@newglsummarydesc = i.GLSummaryDesc, @oldglsummarydesc = d.GLSummaryDesc,
   		@newglinterfacelvl = i.GLInterfaceLvl, @oldglinterfacelvl = d.GLInterfaceLvl,
   		@newchangebegbal = i.ChangeBegBal, @oldchangebegbal = d.ChangeBegBal,
   		@newauditcoparams = i.AuditCoParams, @oldauditcoparams = d.AuditCoParams,
   		@newauditaccts = i.AuditAccts, @oldauditaccts = d.AuditAccts,
   		@newauditdetail = i.AuditDetail, @oldauditdetail = d.AuditDetail
   		from deleted d, inserted i where d.CMCo = i.CMCo
   else
   	begin
   	/* use a cursor to process each updated row */
   	declare bCMCO_update cursor for select i.CMCo, 
   		NewGLCo = @newglco, OldGLCo = @oldglco,
   		NewJrnl = @newjrnl, OldJrnl = @oldjrnl,
   		NewGLDetailDesc = @newgldetaildesc, OldGLDetailDesc = @oldgldetaildesc,
   		NewGLSummaryDesc = @newglsummarydesc, OldGLSummaryDesc = @oldglsummarydesc,
   		NewGLInterfaceLvl = @newglinterfacelvl, OldGLInterfaceLvl = @oldglinterfacelvl,
   		NewChangeBegBal = @newchangebegbal, OldChangeBegBal = @oldchangebegbal,
   		NewAuditCoParams = @newauditcoparams, OldAuditCoParams = @oldauditcoparams,
   		NewAuditAccts = @newauditaccts, OldAuditAccts = @oldauditaccts,
   		NewAuditDetail = @newauditdetail, OldAuditDetail = @oldauditdetail
   		from deleted d, inserted i where d.CMCo = i.CMCo
   	open bCMCO_update
   	select @opencursor = 1	/*set open cursor flag */
   	fetch next from bCMCO_update into @cmco, 
   		@newglco, @oldglco, 
   		@newjrnl, @oldjrnl, 
   		@newgldetaildesc, @oldgldetaildesc,
   		@newglsummarydesc, @oldglsummarydesc, 
   		@newglinterfacelvl, @oldglinterfacelvl, 
   		@newchangebegbal, @oldchangebegbal, 
   		@newauditcoparams, @oldauditcoparams, 
   		@newauditaccts, @oldauditaccts, 
   
   
   		@newauditdetail, @oldauditdetail 
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   update_check:
   	/* update HQ Master Audit */
   	select @tablename = 'bCMCO', 
   		@key = 'CM Co#: ' + convert(char(3),isnull(@cmco,'')), 
   		@co = @cmco, @rectype = 'C', 
   		@date = getdate(), @user = SUSER_SNAME()
   	if @newglco <> @oldglco
   		begin
   		select @field = 'GLCo', @old = convert(varchar(30),@oldglco), 
   		@new = convert(varchar(30),@newglco)
   		exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   			@old, @new, @date, @user, @errmsg output
   		if @errno <> 0 goto error
   		end
   	if @newjrnl <> @oldjrnl
   		begin
   		select @field = 'Jrnl', @old = @oldjrnl, @new = @newjrnl
   		exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   			@old, @new, @date, @user, @errmsg output
   		if @errno <> 0 goto error
   		end
   	if @newgldetaildesc <> @oldgldetaildesc
   		begin
   		select @field = 'GLDetailDesc', @old = @oldgldetaildesc, @new = @newgldetaildesc
   		exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   			@old, @new, @date, @user, @errmsg output
   		if @errno <> 0 goto error
   		end
   	if @newglsummarydesc <> @oldglsummarydesc
   		begin
   		select @field = 'GLSummaryDesc', @old = @oldglsummarydesc, @new = @newglsummarydesc
   		exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   			@old, @new, @date, @user, @errmsg output
   		if @errno <> 0 goto error
   		end
   	if @newglinterfacelvl <> @oldglinterfacelvl
   		begin
   		select @field = 'GLInterfaceLvl', @old = convert(varchar(30),@oldglinterfacelvl), 
   		@new = convert(varchar(30),@newglinterfacelvl)
   		exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   			@old, @new, @date, @user, @errmsg output
   		if @errno <> 0 goto error
   		end
   	if @newchangebegbal <> @oldchangebegbal
   		begin
   		select @field = 'ChangeBegBal', @old = @oldchangebegbal, @new = @newchangebegbal
   		exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   			@old, @new, @date, @user, @errmsg output
   		if @errno <> 0 goto error
   		end
   	if @newauditcoparams <> @oldauditcoparams
   		begin
   		select @field = 'AuditCoParams', @old = @oldauditcoparams, @new = @newauditcoparams
   		exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   			@old, @new, @date, @user, @errmsg output
   		if @errno <> 0 goto error
   		end
   	if @newauditaccts <> @oldauditaccts
   		begin
   		select @field = 'AuditAccts', @old = @oldauditaccts, @new = @newauditaccts
   		exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   			@old, @new, @date, @user, @errmsg output
   		if @errno <> 0 goto error
   		end
   	if @newauditdetail <> @oldauditdetail
   		begin
   		select @field = 'AuditDetail', @old = @oldauditdetail, @new = @newauditdetail
   		exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   			@old, @new, @date, @user, @errmsg output
   		if @errno <> 0 goto error
   		end
   
   	if @numrows > 1
   		begin
   		fetch next from bCMCO_update into @cmco, 
   			@newglco, @oldglco, 
   			@newjrnl, @oldjrnl, 
   			@newgldetaildesc, @oldgldetaildesc,
   			@newglsummarydesc, @oldglsummarydesc, 
   			@newglinterfacelvl, @oldglinterfacelvl, 
   			@newchangebegbal, @oldchangebegbal, 
   			@newauditcoparams, @oldauditcoparams, 
   			@newauditaccts, @oldauditaccts, 
   			@newauditdetail, @oldauditdetail 
   		if @@fetch_status = 0
   			goto update_check
   		else
   			begin
   			close bCMCO_update
   			deallocate bCMCO_update
   			end
   		end
   
   return
   
   error:
   	if @opencursor = 1
   		begin
   		close bCMCO_update
   		deallocate bCMCO_update
   		end
   		
   	select @errmsg = @errmsg + ' - cannot update CM Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bCMCO] ADD CONSTRAINT [PK_bCMCO_KeyID] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biCMCO] ON [dbo].[bCMCO] ([CMCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bCMCO] WITH NOCHECK ADD CONSTRAINT [FK_bCMCO_bHQCO_CMCo] FOREIGN KEY ([CMCo]) REFERENCES [dbo].[bHQCO] ([HQCo])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bCMCO].[ChangeBegBal]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bCMCO].[AuditCoParams]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bCMCO].[AuditAccts]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bCMCO].[AuditDetail]'
GO
