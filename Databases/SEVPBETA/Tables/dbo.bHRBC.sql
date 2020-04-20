CREATE TABLE [dbo].[bHRBC]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[BenefitCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[PlanName] [dbo].[bDesc] NULL,
[PlanNumber] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ReportInfo] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Contact] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Phone] [dbo].[bPhone] NULL,
[Fax] [dbo].[bPhone] NULL,
[Email] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[EligBasis] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[EligPeriod] [int] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UpdatePRYN] [dbo].[bYN] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE      trigger [dbo].[btHRBCd] on [dbo].[bHRBC] for Delete
    as
    

/**************************************************************
    * Created by: mh 1/10/03
    * Last Modified: mh 3/15/04 23061
    *
    * Purpose:  
    **************************************************************/
   
   
   	declare @hrco bCompany, @bencode varchar(10), @opencurs tinyint, @errmsg varchar(255), @numrows int
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	select @opencurs = 0
   
   	declare cursDel cursor local fast_forward for
   	select HRCo, BenefitCode from deleted with (nolock)
   
   	open cursDel
   
   	select @opencurs = 1
   
   	fetch next from cursDel into @hrco, @bencode
   
   	while @@fetch_status = 0
   	begin
   		if exists(select 1 from bHRBI with (nolock) where HRCo = @hrco and BenefitCode = @bencode)
   		begin
   			select @errmsg = 'Benefit code ' + isnull(@bencode,'') + ' exists in HRBI'  
   			goto error
   		end
   
   		if exists(select 1 from bHREB with (nolock) where HRCo = @hrco and BenefitCode = @bencode)
   		begin
   			select @errmsg = 'Benefit code ' + isnull(@bencode,'') + ' exists in HREB'
   			goto error
   		end
   
   		if exists(select 1 from bHRGI with (nolock) where HRCo = @hrco and BenefitCode = @bencode)
   		begin
   			select @errmsg = 'Benefit code ' + isnull(@bencode,'') + ' exists in HRGI'
   			goto error
   		end
   
   		if exists(select 1 from bHRBB with (nolock) where Co = @hrco and BenefitCode = @bencode)
   		begin	
   			select @errmsg = 'Benefit Code ' + isnull(@bencode,'') + ' exists in HRGI'
   			goto error
   		end
   
   	
   		fetch next from cursDel into @hrco, @bencode
   	end 
   
   	close cursDel
   	deallocate cursDel
   
    Return
    error:
   
   	if @opencurs = 1
   	begin
   		close cursDel
   		deallocate cursDel
   	end
   
   	select @errmsg = (@errmsg + ' - cannot delete HRBC! ')
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRBC] ON [dbo].[bHRBC] ([HRCo], [BenefitCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRBC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRBC].[UpdatePRYN]'
GO
