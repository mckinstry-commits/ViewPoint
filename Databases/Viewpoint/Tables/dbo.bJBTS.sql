CREATE TABLE [dbo].[bJBTS]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[GroupNum] [int] NULL,
[Description] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[APYN] [dbo].[bYN] NOT NULL,
[EMYN] [dbo].[bYN] NOT NULL,
[INYN] [dbo].[bYN] NOT NULL,
[JCYN] [dbo].[bYN] NOT NULL,
[MSYN] [dbo].[bYN] NOT NULL,
[PRYN] [dbo].[bYN] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SummaryOpt] [tinyint] NULL,
[SortLevel] [tinyint] NULL,
[EarnLiabTypeOpt] [char] (1) COLLATE Latin1_General_BIN NULL,
[LiabilityType] [dbo].[bLiabilityType] NULL,
[EarnType] [dbo].[bEarnType] NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[MiscDistCode] [char] (10) COLLATE Latin1_General_BIN NULL,
[PriceOpt] [char] (1) COLLATE Latin1_General_BIN NULL,
[MarkupOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[MarkupRate] [numeric] (17, 6) NOT NULL,
[FlatAmtOpt] [char] (1) COLLATE Latin1_General_BIN NULL,
[AddonAmt] [dbo].[bDollar] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[ContractItem] [dbo].[bContractItem] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJBTS] ON [dbo].[bJBTS] ([JBCo], [Template], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBTS] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  TRIGGER [dbo].[btJBTSd] ON [dbo].[bJBTS]
          FOR DELETE AS
   

/**************************************************************
   *	This trigger rejects delete of bJBTS
   *	 if the following error condition exists:
   *		none
   *
   *  Created by: kb 8/28/00
   *  Modified by: ALLENN 11/16/2001 Issue #13667
   *		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   *		DANF 09/14/2004 - Issue 19246 added new login
   **************************************************************/
    declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
      @co bCompany, @template varchar(10), @templateseq int
   
      select @numrows = @@rowcount
   
      if @numrows = 0 return
      set nocount on
   
      select @co = min(JBCo) from deleted d
      while @co is not null
         begin
         select @template = min(Template) from deleted d where JBCo = @co
         while @template is not null
             begin
   
             if @template in ('STD ACTDT','STD CONT','STD PHASE','STD SEQ') and SUSER_SNAME() <> 'bidtek' and SUSER_SNAME() <> 'viewpointcs'
               begin
               select @errmsg = 'Cannot delete information relating to a standard template'
               goto error
               end
   
             select @templateseq = min(Seq) from deleted d where JBCo = @co and
               Template = @template
             while @templateseq is not null
                begin
                delete from bJBTC where JBCo = @co and Template = @template
                  and Seq = @templateseq
                delete from bJBTA where JBCo = @co and Template = @template
                  and (Seq = @templateseq or AddonSeq = @templateseq)
   
                select @templateseq = min(Seq) from deleted d where JBCo = @co and
                  Template = @template and Seq > @templateseq
                if @@rowcount = 0 select @templateseq = null
                end
   
             select @template = min(Template) from deleted d where JBCo = @co
               and Template > @template
             if @@rowcount = 0 select @template = null
             end
   
        select @co = min(JBCo) from deleted d where JBCo > @co
        if @@rowcount = 0 select @co = null
        end
   
   /*Issue 13667*/
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    Select 'bJBTS', 'JBCo: ' + convert(varchar(3),d.JBCo) + 'Template: ' + d.Template + 'Seq: ' + convert(varchar(10),d.Seq), d.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
    From deleted d 
    Join bJBCO c on c.JBCo = d.JBCo 
    Where c.AuditTemplate = 'Y'
   
      return
   
      error:
      select @errmsg = @errmsg + ' - cannot delete JBTS!'
   
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btJBTSi] ON [dbo].[bJBTS]
FOR INSERT AS
   
