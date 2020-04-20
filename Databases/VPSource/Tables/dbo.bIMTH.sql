CREATE TABLE [dbo].[bIMTH]
(
[ImportTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[UploadRoutine] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BidtekRoutine] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[MultipleTable] [dbo].[bYN] NOT NULL,
[FileType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[Delimiter] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[OtherDelim] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[TextQualifier] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[LastImport] [dbo].[bDate] NULL,
[SampleFile] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[RecordTypeCol] [int] NULL,
[BegPos] [int] NULL,
[EndPos] [int] NULL,
[ImportRoutine] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[UserRoutine] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[DirectType] [tinyint] NULL,
[XMLRowTag] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bIMTH] ADD
CONSTRAINT [CK_bIMTH_MultipleTable] CHECK (([MultipleTable]='Y' OR [MultipleTable]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

   CREATE     trigger [dbo].[btIMTHd] ON [dbo].[bIMTH] for DELETE as
    

declare @errmsg varchar(255), @validcnt int
   
    /*-----------------------------------------------------------------
     *	This trigger deletes all associated detail and record types on delete of template
     *
     * Created By: GR 9/15/99
     *
     * Modified By: MH 10/24/01.  Implemented purge program (IMPurge).
     * 							No longer do cascading deletes.
     *				mh 5/19/03.  Changed Select * to Select t.ImportTemplate.
     *
     *----------------------------------------------------------------*/
   
    declare  @errno   int, @numrows int
    SELECT @numrows = @@rowcount
    IF @numrows = 0 return
    set nocount on
    begin
   
    /*----------------------------------------------------------*/
    /* Delete Template Detail, Record Type and from Work Tables */
    /*----------------------------------------------------------*/
   -- delete bIMTR from bIMTR, deleted d where bIMTR.ImportTemplate=d.ImportTemplate
   -- delete bIMTD from bIMTD, deleted d where bIMTD.ImportTemplate=d.ImportTemplate
   -- delete bIMWH from bIMWH, deleted d where bIMWH.ImportTemplate=d.ImportTemplate
   -- delete bIMWE from bIMWE, deleted d where bIMWE.ImportTemplate=d.ImportTemplate
   -- delete bIMXD from bIMXD, deleted d where bIMXD.ImportTemplate=d.ImportTemplate
   -- delete bIMXH from bIMXH, deleted d where bIMXH.ImportTemplate=d.ImportTemplate
   
   	if exists(select t.ImportTemplate from bIMTD t, deleted d where t.ImportTemplate = d.ImportTemplate)
   	begin
   		select @errmsg = 'Entries exist in IMTD.' 
   		goto error
   	end
   
   	if exists(select t.ImportTemplate from bIMTA t, deleted d where t.ImportTemplate = d.ImportTemplate)
   	begin
   		select @errmsg = 'Entries exist in IMTA.'
   		goto error
   	end
   
   	if exists(select t.ImportTemplate from bIMTH t, deleted d where t.ImportTemplate = d.ImportTemplate)
   	begin
   		select @errmsg = 'Entries exist in IMTH.'
   		goto error
   	end
   
   	if exists(select t.ImportTemplate from bIMTR t, deleted d where t.ImportTemplate = d.ImportTemplate)
   	begin
   		select @errmsg = 'Entries exist in IMTR.'
   		goto error
   	end
   
   	if exists(select t.ImportTemplate from bIMWE t, deleted d where t.ImportTemplate = d.ImportTemplate)
   	begin
   		select @errmsg = 'Entries exist in IMWE.'
   		goto error
   	end
   
   	if exists(select t.ImportTemplate from bIMWH t, deleted d where t.ImportTemplate = d.ImportTemplate)
   	begin
   		select @errmsg = 'Entries exist in IMWH.'
   		goto error
   	end
   
   	if exists(select t.ImportTemplate from bIMWM t, deleted d where t.ImportTemplate = d.ImportTemplate)
   	begin
   		select @errmsg = 'Entries exist in IMWM.'
   		goto error
   	end
   
   	if exists(select t.ImportTemplate from bIMXD t, deleted d where t.ImportTemplate = d.ImportTemplate)
   	begin	
   		select @errmsg = 'Entries exist in IMXD.'
   		goto error
   	end
   
   	if exists(select t.ImportTemplate from bIMXF t, deleted d where t.ImportTemplate = d.ImportTemplate)
   	begin
   		select @errmsg = 'Entries exist in IMXF.'
   		goto error
   	end
   
   	if exists(select t.ImportTemplate from bIMXH t, deleted d where t.ImportTemplate = d.ImportTemplate)
   	begin
   		select @errmsg = 'Entries exist in IMXH.'
   		goto error
   	end
   
   
    return
    error:
        SELECT @errmsg = @errmsg + ' - cannot delete Template!  Use IMPurge Program'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
    end
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btIMTHi] on [dbo].[bIMTH] for INSERT as
    

/*-----------------------------------------------------------------
     * Created by: GR 9/13/99
     * Modified by: RT 11/11/03 Issue #22751, provide value for Skip column.
     *
     *	This trigger rejects insertion into bIMTH (IM Template Header)
     * IM Record Types if any error exists:
     *
     *	Adds to IM Record Types
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @formdesc bDesc, @desttable varchar(30), @recordtype int,
            @filetype varchar(1), @begpos int, @endpos int
   
    select @numrows = @@rowcount
   
    if @numrows = 0 return
   
    set nocount on
   
    --validate Import Form
    select @validcnt = count(*) from bDDUF c, inserted i where c.Form = i.Form
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Import Form'
    	goto error
    	end
   
   -- get description and destination table for this import
   select @formdesc=b.Description, @desttable = DestTable
   from inserted i, bDDUF b where i.Form=b.Form
   
    --add Record Type if record type is not specified in inserted (record type is pulled from DDUF which is default)
    select @filetype=FileType from inserted
    if @filetype = 'D'
    begin
       select @recordtype=RecordTypeCol from inserted
       if @recordtype is NULL
           begin
               insert into bIMTR (ImportTemplate, RecordType, Form, Description, Skip)
    	        select i.ImportTemplate, @desttable, i.Form, @formdesc, 'N' from inserted i
           end
   end
   else    -- @filetype is 'F'
       begin
           select @begpos=BegPos, @endpos=EndPos from inserted
           if @begpos is null or @endpos is null
               begin
                   insert into bIMTR (ImportTemplate, RecordType, Form, Description, Skip)
    	            select i.ImportTemplate, @desttable, i.Form, @formdesc, 'N' from inserted i
               end
       end
   
    return
    error:
    	select @errmsg = @errmsg + ' - cannot insert IM Template Header!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biIMTH] ON [dbo].[bIMTH] ([ImportTemplate], [Form]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bIMTH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bIMTH].[MultipleTable]'
GO
