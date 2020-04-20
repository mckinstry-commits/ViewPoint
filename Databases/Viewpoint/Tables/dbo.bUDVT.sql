CREATE TABLE [dbo].[bUDVT]
(
[ValProc] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[TableName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ErrorMessage] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[DescriptionColumn] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biUDVT] ON [dbo].[bUDVT] ([ValProc], [TableName]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bUDVT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE TRIGGER [dbo].[btUDVTd] ON [dbo].[bUDVT] 
   FOR DELETE 
   AS
   
   

delete bUDVD
   from bUDVD u join deleted d 
   on u.ValProc = d.ValProc and u.TableName = d.TableName
   
  
 



GO
