CREATE TABLE [dbo].[bHRWI]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[DednCode] [dbo].[bEDLCode] NOT NULL,
[FileStatus] [char] (1) COLLATE Latin1_General_BIN NULL,
[RegExemp] [tinyint] NULL,
[AddionalExemp] [int] NULL,
[OverrideMiscAmtYN] [dbo].[bYN] NOT NULL,
[MiscAmt1] [dbo].[bDollar] NOT NULL,
[MiscFactor] [dbo].[bRate] NULL,
[AddonType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bHRWI_AddonType] DEFAULT ('N'),
[AddonRateAmt] [dbo].[bUnitCost] NULL CONSTRAINT [DF_bHRWI_AddonRateAmt] DEFAULT ((0.00)),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[MiscAmt2] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bHRWI_MiscAmt2] DEFAULT ((0.00))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		mh
-- Create date: 11/9/06
-- Description: Perform some minor validation with respect to rates and amounts.  
-- =============================================
CREATE trigger [dbo].[btHRWId] on [dbo].[bHRWI] for delete as

   declare @errmsg varchar(255), @validcnt int, @numrows int
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return

BEGIN

	SET NOCOUNT ON

	if not exists(select 1 from bHRWI h join deleted d on h.HRCo = d.HRCo and h.HRRef = d.HRRef)
	begin
		update bHRRM set W4CompleteYN = 'N'
		from bHRRM h
		join deleted d on h.HRCo = d.HRCo and h.HRRef = d.HRRef
	end

	return
   
	error:
   	select @errmsg = @errmsg + ' - cannot update HRWI!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		mh
-- Create date: 11/9/06
-- Modified:  09/27/07 - Issue 120592
--			  08/01/08 - Issue 129198
--			  10/29/2008 - Issue 127008
--			  12/14/2009 - Issue 136348 Added check to HRCO.UpdateW4YN
-- Description: Perform some minor validation with respect to rates and amounts.  Also make
--				sure the Resource and Deduction are set up.
-- =============================================
CREATE trigger [dbo].[btHRWIi] on [dbo].[bHRWI] for Insert as
 
BEGIN
	
	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount
	if @numrows = 0 return

	SET NOCOUNT ON

	if not exists(select 1 from dbo.bHRRM h join inserted i on h.HRCo = i.HRCo and h.HRRef = i.HRRef)
	begin
		select @errmsg = 'Resource does not set up in HRRM'
		goto error
	end

	if not exists(select 1 from bHRRM h join inserted i on h.HRCo = i.HRCo and h.HRRef = i.HRRef
		join bPRDL p on h.PRCo = p.PRCo and p.DLCode = i.DednCode and p.DLType = 'D')
	begin
		select @errmsg = 'Deduction code not set up in PRDL'
		goto error
	end

	if exists(select 1 from inserted i where i.OverrideMiscAmtYN = 'N' and i.MiscAmt1 <> 0)
	begin
		select @errmsg = 'Misc Amt 1 must be 0.00 when Over Misc equals is ''N'''
		goto error	
	end

	if exists(select 1 from inserted i where i.AddonType = 'N' and i.AddonRateAmt <> 0)
	begin
		select @errmsg = 'Rate/Amt must be 0.00 when Add-On is ''N'''
		goto error
	end

	--HRRef and Code exist.  Update HRRM.W4CompleteYN

	update bHRRM set W4CompleteYN = 'Y'
	from inserted i
	join bHRRM h on i.HRCo = h.HRCo and i.HRRef = h.HRRef 

	--Insert Deduction into PRED

	insert dbo.bPRED (PRCo, Employee,DLCode,EmplBased, FileStatus,RegExempts,
	AddExempts,OverMiscAmt,MiscAmt,MiscFactor, OverLimit,NetPayOpt,	AddonType, 
	OverCalcs,GLCo, AddonRateAmt, VendorGroup, MiscAmt2)
	Select m.PRCo, m.PREmp, i.DednCode, 'N', i.FileStatus, i.RegExemp, 
	i.AddionalExemp, i.OverrideMiscAmtYN, i.MiscAmt1, i.MiscFactor, 'N', 'N', 
	i.AddonType, 'N', p.GLCo, i.AddonRateAmt, l.VendorGroup, i.MiscAmt2
	from inserted i
	Join dbo.bHRRM m (nolock) on i.HRCo = m.HRCo and i.HRRef = m.HRRef
	Join dbo.bPREH p (nolock) on p.PRCo = m.PRCo and p.Employee = m.PREmp
	join dbo.bPRDL l (nolock) on p.PRCo = l.PRCo and i.DednCode = l.DLCode
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateW4YN = 'Y'
	where i.DednCode not in (
	Select DLCode from dbo.bPRED d 
	Join dbo.bHRRM h (nolock) on d.PRCo = h.PRCo and d.Employee = h.PREmp
	Join inserted i on h.HRCo = i.HRCo and i.HRRef = h.HRRef)
	
	return
   
	error:
   	select @errmsg = @errmsg + ' - cannot insert into HRWI!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
     
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		mh
-- Create date: 11/9/06
-- Modified:  09/27/07 - Issue 120592
--			  08/01/08 - Issue 129198
--			  12/14/2009 - Issue 136348 Added check to HRCO.UpdateW4YN.  Only cross updating to 
--				PRED if certain fields are updated.
-- Description: Perform some minor validation with respect to rates and amounts.  
-- =============================================
CREATE trigger [dbo].[btHRWIu] on [dbo].[bHRWI] for update as

   
declare @errmsg varchar(255), @validcnt int, @numrows int
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return

