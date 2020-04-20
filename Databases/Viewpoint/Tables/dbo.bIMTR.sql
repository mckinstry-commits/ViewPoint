CREATE TABLE [dbo].[bIMTR]
(
[ImportTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[RecordType] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Skip] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biIMTR] ON [dbo].[bIMTR] ([ImportTemplate], [RecordType], [Form]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bIMTR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE TRIGGER [dbo].[btIMTRd] on [dbo].[bIMTR] for DELETE as
     

/*-----------------------------------------------------------------
      * Created by: RBT 09/11/03, issue #22362
      *
      *	This trigger deletes matching records from IMTD.
      *
      *	
      */----------------------------------------------------------------
   
     declare @errmsg varchar(255), @numrows int
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
     --Delete records from IMTD that match the import template and record type
     --deleted from IMTR.
   
     DELETE bIMTD
     FROM bIMTD a JOIN deleted d on a.ImportTemplate = d.ImportTemplate 
   	and a.RecordType = d.RecordType
             
   
     return
   
     error:
     	select @errmsg = @errmsg + ' - cannot delete IMTR-matching IM Detail Records!'
     	RAISERROR(@errmsg, 11, -1);
     	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE trigger [dbo].[btIMTRi] on [dbo].[bIMTR] for INSERT as
     

/*-----------------------------------------------------------------
      * Created by: GR 9/13/99
      * Modified by: RT 11/11/03 Issue #22751 - Skip column is now bYN, not tinyint.
      *			  RT 03/29/04 Issue #24182 - Set IMTD.UpdateKeyYN column based on DDUD.UpdateKeyYN.
      *
      *	This trigger rejects insertion into bIMTR (IM Template Detail)
      * if any error exists:
      *
      *	Adds to IM Template Detail
      */----------------------------------------------------------------
     declare @errmsg varchar(255), @numrows int, @validcnt int, @formdesc bDesc, @desttable varchar(30), @recordtype int,
             @filetype varchar(1), @begpos int, @endpos int, @skip bYN, @IMTDcnt int
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
     --validate Import Form
     select @validcnt = count(*) from bDDUF c, inserted i where c.Form = i.Form
     if @validcnt <> @numrows
     	begin
     	select @errmsg = 'Invalid Form'
     	goto error
     	end
     --check whether detail info exists for this form
     select @validcnt = count(*) from bDDUD b, inserted i where b.Form = i.Form
     if @validcnt = 0
        begin
        select @errmsg = 'Import Form not set up in Form Detail'
        goto error
        end
   
     --check whether to skip inserting into IMTD based on skip flag
     select @skip=i.Skip from inserted i
   
     if @skip <> 'Y'
     begin
        --add template detail
   
       select @IMTDcnt = 0
   
        select @IMTDcnt = count(IMTD.ImportTemplate)
           from IMTD
               join inserted i on IMTD.ImportTemplate = i.ImportTemplate and IMTD.RecordType = i.RecordType
        where IMTD.ImportTemplate=i.ImportTemplate
   
       if @IMTDcnt = 0
        begin
          insert into bIMTD (ImportTemplate, RecordType, Identifier, Seq, Required, ColDesc, Datatype, DefaultValue, UpdateKeyYN)
          select i.ImportTemplate, i.RecordType, a.Identifier, a.Seq, Case a.RequiredValue WHEN 'Y' THEN -1 ELSE 0 END, a.Description, a.Datatype,
                 Case a.BidtekDefaultValue WHEN 'Y' THEN '[Bidtek]' ELSE NULL END, a.UpdateKeyYN
          from inserted i, bDDUD a
          where i.Form=a.Form
        end
     end
     return
     error:
     	select @errmsg = @errmsg + ' - cannot insert IM Record Types!'
     	RAISERROR(@errmsg, 11, -1);
     	rollback transaction
   
   
   
   
   
   
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bIMTR].[Skip]'
GO
