CREATE TABLE [dbo].[bIMXH]
(
[ImportTemplate] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[XRefName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[RecordType] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Identifier] [int] NOT NULL CONSTRAINT [DF_bIMXH_Identifier] DEFAULT ('0'),
[UniqueAttchID] [uniqueidentifier] NULL,
[PMCrossReference] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bIMXH_PMCrossReference] DEFAULT ('N'),
[PMTemplate] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btIMXHd    Script Date: 5/19/2003 1:08:18 PM ******/
   
   /****** Object:  Trigger dbo.btIMXHd    Script Date: 5/19/2003 11:06:10 AM ******/
   CREATE    trigger [dbo].[btIMXHd] ON [dbo].[bIMXH] for DELETE as
   
    

declare @errmsg varchar(255), @validcnt int
    /*-----------------------------------------------------------------
     *	Description of Trigger
     *
     *  Prevents deletion of entries in bIMXH if related entries 
     *  exist in bIMXF and bIMXD
     *
     * Created By: MH 10/24/01
     *		Modified:	mh 5/19/03 included RecordType
     *----------------------------------------------------------------*/
    declare  @errno   int, @numrows int
   
    SELECT @numrows = @@rowcount
    IF @numrows = 0 return
    set nocount on
   
    begin
   
   
   	if exists(select bIMXF.ImportTemplate from bIMXF, deleted d where bIMXF.XRefName = d.XRefName 
   		and bIMXF.ImportTemplate = d.ImportTemplate and bIMXF.RecordType = d.RecordType)
   	begin
   		select @errmsg = 'Related entries exist in bIMXF.'
   		goto error
   	end
   
   	if exists(select bIMXD.ImportTemplate from bIMXD, deleted d where bIMXD.XRefName = d.XRefName
   		and bIMXD.ImportTemplate = d.ImportTemplate and bIMXD.RecordType = d.RecordType)
   	begin
   		select @errmsg = 'Related entries exist in bIMXD.'
   		goto error
   	end
   
   	if exists(select bIMTD.ImportTemplate from bIMTD, deleted d where bIMTD.XRefName = d.XRefName
   		and bIMTD.ImportTemplate = d.ImportTemplate and bIMTD.RecordType = d.RecordType)
   	begin
   		select @errmsg = 'Related entries exist in bIMTD.'
   		goto error
   	end
   
   
    return
    error:
        SELECT @errmsg = @errmsg + '  Remove entries or use IM Purge Program.'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
    end
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biIMXH] ON [dbo].[bIMXH] ([ImportTemplate], [XRefName], [RecordType]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bIMXH] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bIMXH].[PMCrossReference]'
GO
