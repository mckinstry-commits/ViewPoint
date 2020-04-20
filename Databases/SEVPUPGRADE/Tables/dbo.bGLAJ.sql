CREATE TABLE [dbo].[bGLAJ]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[Jrnl] [dbo].[bJrnl] NOT NULL,
[EntryId] [smallint] NOT NULL,
[Seq] [tinyint] NOT NULL,
[AllocType] [tinyint] NOT NULL,
[SourceType] [char] (1) COLLATE Latin1_General_BIN NULL,
[SourceAcct] [dbo].[bGLAcct] NULL,
[SourceTotal] [tinyint] NULL,
[SourceBasis] [char] (1) COLLATE Latin1_General_BIN NULL,
[Pct] [dbo].[bPct] NULL,
[RatioType1] [char] (1) COLLATE Latin1_General_BIN NULL,
[RatioAcct1] [dbo].[bGLAcct] NULL,
[RatioTotal1] [tinyint] NULL,
[RatioBasis1] [char] (1) COLLATE Latin1_General_BIN NULL,
[RatioType2] [char] (1) COLLATE Latin1_General_BIN NULL,
[RatioAcct2] [dbo].[bGLAcct] NULL,
[RatioTotal2] [tinyint] NULL,
[RatioBasis2] [char] (1) COLLATE Latin1_General_BIN NULL,
[Amount] [dbo].[bDollar] NULL,
[DrCr] [char] (1) COLLATE Latin1_General_BIN NULL,
[PostToType] [char] (1) COLLATE Latin1_General_BIN NULL,
[PostToGLAcct] [dbo].[bGLAcct] NULL,
[PostToTotal] [tinyint] NULL,
[GLRef] [dbo].[bGLRef] NULL,
[TransDesc] [dbo].[bTransDesc] NULL,
[LastMthToPost] [dbo].[bMonth] NULL,
[Frequency] [dbo].[bFreq] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PostToGLCo] [dbo].[bCompany] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLAJd    Script Date: 8/28/99 9:37:27 AM ******/
   CREATE  trigger [dbo].[btGLAJd] on [dbo].[bGLAJ] for DELETE as
   

/*-----------------------------------------------------------------
    *	This trigger rejects deletion from bGLAJ if the following
    *	error condition exists:
    *
    *		None
    *
    *	Adds HQ Master Audit entry if AuditAutoJrnl in bGLCO is 'Y'.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* Audit GL Auto Journal Entry deletions */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ',	'Jrnl: ' + d.Jrnl + ' Entry: ' + convert(varchar(4),d.EntryId) + ' Seq: ' + convert(varchar(3),d.Seq),
   		d.GLCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   		from deleted d, bGLCO c
   		where d.GLCo = c.GLCo and c.AuditAutoJrnl = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete Auto Journal Entry!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
