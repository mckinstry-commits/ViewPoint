CREATE TABLE [dbo].[bJBTA]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[AddonSeq] [int] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJBTA] ON [dbo].[bJBTA] ([JBCo], [Template], [Seq], [AddonSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBTA] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  TRIGGER [dbo].[btJBTAd] ON [dbo].[bJBTA] FOR DELETE AS

/**************************************************************
*
*  Created by: bc 10/24/00
*  Modified by:  ALLENN 11/28/2001 Issue #13667
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		DANF 09/14/2004 - Issue 19246 added new login
*
**************************************************************/
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
	@co bCompany, @template varchar(10), @copy bYN
    
select @numrows = @@rowcount
    
if @numrows = 0 return
set nocount on
    
select @co = min(JBCo) from deleted d
while @co is not null
	begin
	select @template = min(Template) 
	from deleted d 
	where JBCo = @co
	while @template is not null
		begin
		select @copy = CopyInProgress 
		from bJBTM 
		where JBCo = @co and Template = @template  

		if @template in ('STD ACTDT','STD CONT','STD PHASE','STD SEQ') 
			and SUSER_SNAME() <> 'bidtek' and SUSER_SNAME() <> 'viewpointcs' and @copy ='N'
			begin
			select @errmsg = 'Cannot delete standard template information'
			goto error
			end

		select @template = min(Template)
		from deleted d 
		where JBCo = @co and Template > @template
		if @@rowcount = 0 select @template = null
		end

	select @co = min(JBCo) 
	from deleted d 
	where JBCo > @co
	if @@rowcount = 0 select @co = null
	end
    
/*Issue #13667*/
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
Select 'bJBTA', 'JBCo: ' + convert(varchar(3),d.JBCo) + 'Template: ' + d.Template + 'Seq: ' + convert(varchar(10),d.Seq) + 'AddonSeq: ' + convert(varchar(10),d.AddonSeq),
	d.JBCo, 'D', null, null, null, getdate(), SUSER_SNAME() 
From deleted d 
Join bJBCO c on c.JBCo = d.JBCo 
Where c.AuditTemplate = 'Y'
    
return

error:
select @errmsg = @errmsg + ' - cannot delete JBTA!'

RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
CREATE  TRIGGER [dbo].[btJBTAi] ON [dbo].[bJBTA] FOR INSERT AS

/**************************************************************
*
*  Created by: bc 10/24/00
*  Modified by:  ALLENN 11/28/2001 Issue #13667
*		kb 7/22/2 - issue #18040 allow insert if copying template
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		DANF 09/14/2004 - Issue 19246 added new login
*
**************************************************************/
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
	@co bCompany, @template varchar(10), @copy bYN
   
select @numrows = @@rowcount

if @numrows = 0 return
set nocount on
   
select @co = min(JBCo)
from inserted
while @co is not null
	begin
	select @template = min(Template)
	from inserted
	where JBCo = @co
	while @template is not null
		begin
		select @copy = CopyInProgress 
		from bJBTM 
		where JBCo = @co and Template = @template
		if @template in ('STD ACTDT','STD CONT','STD PHASE','STD SEQ') 
   			and SUSER_SNAME() <> 'bidtek' and SUSER_SNAME() <> 'viewpointcs' and @copy ='N'
			begin
			select @errmsg = 'Cannot edit standard templates'
			goto error
			end
   
		select @template = min(Template)
		from inserted
		where JBCo = @co and Template > @template
		if @@rowcount = 0 select @template = null
		end
   
	select @co = min(JBCo) 
	from inserted 
	where JBCo > @co
	if @@rowcount = 0 select @co = null
	end
   
/*Issue #13667*/
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
Select 'bJBTA', 'JBCo: ' + convert(varchar(3),i.JBCo) +
	'Template: ' + i.Template +
	'Seq: ' + convert(varchar(10),i.Seq) + 'AddonSeq: ' + convert(varchar(10),i.AddonSeq),
	i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME()
From inserted i
Join bJBCO c on c.JBCo = i.JBCo
Where c.AuditTemplate = 'Y'
   
return

error:
select @errmsg = @errmsg + ' - cannot insert into JBTA!'

RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  TRIGGER [dbo].[btJBTAu] ON [dbo].[bJBTA] FOR UPDATE AS

/**************************************************************
*
*  Created by: bc 10/24/00
*  Modified by: ALLENN 11/28/2001 Issue #13667
*		kb 7/22/2 - issue #18040 allow insert if copying template
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		DANF 09/14/2004 - Issue 19246 added new login
**************************************************************/
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
	@co bCompany, @template varchar(10), @copy bYN
   
select @numrows = @@rowcount

if @numrows = 0 return
set nocount on
   
/*Issue 13667*/
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
   
select @co = min(JBCo)
from inserted
while @co is not null
	begin
	select @template = min(Template)
	from inserted
	where JBCo = @co
	while @template is not null
		begin
		select @copy = CopyInProgress 
		from bJBTM 
		where JBCo = @co and Template = @template 

		if @template in ('STD ACTDT','STD CONT','STD PHASE','STD SEQ') 
			and SUSER_SNAME() <> 'bidtek' and SUSER_SNAME() <> 'viewpointcs' and @copy = 'N'
			begin
			select @errmsg = 'Cannot edit standard templates'
			goto error
			end

		select @template = min(Template)
		from inserted
		where JBCo = @co and Template > @template
		if @@rowcount = 0 select @template = null
		end

	select @co = min(JBCo) 
	from inserted 
	where JBCo > @co
	if @@rowcount = 0 select @co = null
	end
   
/*Issue 13667*/
If exists(select * from inserted i join bJBCO c on i.JBCo = c.JBCo where (c.AuditCo = 'Y' and c.AuditTemplate = 'Y') )
	BEGIN
	If Update(AddonSeq)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBTA', 'JBCo: ' + convert(varchar(3),i.JBCo)
			+ 'Template: ' + i.Template
			+ 'Seq: ' + convert(varchar(10),i.Seq) + 'AddonSeq: ' + convert(varchar(10),i.AddonSeq)
			,i.JBCo, 'C', 'AddonSeq', convert(varchar(10), d.AddonSeq), convert(varchar(10), i.AddonSeq), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.AddonSeq <> i.AddonSeq and c.AuditTemplate = 'Y'
		End
	END
   
return

error:
select @errmsg = @errmsg + ' - cannot update JBTA!'

RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
   
   
  
 




GO