/**************************************************************
*	This trigger rejects update of bJBTS
*	 if the following error condition exists:
*		none
*
*  Created by: kb 8/29/00
*  Modified by: ALLENN 11/16/2001 Issue #13667
*		kb 7/22/2 - issue #18040 allow insert if copying template
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		DANF 09/14/2004 - Issue 19246 added new login
*		TJL 08/04/08 - Issue #128962, JB International Sales Tax
*
**************************************************************/
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
    @co bCompany, @seq int, @billmth bMonth, @template varchar(10), @type char(1),
    @copy bYN, @markupopt char(1)

select @numrows = @@rowcount
   
if @numrows = 0 return
set nocount on

select @co = min(JBCo) from inserted i
while @co is not null
	begin
	select @template = min(Template) 
	from inserted i where JBCo = @co
   
	while @template is not null
		begin
		select @copy = CopyInProgress from bJBTM where JBCo = @co 
   			and Template = @template
		if @template in ('STD ACTDT','STD CONT','STD PHASE','STD SEQ') 
   			and SUSER_SNAME() <> 'bidtek' and SUSER_SNAME() <> 'viewpointcs' and @copy = 'N'
			begin
			select @errmsg = 'Cannot edit standard template information'
			goto error
			end
   
		select @seq = min(Seq) from inserted i where JBCo = @co and Template = @template
			and (Type = 'D' or Type = 'T')
		while @seq is not null
			begin
			/*add JBTA records for all seq#'s above this detail or total addon seq*/
			select @type = Type, @markupopt = MarkupOpt
			from inserted i 
			where JBCo = @co and Template = @template and Seq = @seq

			if @type = 'D' and @markupopt <> 'X'
				begin
				insert bJBTA (JBCo,Template,Seq,AddonSeq)
				select @co, @template, Seq, @seq from bJBTS where JBCo = @co and
					Template = @template and Type = 'S' and Seq < @seq
				end

			if @type = 'T' and @markupopt <> 'X'
				begin
				insert bJBTA (JBCo, Template, Seq, AddonSeq)
				select @co, @template, Seq, @seq from bJBTS where JBCo = @co and
					Template = @template and Seq < @seq
				end

			select @seq = min(Seq) from inserted i where JBCo = @co and Template = @template
				and (Type = 'D' or Type = 'T') and Seq > @seq
			end
		select @template = min(Template) from inserted i where JBCo = @co and Template > @template
		end
	select @co = min(JBCo) from inserted i where JBCo > @co
	end
   
/*Issue 13667*/
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
From inserted i 
Join bJBCO c on c.JBCo = i.JBCo 
Where c.AuditTemplate = 'Y'
   
return

error:
select @errmsg = @errmsg + ' - cannot insert JBTS!'

RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  TRIGGER [dbo].[btJBTSu] ON [dbo].[bJBTS]
   FOR UPDATE AS
   