CREATE trigger [dbo].[btGLAJi] on [dbo].[bGLAJ] for INSERT as
/***********************************************************************
* Created : ??
* Modified: GG - 03/26/08 - #30071 - InterCo Auto Journal entries, cleanup 
*			AR 2/4/2011  - #143291 - adding foreign keys and check constraints, removing trigger look ups
*
* This trigger rejects insertion in bGLAJ (Auto Journal Entries) if any of
* the following error conditions exist:
*
*	Missing Source type
*	Invalid Source GL Account
*	Missing Ratio Type 1
*	Invalid Ratio Account 1
*	Missing Ratio Type 2
*	Invalid Ratio Account 2
*	Invalid Post To Account
*	Invalid Frequency
*
*	Adds HQ Master Audit entry.
****************************************************************/

 declare @numrows int, @validcnt int, @validcnt1 int, @errmsg varchar(255)

 select @numrows = @@rowcount
 if @numrows = 0 return
 set nocount on
 
 /* validate Journal */
 --#142311 -	 handled by foreign key constraint now
 
 /* Allocation Types 1 and 2 (Percent and Ratio) must have a Source Type 
 --#142311 - replacing with a check constraint
 if exists(select top 1 1 from inserted where (AllocType = 1 or AllocType = 2) and SourceType is null)
   	begin
   	select @errmsg = 'Percent and Ratio Allocations require a Source type'
   	goto error
   	end
*/   	
 if exists(select top 1 1 from inserted where AllocType <> 2 
	and (RatioType1 is not null  or RatioAcct1 is not null
   		or RatioTotal1 is not null or RatioBasis1 is not null or RatioType2 is not null or RatioAcct2 is not null
   		or RatioTotal2 is not null or RatioBasis2 is not null))
   	begin
   	select @errmsg = 'Ratio information cannot be included with Percent or Fixed Allocation types'
   	goto error
   	end
 /* validate Source Account */
 select @validcnt = count(*) from inserted where SourceType = 'A'
 select @validcnt1 = count(*)
 from dbo.bGLAC a (nolock)
 join inserted i on a.GLCo = i.GLCo and a.GLAcct = i.SourceAcct
 if @validcnt <> @validcnt1
   	begin
   	select @errmsg = 'Invalid Source GL Account'
   	goto error
   	end

 /* validate Ratio 1 Type 
 --#142311 - replacing with check constraint
 if exists(select top 1 1 from inserted where AllocType = 2 and RatioType1  is null)
   	begin
   	select @errmsg = 'Missing Ratio Type 1'
   	goto error
   	end
 */  	
 /* validate Ratio 1 Account */
 select @validcnt = count(*) from inserted where RatioType1 = 'A'
 select @validcnt1 = count(*)
 from dbo.bGLAC a (nolock)
 join inserted i on a.GLCo = i.GLCo and a.GLAcct = i.RatioAcct1
 if @validcnt <> @validcnt1
   	begin
   	select @errmsg = 'Invalid Ratio Account 1'
   	goto error
   	end
 /* validate Ratio 2 Type
--#142311 - replacing with check constraint
 if exists(select top 1 1 from inserted where AllocType = 2 and RatioType2  is null)
	begin
   	select @errmsg = 'Missing Ratio Type 2'
   	goto error
   	end
*/
 /* validate Ratio 2 Account */
 select @validcnt = count(*) from inserted where RatioType2 = 'A'
 select @validcnt1 = count(*)
 from dbo.bGLAC a (nolock)
 join inserted i on a.GLCo = i.GLCo and a.GLAcct = i.RatioAcct2
 if @validcnt <> @validcnt1
   	begin
   	select @errmsg = 'Invalid Ratio Account 2'
   	goto error
   	end
 /* validate Post To Account */
 select @validcnt = count(*) from inserted where PostToType = 'A'
 select @validcnt1 = count(*)
 from dbo.bGLAC a (nolock)
 join inserted i on a.GLCo = i.PostToGLCo and a.GLAcct = i.PostToGLAcct	-- #30071 use PostToGLCo
 if @validcnt <> @validcnt1
   	begin
   	select @errmsg = 'Invalid Post To Account'
   	goto error
   	end
   	
 /* validate Frequency */
 --#142311 -	 handled by foreign key constraint now
    	
 /* add HQ Master Audit entry */
 insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 select 'bGLAJ',  'Jrnl: ' + Jrnl + ' EntryId: ' + convert(varchar(4),EntryId) + ' Seq: ' + convert(varchar(3),Seq),
   	i.GLCo, 'A', null, null, null, getdate(), SUSER_SNAME()
 from inserted i
 join dbo.bGLCO c (nolock) on i.GLCo = c.GLCo
 where c.AuditAutoJrnl = 'Y'
 
 return
 
 error:
	select @errmsg = @errmsg + ' - cannot insert Auto Journal entry!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   trigger [dbo].[btGLAJu] on [dbo].[bGLAJ] for UPDATE as
/***********************************************************************
* Created : ??
* Modified: GG - 04/22/99 - (SQL 7.0)
*			DanF - 07/26/2005 - Issue 29337 Error in audit of amount when greater than 5 digits
*			GG - 03/26/08 - #30071 - InterCo Auto Journal entries, cleanup 
*			AR 2/4/2011  - #143291 - adding foreign keys, removing trigger look ups
*			AR 2/18/2011  - #143291 - adding check constraints, commenting out trigger look ups
*
*This trigger rejects update to bGLAJ (Auto Journal Entries)
*if any of the following error conditions exist:
*
*	Cannot change GL Co#, Journal, Entry Id, or Seq#
*	Missing Source type
*	Invalid Source GL Account
*	Missing Ratio Type 1
*	Invalid Ratio Account 1
*	Missing Ratio Type 2
*	Invalid Ratio Account 2
*	Invalid Post To Account
*	Invalid Frequency
*
*Adds a record for each updated field to HQ Master Audit as necessary.
************************************************************************/
declare @numrows int, @validcnt int, @validcnt1 int, @errmsg varchar(255) 

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

