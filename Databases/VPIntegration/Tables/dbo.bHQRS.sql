CREATE TABLE [dbo].[bHQRS]
(
[JobState] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[ResidentState] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
CREATE trigger [dbo].[btHQRSi] on [dbo].[bHQRS] for INSERT as
/*-----------------------------------------------------------------
*  Created: GG 07/21/08
*  Modified: 
*
*	This trigger rejects insertion in bHQRS (Reciprocal States)
*	if any of the following error conditions exist:
*
*		Invalid Country
*		Job State or Resident State not valid for Country
*		Job and Resident State the same
*
*/----------------------------------------------------------------
    
declare @numrows int, @validcnt int, @errmsg varchar(255)
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount ON

-- validate Country
SELECT @validcnt = count(*) FROM dbo.bHQCountry c (NOLOCK)
JOIN inserted i ON i.Country = c.Country
IF @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Country'
	GOTO error
	END
	
-- validate Job State
SELECT @validcnt = count(*) FROM dbo.bHQST s (NOLOCK)
JOIN inserted i ON i.Country = s.Country AND i.JobState = s.State
IF @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Job State and Country combination'
	GOTO error
	END
	
-- validate Resident State
SELECT @validcnt = count(*) FROM dbo.bHQST s (NOLOCK)
JOIN inserted i ON i.Country = s.Country AND i.ResidentState = s.State
IF @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Resident State and Country combination'
	GOTO error
	END
	
IF EXISTS(SELECT TOP 1 1 FROM inserted WHERE JobState = ResidentState)
	BEGIN
	SELECT @errmsg = 'Job and Resident State must be different'
	GOTO error
	END


RETURN

error:  
   	select @errmsg = @errmsg + ' - cannot insert Reciprocal States!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 




GO
CREATE UNIQUE CLUSTERED INDEX [biHQRS] ON [dbo].[bHQRS] ([Country], [JobState], [ResidentState]) ON [PRIMARY]
GO
