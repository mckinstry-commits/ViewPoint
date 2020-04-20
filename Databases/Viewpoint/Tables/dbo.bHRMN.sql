CREATE TABLE [dbo].[bHRMN]
(
[MSHAID] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[MineName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Operator] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BeginDate] [dbo].[bDate] NULL,
[Status] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[StatusDate] [dbo].[bDate] NULL,
[MinedMaterial] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MineType] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[Location] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Phone] [dbo].[bPhone] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bHRMN] ADD 
CONSTRAINT [PK_bHRMN] PRIMARY KEY CLUSTERED  ([MSHAID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
   
CREATE trigger [dbo].[btHRMNd] on [dbo].[bHRMN] for Delete
as

/**************************************************************
* 	Created:		mh 9/12/06 - Delete trigger for HRMN 
* 	Last Modified:  
*				
*
**************************************************************/

	declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int,
   	@nullcnt int, @rcode int

   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on

	--If trigger is in use in HRAT reject delete.
	if exists(select 1 from bHRAT h join deleted d on h.MSHAID = d.MSHAID)
	begin
		select @errmsg = 'MSHAID is currently in use in HR Accidents.'
		goto error
	end


   	Return
   	error:
   	select @errmsg = (@errmsg + ' - cannot delete bHRMN! ')
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
GO