/* check for key changes */
select @validcnt = count (*)
from deleted d
join inserted i on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId and d.Seq = i.Seq
if @numrows <> @validcnt
	begin
	select @errmsg = 'Cannot change GL Co#, Journal, Entry Id, or Seq#'
	goto error
	end
 --#142311 - replacing with a check constraint
 /*
if update(AllocType) or update(SourceType)
	begin
	/* Allocation Types 1 and 2 (Percent and Ratio) must have a Source Type */
	if exists(select 1 from inserted where (AllocType = 1 or AllocType = 2) and SourceType is null)
   		begin
   		select @errmsg = 'Percent and Ratio Allocations require a Source type'
   		goto error
   		end
   	end
  */	
--#142311 - replacing with a check constraint
/*  
if update(AllocType) or update(RatioType1) or update(RatioAcct1) or update(RatioTotal1) or update(RatioBasis1)
	or update(RatioType2) or update(RatioAcct2) or update(RatioTotal2) or update(RatioBasis2)
	begin
	if exists(select 1 from inserted where AllocType <> 2 and (RatioType1 is not null  or RatioAcct1 is not null
   		or RatioTotal1 is not null or RatioBasis1 is not null or RatioType2 is not null or RatioAcct2 is not null
   		or RatioTotal2 is not null or RatioBasis2 is not null))
   		begin
   		select @errmsg = 'Ratio information cannot be included with Percent or Fixed Allocation types'
   		goto error
   		end
   	end
*/
if update(SourceType) or update(SourceAcct)
	begin 
	/* validate Source Account */
	select @validcnt = count(*) from inserted where SourceType = 'A'
	select @validcnt1 = count(*)
	from dbo.bGLAC a (nolock)
	join inserted i on a.GLCo = i.GLCo and a.GLAcct = i.SourceAcct
	if @validcnt <> @validcnt1
   		begin
   		select @errmsg = 'Invalid Source GL Account'
   		goto error
   		end
   	end

--#142311 - replacing with a check constraint

if update(AllocType) or update(RatioType1) or update(RatioAcct1)
	begin

	/* validate Ratio 1 Type 
	--#142311 - replacing with a check constraint
	if exists(select 1 from inserted where AllocType = 2 and RatioType1  is null)
   		begin
   		select @errmsg = 'Missing Ratio Type 1'
   		goto error
   		end
  */ 	
	/* validate Ratio 1 Account */
	select @validcnt = count(*) from inserted where RatioType1 = 'A'
	select @validcnt1 = count(*)
	from dbo.bGLAC a (nolock)
	join inserted i on a.GLCo = i.GLCo and a.GLAcct = i.RatioAcct1
	if @validcnt <> @validcnt1
   		begin
   		select @errmsg = 'Invalid Ratio Account 1'
   		goto error
   		end
   	end
if update(AllocType) or update(RatioType2) or update(RatioAcct2)
	begin
	/* validate Ratio 2 Type 
	--#142311 - replacing with a check constraint
	if exists(select 1 from inserted where AllocType = 2 and RatioType2  is null)
   		begin
   		select @errmsg = 'Missing Ratio Type 2'
   		goto error
   		END
   	*/
	/* validate Ratio 2 Account */
	select @validcnt = count(*) from inserted where RatioType2 = 'A'
	select @validcnt1 = count(*)
	from dbo.bGLAC a (nolock)
	join inserted i on a.GLCo = i.GLCo and a.GLAcct = i.RatioAcct2
	if @validcnt <> @validcnt1
   		begin
   		select @errmsg = 'Invalid Ratio Account 2'
      	goto error
   		end
   	end