/*************************************************************************
   *	This trigger rejects update of bJBTS
   *	 if the following error condition exists:
   *		none
   *
   *  Created by: kb 5/15/00
   *  Modified by: ALLENN 11/16/2001 Issue #13667
   *		kb 7/22/2 - issue #18040 allow insert if copying template
   *		TJL 02/11/03 - Issue #20341, Update bJBTC if EarnLiabTypeOpt changes
   *		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   *		DANF 09/14/2004 - Issue 19246 added new login
   *
   ***************************************************************************/
   declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
   
   @co bCompany, @mth bMonth, @billnum int, @line int, @seq int, @billmth bMonth,
   	@template varchar(10), @copy bYN
   
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
   
   select @co = min(JBCo) from inserted i
   while @co is not null
       begin
       select @template = min(Template) 
   	from inserted i 
   	where JBCo = @co while @template is not null
       	begin
   
   		select @copy = CopyInProgress 
   		from bJBTM 
   		where JBCo = @co and Template = @template
   		
           if @template in ('STD ACTDT','STD CONT','STD PHASE','STD SEQ') 
   			and SUSER_SNAME() <> 'bidtek' and SUSER_SNAME() <> 'viewpointcs' and @copy = 'N'
             	begin
             	select @errmsg = 'Cannot edit standard template information'
             	goto error
             	end
   
           select @seq = min(Seq) 
   		from inserted i 
   		where JBCo = @co and Template = @template
           while @seq is not null
           	begin
               if update(APYN)
               	begin
                   update bJBTC 
   				set APYN = i.APYN 
   				from inserted i 
   				join bJBTC c on i.JBCo = c.JBCo and i.Template = c.Template and i.Seq = c.Seq
                   end
               if update(PRYN)
                   begin
                   update bJBTC 
   				set PRYN = i.PRYN 
   				from inserted i 
   				join bJBTC c on i.JBCo = c.JBCo and i.Template = c.Template and i.Seq = c.Seq
                   end
               if update(EMYN)
                   begin
                   update bJBTC 
   				set EMYN = i.EMYN 
   				from inserted i 
   				join bJBTC c on i.JBCo = c.JBCo and i.Template = c.Template and i.Seq = c.Seq
                   end
               if update(JCYN)
                   begin
                   update bJBTC 
   				set JCYN = i.JCYN 
   				from inserted i 
   				join bJBTC c on i.JBCo = c.JBCo and i.Template = c.Template and i.Seq = c.Seq
                   end
               if update(MSYN)
                   begin
                   update bJBTC 
   				set MSYN = i.MSYN 
   				from inserted i 
   				join bJBTC c on i.JBCo = c.JBCo and i.Template = c.Template and i.Seq = c.Seq
                   end
               if update(INYN)
                   begin
                   update bJBTC 
   				set INYN = i.INYN 
   				from inserted i 
   				join bJBTC c on i.JBCo = c.JBCo and i.Template = c.Template and i.Seq = c.Seq
                   end
               if update(Category)
                   begin
                   update bJBTC 
   				set Category = i.Category 
   				from inserted i 
   				join bJBTC c on i.JBCo = c.JBCo and i.Template = c.Template and i.Seq = c.Seq
                   end
   			if update(EarnLiabTypeOpt)
   			    begin
   			    update bJBTC 
   				set EarnLiabTypeOpt = i.EarnLiabTypeOpt
   			  	from inserted i 
   				join bJBTC c on i.JBCo = c.JBCo and i.Template = c.Template and i.Seq = c.Seq
   			    end 
               if update(LiabilityType)
                   begin
                   update bJBTC 
   				set LiabilityType = i.LiabilityType
                 	from inserted i 
   				join bJBTC c on i.JBCo = c.JBCo and i.Template = c.Template and i.Seq = c.Seq
                   end
               if update(EarnType)
                   begin
                   update bJBTC 
   				set EarnType = i.EarnType
                 	from inserted i 
   				join bJBTC c on i.JBCo = c.JBCo and i.Template = c.Template and i.Seq = c.Seq
                   end
   
               select @seq = min(Seq) 
   			from inserted i 
   			where JBCo = @co and Template = @template and Seq > @seq
               end
           select @template = min(Template) 
   		from inserted i 
   		where JBCo = @co and Template > @template
       	end
   	select @co = min(JBCo) 
   	from inserted i 
   	where JBCo > @co
   	end
   
   /*Issue 13667*/
   If exists(select * from inserted i join bJBCO c on i.JBCo = c.JBCo where c.AuditCo = 'Y' and c.AuditTemplate = 'Y')
   BEGIN
   If Update(Type) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'Type', d.Type, i.Type, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.Type <> i.Type
        and c.AuditTemplate = 'Y'
        End
   
   If Update(GroupNum) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'GroupNum', convert(varchar(10), d.GroupNum), convert(varchar(10), i.GroupNum), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.GroupNum,-2147483648) <> isnull(i.GroupNum,-2147483648)
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Description) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.Description,'') <> isnull(i.Description,'')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(APYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'APYN', d.APYN, i.APYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.APYN <> i.APYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(EMYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'EMYN', d.EMYN, i.EMYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.EMYN <> i.EMYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(INYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'INYN', d.INYN, i.INYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.INYN <> i.INYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(JCYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'JCYN', d.JCYN, i.JCYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.JCYN <> i.JCYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(MSYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'MSYN', d.MSYN, i.MSYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.MSYN <> i.MSYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(PRYN) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'PRYN', d.PRYN, i.PRYN, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.PRYN <> i.PRYN
        and c.AuditTemplate = 'Y'
        End
   
   If Update(Category) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'Category', d.Category, i.Category, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.Category,'') <> isnull(i.Category,'')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(SummaryOpt) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'SummaryOpt', convert(varchar(3), d.SummaryOpt), convert(varchar(3), i.SummaryOpt), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.SummaryOpt,0) <> isnull(i.SummaryOpt,0)
        and c.AuditTemplate = 'Y'
        End
   
   If Update(SortLevel) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'SortLevel', convert(varchar(3), d.SortLevel), convert(varchar(3), i.SortLevel), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.SortLevel,0) <> isnull(i.SortLevel,0)
        and c.AuditTemplate = 'Y'
        End
   
   If Update(EarnLiabTypeOpt) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'EarnLiabTypeOpt', d.EarnLiabTypeOpt, i.EarnLiabTypeOpt, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.EarnLiabTypeOpt,'') <> isnull(i.EarnLiabTypeOpt,'')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(LiabilityType) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'LiabilityType', convert(varchar(5), d.LiabilityType), convert(varchar(5), i.LiabilityType), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.LiabilityType,-32768) <> isnull(i.LiabilityType,-32768)
        and c.AuditTemplate = 'Y'
        End
   
   If Update(EarnType) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'EarnType', convert(varchar(5), d.EarnType), convert(varchar(5), i.EarnType), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.EarnType,-32768) <> isnull(i.EarnType,-32768)
        and c.AuditTemplate = 'Y'
        End
   
   If Update(CustGroup) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'CustGroup', convert(varchar(3), d.CustGroup), convert(varchar(3), i.CustGroup), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.CustGroup <> i.CustGroup
        and c.AuditTemplate = 'Y'
        End
   
   If Update(MiscDistCode) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'MiscDistCode', d.MiscDistCode, i.MiscDistCode, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.MiscDistCode,'') <> isnull(i.MiscDistCode,'')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(PriceOpt) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'PriceOpt', d.PriceOpt, i.PriceOpt, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.PriceOpt,'') <> isnull(i.PriceOpt,'')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(MarkupOpt) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'MarkupOpt', d.MarkupOpt, i.MarkupOpt, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.MarkupOpt <> i.MarkupOpt
        and c.AuditTemplate = 'Y'
        End
   
   If Update(MarkupRate) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'MarkupRate', convert(varchar(17), d.MarkupRate), convert(varchar(17), i.MarkupRate), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.MarkupRate <> i.MarkupRate
        and c.AuditTemplate = 'Y'
        End
   
   If Update(FlatAmtOpt) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'FlatAmtOpt', d.FlatAmtOpt, i.FlatAmtOpt, getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where isnull(d.FlatAmtOpt,'') <> isnull(i.FlatAmtOpt,'')
        and c.AuditTemplate = 'Y'
        End
   
   If Update(AddonAmt) 
        Begin 
        Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBTS', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'Template: ' + i.Template + 'Seq: ' + convert(varchar(10),i.Seq), i.JBCo, 'C', 'AddonAmt', convert(varchar(13), d.AddonAmt), convert(varchar(13), i.AddonAmt), getdate(), SUSER_SNAME() 
        From inserted i 
        Join deleted d on d.JBCo = i.JBCo and d.Template = i.Template and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo 
        Where d.AddonAmt <> i.AddonAmt
        and c.AuditTemplate = 'Y'
        End
   END
   
   return
   
   error:
   select @errmsg = @errmsg + ' - cannot update JBTS!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTS].[APYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTS].[EMYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTS].[INYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTS].[JCYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTS].[MSYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBTS].[PRYN]'
GO
