CREATE TABLE [dbo].[bIMXF]
(
[ImportTemplate] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[XRefName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ImportField] [int] NOT NULL,
[RecordType] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   --drop trigger btIMXFi
   CREATE trigger [dbo].[btIMXFi] on [dbo].[bIMXF] for INSERT as
   

/*-----------------------------------------------------------------
    *    Created by:  MH 04/07/2000
    *    Modified by:
    *
    *    Verifys Inserted XRefName exists in IMXH - Reject insertion if not.
    *    Verifys XRef Field exists in IMTD - Reject insertion if not.
    *        otherwise insure Required flag in IMTD is set to true.
    *
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
   
   select @numrows = @@rowcount
   
   --print '@numrows'
   --print @numrows
   
   if @numrows = 0 return
   set nocount on
   
   -- validate ImportTemplate
   
   select @validcnt = count(*) from bIMTD a, inserted i where a.ImportTemplate = i.ImportTemplate
   if @validcnt = 0
   	begin
   	select @errmsg = 'Invalid ImportTemplate, not in IMTD!'
   	goto error
   	end
   
   -- validate XRefName
   /*select @validcnt = count(*) from bIMXH b, inserted i where b.XRefName = i.XRefName and b.ImportTemplate = i.ImportTemplate
   
   --select @validcnt
   
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid XRefName, not in IMXH!'
   	goto error
   	end*/
   
   --validate Identifier/ImportField
   --mark
   
   /*print '@validcnt query'
   select * from bIMTD c, inserted i where c.Identifier = i.ImportField and c.ImportTemplate = i.ImportTemplate 
   
   
   select count(*) 
   from bIMTD c, inserted i 
   where c.Identifier = i.ImportField and c.ImportTemplate = i.ImportTemplate */
   
   
   
   --select @validcnt = count(*) 
   --from bIMTD c, inserted i 
   --where c.Identifier = i.ImportField and c.ImportTemplate = i.ImportTemplate 
   
   
   
   --select @validcnt 'Validate Identifier/ImportField'
   --select @numrows 'Number of rows'
   
   /*if @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid ImportField.  Check for existance in IMTD or previous existance in this XRef.'
           goto error
           end*/
   
   update bIMTD 
   set Required = 1 
   from bIMTD d, inserted i
   where d.ImportTemplate = i.ImportTemplate and d.Identifier = i.ImportField
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert XRef Field!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biIMXF] ON [dbo].[bIMXF] ([ImportTemplate], [XRefName], [ImportField], [RecordType]) ON [PRIMARY]
GO