if update(PostToType) or update(PostToGLCo) or update(PostToGLAcct)
	begin
	/* validate Post To Account */
	select @validcnt = count(*) from inserted where PostToType = 'A'
	select @validcnt1 = count(*)
	from dbo.bGLAC a (nolock)
	join inserted i on a.GLCo = i.PostToGLCo and a.GLAcct = i.PostToGLAcct
	if @validcnt <> @validcnt1
   		begin
   		select @errmsg = 'Invalid Post To GL Co# and Account combination'
   		goto error
   		end
   	end

 /* validate Frequency */   	
 --#142311 -	 handled by foreign key constraint now
   	
/*update HQMA */
if update(AllocType)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Alloc Type',  convert(varchar,d.AllocType), convert(varchar,i.AllocType),
   		getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where  d.AllocType <> i.AllocType and c.AuditAutoJrnl = 'Y'
if update(SourceType)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Source Type',  d.SourceType, i.SourceType, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where  isnull(d.SourceType,'') <> isnull(i.SourceType,'') and c.AuditAutoJrnl = 'Y'
if update(SourceAcct)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Source Account',  d.SourceAcct, i.SourceAcct, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where  isnull(d.SourceAcct,'') <> isnull(i.SourceAcct,'') and c.AuditAutoJrnl = 'Y'
if update(SourceTotal)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Source Total',  convert(varchar,d.SourceTotal), convert(varchar,i.SourceTotal),
   		getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.SourceTotal,0) <> isnull(i.SourceTotal,0) and c.AuditAutoJrnl = 'Y'
if update(SourceBasis)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Source Basis',  d.SourceBasis, i.SourceBasis, getdate(), SUSER_SNAME()
    from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.SourceBasis,'') <> isnull(i.SourceBasis,'') and c.AuditAutoJrnl = 'Y'
if update(Pct)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Percent',  convert(varchar,d.Pct), convert(varchar,i.Pct), getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.Pct,0) <> isnull(i.Pct,0) and c.AuditAutoJrnl = 'Y'
if update(RatioType1)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Ratio Type 1',  d.RatioType1, i.RatioType1, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.RatioType1,'') <> isnull(i.RatioType1,'') and c.AuditAutoJrnl = 'Y'
if update(RatioAcct1)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Ratio Acct 1',  d.RatioAcct1, i.RatioAcct1, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.RatioAcct1,'') <> isnull(i.RatioAcct1,'') and c.AuditAutoJrnl = 'Y'
if update(RatioTotal1)
	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Ratio Total 1',  convert(varchar,d.RatioTotal1), convert(varchar,i.RatioTotal1),
   		getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.RatioTotal1,0) <> isnull(i.RatioTotal1,0) and c.AuditAutoJrnl = 'Y'
if update(RatioBasis1)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Ratio Basis 1',  d.RatioBasis1, i.RatioBasis1, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.RatioBasis1,'') <> isnull(i.RatioBasis1,'') and c.AuditAutoJrnl = 'Y'
if update(RatioType2)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Ratio Type 2',  d.RatioType2, i.RatioType2, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.RatioType2,'') <> isnull(i.RatioType2,'') and c.AuditAutoJrnl = 'Y'
if update(RatioAcct2)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Ratio Acct 2',  d.RatioAcct2, i.RatioAcct2, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.RatioAcct2,'') <> isnull(i.RatioAcct2,'') and c.AuditAutoJrnl = 'Y'
if update(RatioTotal2)
	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Ratio Total 2',  convert(varchar,d.RatioTotal2), convert(varchar,i.RatioTotal2),
   		getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.RatioTotal2,0) <> isnull(i.RatioTotal2,0) and c.AuditAutoJrnl = 'Y'
if update(RatioBasis2)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Ratio Basis 2',  d.RatioBasis2, i.RatioBasis2, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.RatioBasis2,'') <> isnull(i.RatioBasis2,'') and c.AuditAutoJrnl = 'Y'
if update(Amount)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Amount',  convert(varchar,d.Amount), convert(varchar,i.Amount), getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.Amount,0) <> isnull(i.Amount,0) and c.AuditAutoJrnl = 'Y'   		
if update(DrCr)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Dr/Cr',  d.DrCr, i.DrCr, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.DrCr,'') <> isnull(i.DrCr,'') and c.AuditAutoJrnl = 'Y'
if update(PostToType)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Post To Type',  d.PostToType, i.PostToType, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.PostToType,'') <> isnull(i.PostToType,'') and c.AuditAutoJrnl = 'Y'
if update(PostToGLAcct)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Post To GL Acct',  d.PostToGLAcct, i.PostToGLAcct, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.PostToGLAcct,'') <> isnull(i.PostToGLAcct,'') and c.AuditAutoJrnl = 'Y'
if update(PostToTotal)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
		i.GLCo, 'C', 'Post To Total',  convert(varchar,d.PostToTotal), convert(varchar,i.PostToTotal),
		getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.PostToTotal,0) <> isnull(i.PostToTotal,0) and c.AuditAutoJrnl = 'Y'          	
