CREATE TABLE [dbo].[bHRTC]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[TrainCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ClassSeq] [int] NOT NULL,
[ClassDesc] [dbo].[bDesc] NULL,
[Instructor] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Institution] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Contact] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Phone] [dbo].[bPhone] NULL,
[EMail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Room] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Hours] [dbo].[bHrs] NULL,
[Status] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CEUCredits] [numeric] (4, 2) NULL,
[Cost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bHRTC_Cost] DEFAULT ((0.00)),
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[StartDate] [dbo].[bDate] NULL,
[ClassTime] [smalldatetime] NULL,
[EndDate] [dbo].[bDate] NULL,
[TimeDesc] [dbo].[bDesc] NULL,
[MaxAttend] [int] NULL,
[Instructor1099YN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRTC_Instructor1099YN] DEFAULT ('N'),
[OSHAYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRTC_OSHAYN] DEFAULT ('N'),
[MSHAYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRTC_MSHAYN] DEFAULT ('N'),
[FirstAidYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRTC_FirstAidYN] DEFAULT ('N'),
[CPRYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRTC_CPRYN] DEFAULT ('N'),
[ReimbursedYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRTC_ReimbursedYN] DEFAULT ('N'),
[WorkRelatedYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRTC_WorkRelatedYN] DEFAULT ('N'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[btHRTCd] ON [dbo].[bHRTC] FOR DELETE AS 
   
    

/**************************************************************
    * Created: 02/25/04 mh
    * Last Modified:
    *
    *	When deleted a Training Class from HRTC need to look for
    *  dependent records in HRTS (training skills) and HRET (resource training)
    *
    **************************************************************/
   
   
   	declare @errmsg varchar(255), @numrows int, @rcode int,
   	@hrco bCompany, @traincode varchar(10), @classseq int,
   	@opencurs tinyint
   
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	select @opencurs = 0
   
   	declare delcurs Cursor local fast_forward for
   
   	select HRCo, TrainCode, ClassSeq from deleted with (nolock)
   
   	open delcurs
   
   	select @opencurs = 1
   
   	fetch next from delcurs into @hrco, @traincode, @classseq
   
   	while @@fetch_status = 0
   	begin
   		if exists (Select 1 from dbo.bHRTS with (nolock) where HRCo = @hrco and
   			TrainCode = @traincode and Type = 'S' and ClassSeq = @classseq)
   		begin
   			select @errmsg = 'Related Training Skills entries exist in HRTS. '
   			goto error
   		end
   
   		if exists (select 1 from dbo.bHRET with (nolock) where HRCo = @hrco and
   			TrainCode = @traincode and Type = 'T' and ClassSeq = @classseq)
   		begin
   			select @errmsg = 'Training Code Class Sequence is assigned in HR Resource Training. '
   			goto error
   		end
   
   		fetch next from delcurs into @hrco, @traincode, @classseq
   	end
   
   	if @opencurs = 1
   	begin
   		close delcurs
   		deallocate delcurs
   	end
   
   	return
   
   error:
   
   	if @opencurs = 1
   	begin
   		close delcurs
   		deallocate delcurs
   	end
   
   	select @errmsg = @errmsg + ' - cannot delete from HRTC'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [biHRTC] ON [dbo].[bHRTC] ([HRCo], [TrainCode], [Type], [ClassSeq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRTC] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRTC].[Instructor1099YN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRTC].[OSHAYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRTC].[MSHAYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRTC].[FirstAidYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRTC].[CPRYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRTC].[ReimbursedYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRTC].[WorkRelatedYN]'
GO