BEGIN

	SET NOCOUNT ON

	if update(HRCo)
	begin
         select @errmsg = 'Cannot change HR Company'
         goto error
    end

	if update(HRRef)
	begin
		select @errmsg = 'Cannot change HR Ref'
		goto error
	end

	if update(DednCode)
	begin
		select @errmsg = 'Cannot change Deduction Code'
		goto error
	end

	if exists(select 1 from inserted i where i.OverrideMiscAmtYN = 'N' and i.MiscAmt1 <> 0)
	begin
		select @errmsg = 'Misc Amt 1 must be 0.00 when Over Misc equals is ''N'''
		goto error	
	end

	if exists(select 1 from inserted i where i.AddonType = 'N' and i.AddonRateAmt <> 0)
	begin
		select @errmsg = 'Rate/Amt must be 0.00 when Add-On is ''N'''
		goto error
	end

	if (update(FileStatus) or update(RegExemp) or update(AddionalExemp) or 
	update(OverrideMiscAmtYN) or update(MiscAmt1) or update(MiscAmt2) or update(MiscFactor) or 
	update(AddonType) or update(AddonRateAmt))
	begin
		update dbo.bPRED set FileStatus = i.FileStatus, RegExempts = i.RegExemp,
			AddExempts = i.AddionalExemp, OverMiscAmt = i.OverrideMiscAmtYN, MiscAmt = i.MiscAmt1, MiscAmt2 = i.MiscAmt2,
			MiscFactor = i.MiscFactor, AddonType = i.AddonType, AddonRateAmt = i.AddonRateAmt, VendorGroup = l.VendorGroup
		from inserted i
		join dbo.bHRRM m (nolock) on m.HRCo = i.HRCo and m.HRRef = i.HRRef
		join dbo.bPRED d (nolock) on d.PRCo = m.PRCo and d.Employee = m.PREmp and d.DLCode = i.DednCode
		join dbo.bPRDL l (nolock) on d.PRCo = l.PRCo and i.DednCode = l.DLCode
		join dbo.bHRCO o (nolock) on o.HRCo = i.HRCo and o.UpdateW4YN = 'Y'

	end

	return
   
	error:
   	select @errmsg = @errmsg + ' - cannot update HRWI!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

END


GO
ALTER TABLE [dbo].[bHRWI] ADD CONSTRAINT [PK_bHRWI_KeyID] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHRWI] ON [dbo].[bHRWI] ([HRCo], [HRRef], [DednCode]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRWI] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRWI].[OverrideMiscAmtYN]'
GO