if update(GLRef)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'GL Reference',  d.GLRef, i.GLRef, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where d.GLRef <> i.GLRef and c.AuditAutoJrnl = 'Y'
if update(TransDesc)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Trans Description',  d.TransDesc, i.TransDesc, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.TransDesc,'') <> isnull(i.TransDesc,'') and c.AuditAutoJrnl = 'Y'
if update(LastMthToPost)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Last Month To Post',  convert(varchar,d.LastMthToPost,1), convert(varchar,i.LastMthToPost,1),
   		getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.LastMthToPost,'') <> isnull(i.LastMthToPost,'') and c.AuditAutoJrnl = 'Y'
if update(Frequency)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'Frequency',  d.Frequency, i.Frequency, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where d.Frequency <> i.Frequency and c.AuditAutoJrnl = 'Y'
if update(PostToGLCo)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLAJ', 'Jrnl: ' + i.Jrnl + ' EntryId: ' + convert(varchar,i.EntryId) + ' Seq: ' + convert(varchar,i.Seq),
   		i.GLCo, 'C', 'PostToGLCo',  convert(varchar,d.PostToGLCo), convert(varchar,i.PostToGLCo),
   		getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo and d.Jrnl = i.Jrnl and d.EntryId = i.EntryId	and d.Seq = i.Seq
	join dbo.bGLCO c (nolock)on i.GLCo = c.GLCo
	where isnull(d.PostToGLCo,0) <> isnull(i.PostToGLCo,0) and c.AuditAutoJrnl = 'Y'
	
return

error:
   	select @errmsg = @errmsg + ' - cannot update GL Auto Journal Entry!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bGLAJ] ADD CONSTRAINT [CK_bGLAJ_FixedPercentRatio] CHECK (([AllocType]<>(2) AND [RatioType1] IS NULL AND [RatioAcct1] IS NULL AND [RatioBasis1] IS NULL AND [RatioType2] IS NULL AND [RatioAcct2] IS NULL AND [RatioBasis2] IS NULL OR [AllocType]=(2)))
GO
ALTER TABLE [dbo].[bGLAJ] ADD CONSTRAINT [CK_bGLAJ_MissingRatioType] CHECK (([AllocType]=(2) AND [RatioType1] IS NOT NULL OR [AllocType]<>(2)))
GO
ALTER TABLE [dbo].[bGLAJ] ADD CONSTRAINT [CK_bGLAJ_MissingRatioType2] CHECK (([AllocType]=(2) AND [RatioType2] IS NOT NULL OR [AllocType]<>(2)))
GO
ALTER TABLE [dbo].[bGLAJ] ADD CONSTRAINT [CK_bGLAJ_SourceTypeAllocation] CHECK ((([AllocType]=(2) OR [AllocType]=(1)) AND [SourceType] IS NOT NULL OR NOT ([AllocType]=(2) OR [AllocType]=(1))))
GO
ALTER TABLE [dbo].[bGLAJ] ADD CONSTRAINT [PK_bGLAJ] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biGLAJ] ON [dbo].[bGLAJ] ([GLCo], [Jrnl], [EntryId], [Seq]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bGLAJ] WITH NOCHECK ADD CONSTRAINT [FK_bGLAJ_bHQFC_Frequency] FOREIGN KEY ([Frequency]) REFERENCES [dbo].[bHQFC] ([Frequency])
GO
ALTER TABLE [dbo].[bGLAJ] WITH NOCHECK ADD CONSTRAINT [FK_bGLAJ_bGLJR_GLCoJrnl] FOREIGN KEY ([GLCo], [Jrnl]) REFERENCES [dbo].[bGLJR] ([GLCo], [Jrnl])
GO
