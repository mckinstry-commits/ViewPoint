CREATE TABLE [dbo].[bPREC]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Method] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Factor] [dbo].[bRate] NOT NULL,
[SubjToAddOns] [dbo].[bYN] NOT NULL,
[CertRpt] [dbo].[bYN] NOT NULL,
[TrueEarns] [dbo].[bYN] NOT NULL,
[OTCalcs] [dbo].[bYN] NOT NULL,
[EarnType] [dbo].[bEarnType] NOT NULL,
[JCCostType] [dbo].[bJCCType] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[StandardLimit] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPREC_StandardLimit] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[SubjToAutoEarns] [dbo].[bYN] NOT NULL,
[LimitType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[AutoAP] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPREC_AutoAP] DEFAULT ('N'),
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[TransByEmployee] [dbo].[bYN] NULL,
[PayType] [tinyint] NULL,
[Frequency] [dbo].[bFreq] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[IncldLiabDist] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPREC_IncldLiabDist] DEFAULT ('Y'),
[IncldSalaryDist] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPREC_IncldSalaryDist] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Routine] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[IncldRemoteTC] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPREC_IncldRemoteTC] DEFAULT ('N'),
[ATOCategory] [varchar] (4) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPRECd    Script Date: 8/28/99 9:38:12 AM ******/
CREATE trigger [dbo].[btPRECd] on [dbo].[bPREC] for DELETE as
/*-----------------------------------------------------------------
* Created by: EN 01/03/2001
* Modified:	  EN 02/12/2003 - #23061  added isnull check, with (nolock), and dbo
*			  EN 09/07/2005 - #26938  handle validation for Misc lines 3 & 4
*			  EN 09/05/2007 - #119856 add code for HQMA audit
*			 CHS 10/15/2010 - #140541 changed EarnCode to EDLCode
*		  Dan So 07/24/2012 - D-02774 commented out references to PRWM
*			  KK 11/14/2012 - B-11191 handle validation Method type L-Allowance
*/----------------------------------------------------------------
DECLARE @errmsg varchar(255), 
		@numrows int,
		@prco integer, 
		@employee integer
SELECT @numrows = @@ROWCOUNT
IF @numrows = 0 RETURN
   
     if exists(select * from dbo.bPRCO e with (nolock) join deleted d on e.PRCo=d.PRCo and e.OTEarnCode=d.EarnCode)
     	begin
     	select @errmsg='Company exists using this Earnings code at overtime earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPROT e with (nolock) join deleted d on e.PRCo=d.PRCo and e.MonEarnCode=d.EarnCode)
     	begin
     	select @errmsg='Overtime schedule(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPROT e with (nolock) join deleted d on e.PRCo=d.PRCo and e.TuesEarnCode=d.EarnCode)
     	begin
     	select @errmsg='Overtime schedule(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPROT e with (nolock) join deleted d on e.PRCo=d.PRCo and e.WedEarnCode=d.EarnCode)
     	begin
     	select @errmsg='Overtime schedule(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPROT e with (nolock) join deleted d on e.PRCo=d.PRCo and e.ThursEarnCode=d.EarnCode)
     	begin
     	select @errmsg='Overtime schedule(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPROT e with (nolock) join deleted d on e.PRCo=d.PRCo and e.FriEarnCode=d.EarnCode)
     	begin
     	select @errmsg='Overtime schedule(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPROT e with (nolock) join deleted d on e.PRCo=d.PRCo and e.SatEarnCode=d.EarnCode)
     	begin
     	select @errmsg='Overtime schedule(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPROT e with (nolock) join deleted d on e.PRCo=d.PRCo and e.SunEarnCode=d.EarnCode)
     	begin
     	select @errmsg='Overtime schedule(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPROT e with (nolock) join deleted d on e.PRCo=d.PRCo and e.HolEarnCode=d.EarnCode)
     	begin
     	select @errmsg='Overtime schedule(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRGI e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDCode=d.EarnCode where e.EDType='E')
     	begin
     	select @errmsg='Garnishment group(s) exist for this Earnings code'
     	goto error
     	end
     --#140541 chs 10/15/2010
     if exists(select * from dbo.bPRDB e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.EarnCode)
     	begin
     	select @errmsg='Dedn/liab basis exists for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPREH e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EarnCode=d.EarnCode)
     	begin
     	select @errmsg='Employee Header(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPREA e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.EarnCode where e.EDLType='E')
     	begin
     	select @errmsg='Employee accumulation(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRAE e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EarnCode=d.EarnCode)
     	begin
     	select @errmsg='Auto earning(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRCA e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.EarnCode where e.EDLType='E')
     	begin
     	select @errmsg='Craft accumulation(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRCI e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.EarnCode where e.EDLType='E')
     	begin
     	select @errmsg='Craft item(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRCF e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EarnCode=d.EarnCode)
     	begin
     	select @errmsg='Class addon(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRCE e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EarnCode=d.EarnCode)
     	begin
     	select @errmsg='Class earning(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRTF e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EarnCode=d.EarnCode)
     	begin
     	select @errmsg='Template addon(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRTE e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EarnCode=d.EarnCode)
     	begin
     	select @errmsg='Template earnings(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRCS e with (nolock) join deleted d on e.PRCo=d.PRCo and e.ELCode=d.EarnCode where e.ELType='E')
     	begin
     	select @errmsg='Craft capped sequence(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRCB e with (nolock) join deleted d on e.PRCo=d.PRCo and e.ELCode=d.EarnCode where e.ELType='E')
     	begin
     	select @errmsg='Craft capped basis exists for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRTI e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.EarnCode where e.EDLType='E')
     	begin
     	select @errmsg='Template item(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRTB e with (nolock) join deleted d on e.Co=d.PRCo and e.EarnCode=d.EarnCode)
     	begin
     	select @errmsg='Timecard batch item(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRTH e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EarnCode=d.EarnCode)
     	begin
     	select @errmsg='Timecard Header(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRTA e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EarnCode=d.EarnCode)
     	begin
     	select @errmsg='Timecard addon(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRCX e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.EarnCode where e.EDLType='E')
     	begin
     	select @errmsg='Craft accumulation rate detail(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRDT e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.EarnCode where e.EDLType='E')
     	begin
     	select @errmsg='Payment sequence total(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRAU e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EarnCode=d.EarnCode)
     	begin
     	select @errmsg='Accrual usage basis exists for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRLB e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EarnCode=d.EarnCode)
     	begin
     	select @errmsg='Employee leave basis exists for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRWH e with (nolock) join deleted d on e.PRCo=d.PRCo and e.Misc1EDLCode=d.EarnCode where e.Misc1EDLType='E')
     	begin
     	select @errmsg='W2 Header(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRWH e with (nolock) join deleted d on e.PRCo=d.PRCo and e.Misc2EDLCode=d.EarnCode where e.Misc2EDLType='E')
     	begin
     	select @errmsg='W2 Header(s) exist for this Earnings code'
     	goto error
     	end
     --#26938
     if exists(select * from dbo.bPRWH e with (nolock) join deleted d on e.PRCo=d.PRCo and e.Misc3EDLCode=d.EarnCode where e.Misc3EDLType='E')
     	begin
     	select @errmsg='W2 Header(s) exist for this Earnings code'
     	goto error
     	end
     --#26938
     if exists(select * from dbo.bPRWH e with (nolock) join deleted d on e.PRCo=d.PRCo and e.Misc4EDLCode=d.EarnCode where e.Misc4EDLType='E')
     	begin
     	select @errmsg='W2 Header(s) exist for this Earnings code'
     	goto error
     	end
     if exists(select * from dbo.bPRWC e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.EarnCode where e.EDLType='E')
     	begin
     	select @errmsg='W2 Report Item Code(s) exist for this Earnings code'
     	goto error
     	end
--B-11191
IF EXISTS(SELECT * FROM dbo.vPRCraftClassAllowance cc WITH(NOLOCK)
		  JOIN deleted d ON cc.PRCo = d.PRCo AND cc.EarnCode = d.EarnCode)
BEGIN
	SELECT @errmsg = 'Craft/Class Allowance Earn Code(s) exist for this Earnings code'
	GOTO error
END
IF EXISTS(SELECT * FROM dbo.vPRCraftClassTemplateAllowance cct WITH(NOLOCK)
		  JOIN deleted d ON cct.PRCo = d.PRCo AND cct.EarnCode = d.EarnCode)
BEGIN
	SELECT @errmsg = 'Craft/Class Template Allowance Earn Code(s) exist for this Earnings code'
	GOTO error
END
IF EXISTS(SELECT * FROM dbo.vPRCraftMasterAllowance cm WITH(NOLOCK)
		  JOIN deleted d ON cm.PRCo = d.PRCo AND cm.EarnCode = d.EarnCode)
BEGIN
	SELECT @errmsg = 'Craft Master Allowance Earn Code(s) exist for this Earnings code'
	GOTO error
END
IF EXISTS(SELECT * FROM dbo.vPRCraftTemplateAllowance ct WITH(NOLOCK)
		  JOIN deleted d ON ct.PRCo = d.PRCo AND ct.EarnCode = d.EarnCode)
BEGIN
	SELECT @errmsg = 'Craft Template Allowance Earn Code(s) exist for this Earnings code'
	GOTO error
END

/**** Insert delete record in HQMA ****/   
SET NOCOUNT ON
INSERT INTO dbo.bHQMA
	(TableName,KeyString,Co,RecType,FieldName,OldValue,NewValue,DateTime,UserName)
SELECT 'bPREC',
		'EarnCode:' + convert(varchar(10),d.EarnCode),
		d.PRCo, 
		'D', 
		NULL,NULL,NULL, 
		GETDATE(), 
		SUSER_SNAME()
FROM deleted d
JOIN dbo.bPRCO a WITH(NOLOCK) ON d.PRCo=a.PRCo
WHERE a.AuditDLs='Y'
RETURN

/**** Error handling ****/
error:
	SELECT @errmsg = ISNULL(@errmsg,'') + ' - cannot delete PR Earnings Code!'
    RAISERROR(@errmsg, 11, -1);
    ROLLBACK TRANSACTION
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       trigger [dbo].[btPRECi] on [dbo].[bPREC] for INSERT as
/*-----------------------------------------------------------------
*  Created: EN 9/5/07
* 	Modified:	EN 3/04/2009 #129888 include "R" (routine) as a valid method
*				LS 12/14/2010 #127269 Validate ATOCategory
*				KK 11/14/2012 B-11191 Allow for Method type L-Allowance
*
*	This trigger validates insertion in bPREC (PR Earnings)
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* validate PR Company */
select @validcnt = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
if @validcnt <> @numrows
begin
	select @errmsg = 'Invalid Company# '
	goto error
end

/*validate Method*/
select @validcnt = count(*) from inserted i where i.Method in ('A','D','F','G','H','S','V','R','L')
if @validcnt <> @numrows
begin
	select @errmsg = 'Method must be ''A'', ''D'', ''F'', ''G'', ''H'', ''S'', ''V'', ''R'', or ''L'' ' + convert(varchar(10),@validcnt)
	goto error
end
  
/* check Factor*/
select @validcnt = count(*) from inserted i where i.OTCalcs = 'Y' and i.Factor <> 1
if @validcnt > 0
begin
	select @errmsg = 'Earnings factor must be 1.00 to be used in overtime calculations '
	goto error
end

/* validate Limit Type*/
select @validcnt = count(*) from inserted i where i.LimitType = 'N' or i.LimitType = 'A'
	or i.LimitType = 'P' or i.LimitType = 'M'
if @validcnt <> @numrows
begin
	select @errmsg = 'Limit Type must be ''N'', ''A'', ''P'', or ''M'' '
	goto error
end

/*validate AP auto update required fields */
select @validcnt2 = count(*) from inserted i where i.AutoAP = 'Y'
if @validcnt2<>0
begin
	select @validcnt = count(*) from inserted i where i.AutoAP = 'Y' and i.Vendor is not null
		and i.PayType is not null and i.Frequency is not null and i.GLAcct is not null
	if @validcnt<>@validcnt2
	begin
		select @errmsg = 'Vendor, Payable Type, GL Acct, and Frequency are all required when using AP auto update '
		goto error
	end
	/*validate Vendor Group*/
	select @validcnt2 = count(*) from inserted i where i.AutoAP = 'Y' and i.VendorGroup is not null
	if @validcnt2<>0
	begin
		select @validcnt = count(*) from dbo.bHQGP p with (nolock) join inserted i on p.Grp = i.VendorGroup 
			where i.AutoAP = 'Y' and i.VendorGroup is not null
		if @validcnt <> @validcnt2
		begin
			select @errmsg = 'Vendor Group is invalid '
			goto error
		end
	end
	/*validate Vendor */
	select @validcnt2 = count(*) from inserted i where i.AutoAP = 'Y' and i.Vendor is not null
	if @validcnt2 <> 0
	begin
		select @validcnt = count(*) from dbo.bAPVM p with (nolock) join inserted i on p.VendorGroup = i.VendorGroup and
			p.Vendor = i.Vendor 
			where i.AutoAP = 'Y' and i.Vendor is not null
		if @validcnt <> @validcnt2
		begin
			select @errmsg = 'Vendor is invalid '
			goto error
		end
	end
	/*validate PayType*/
	select @validcnt2 = count(*) from inserted i where i.AutoAP = 'Y' and i.PayType is not null
	if @validcnt2 <> 0
	begin
		select @validcnt = count(*) from inserted i join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo join bAPPT p on a.APCo = p.APCo
			and i.PayType = p.PayType 
			where i.AutoAP = 'Y' and i.PayType is not null
		if @validcnt <> @validcnt2
		begin
			select @errmsg = 'Invalid Payable Type '
			goto error
		end
	end
	/*validate Frequency*/
	select @validcnt2 = count(*) from inserted i where i.AutoAP = 'Y' and i.Frequency is not null
	if @validcnt2 <> 0
	begin
		select @validcnt = count(*) from dbo.bHQFC h with (nolock) join inserted i on h.Frequency = i.Frequency 
			where i.AutoAP = 'Y' and i.Frequency is not null
		if @validcnt <> @validcnt2
		begin
			select @errmsg = 'Invalid Frequency '
			goto error
		end
	end
	/*validate GLCo*/
	select @validcnt2 = count(*) from inserted i where i.AutoAP = 'Y' and i.GLCo is not null
	if @validcnt2 <> 0
	begin
		select @validcnt = count(*) from inserted i join dbo.HQCO h with (nolock) on i.GLCo = h.HQCo
			where i.AutoAP = 'Y' and i.GLCo is not null
		if @validcnt <> @validcnt2
		begin
			select @errmsg = 'Invalid GL Company '
			goto error
		end
	end
	/*validate GLAcct*/
	select @validcnt2 = count(*) from inserted i where i.AutoAP = 'Y' and i.GLAcct is not null
	if @validcnt2 <> 0
	begin
		select @validcnt = count(*) from inserted i join dbo.GLAC g with (nolock) on i.GLCo = g.GLCo and i.GLAcct = g.GLAcct 
			where i.AutoAP = 'Y' and i.GLAcct is not null and g.SubType is null
		if @validcnt <> @validcnt2
		begin
			select @errmsg = 'Invalid GL Account '
			goto error
		end
	end
end /* END * validate AP auto update required fields */
   		
/* validate ATO Category*/
IF EXISTS (SELECT * FROM inserted i WHERE i.ATOCategory NOT IN 
(SELECT DatabaseValue FROM dbo.vDDCI WHERE ComboType = 'PRAUTaxEarnCodeCateg'))
BEGIN
	SELECT @errmsg = 'ATO Category is not one of the available choices.'
	GOTO error
END

/* add HQ Master Audit entry */
insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 select 'bPREC',  'EarnCode:' + convert(varchar(10),i.EarnCode), i.PRCo, 'A',
 null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.PRCO a with (nolock) on i.PRCo=a.PRCo
    where a.AuditDLs='Y'

return
error:
select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Earnings!'
RAISERROR(@errmsg, 11, -1);
rollback transaction
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[btPRECu] on [dbo].[bPREC] for UPDATE as
/*-----------------------------------------------------------------
* Created:  EN 09/05/2007
* Modified: mh 11/29/2007 - #126311 Corrected error message from PR Deductions Liabilities
*									to PR Earnings Code
* 			EN 03/04/2009 - #129888 include "R" (routine) as a valid method
*			LS 12/14/2010 - #127269 include ATOCategory for grouping Earnings Codes (Australia)
*			KK 11/14/2012 - B-11191 Allow for Method type L-Allowance 
*
*	This trigger validates updates to bPREC (PR Earnings)
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------
DECLARE @errmsg varchar(255), 
		@numrows int, 
		@validcnt int, 
		@validcnt2 int
SELECT  @numrows = @@rowcount
IF @numrows = 0 RETURN
    
SET NOCOUNT ON
    
/* validate PR Company */
IF UPDATE(PRCo)
BEGIN
	SELECT @errmsg = 'PR Company cannot be updated, it is a key value '
	GOTO error
END
IF UPDATE(EarnCode)
BEGIN
	SELECT @errmsg = 'EarnCode cannot be updated, it is a key value '
	GOTO error
END
    
/*validate Method*/
IF UPDATE(Method)
BEGIN
	SELECT @validcnt = count(*) 
	FROM inserted i WHERE i.Method IN ('A','D','F','G','H','S','V','R','L')
	IF @validcnt <> @numrows
	BEGIN
		SELECT @errmsg = 'Method must be ''A'', ''D'', ''F'', ''G'', ''H'', ''S'', ''V'', ''R'', or ''L'' ' + convert(varchar(10),@validcnt)
		GOTO error
	END
END

   /* check Factor*/
IF UPDATE(Factor)
BEGIN
	SELECT @validcnt = count(*) 
	FROM inserted i WHERE i.OTCalcs = 'Y' AND i.Factor <> 1
	IF @validcnt > 0
	BEGIN
		SELECT @errmsg = 'Earnings factor must be 1.00 to be used in overtime calculations '
		GOTO error
	END
END

/* validate Limit Type*/
IF UPDATE(LimitType)
BEGIN
	SELECT @validcnt = count(*) 
	FROM inserted i WHERE i.LimitType = 'N' 
					   OR i.LimitType = 'A'
					   OR i.LimitType = 'P' 
					   OR i.LimitType = 'M'
	IF @validcnt <> @numrows
	BEGIN
		SELECT @errmsg = 'Limit Type must be ''N'', ''A'', ''P'', or ''M'' '
		GOTO error
	END
END

/*validate AP auto update required fields */
SELECT @validcnt2 = count(*) 
FROM inserted i WHERE i.AutoAP = 'Y'
IF @validcnt2<>0
BEGIN
	SELECT @validcnt = count(*) 
	FROM inserted i WHERE i.AutoAP = 'Y' 
					  AND i.Vendor IS NOT NULL
					  AND i.PayType IS NOT NULL
					  AND i.Frequency IS NOT NULL
					  AND i.GLAcct IS NOT NULL
	IF @validcnt<>@validcnt2
	BEGIN
		SELECT @errmsg = 'Vendor, Payable Type, GL Acct, and Frequency are all required when using AP auto update '
		GOTO error
	END
	/*validate Vendor Group*/
	IF UPDATE(VendorGroup)
 	BEGIN
 		SELECT @validcnt2 = COUNT(*) 
 		FROM inserted i WHERE i.AutoAP = 'Y' 
 						  AND i.VendorGroup IS NOT NULL
 		IF @validcnt2<>0
 		BEGIN
 			SELECT @validcnt = COUNT(*) 
 			FROM dbo.bHQGP p WITH(NOLOCK)
 			JOIN inserted i ON p.Grp = i.VendorGroup 
			WHERE i.AutoAP = 'Y' 
			  AND i.VendorGroup IS NOT NULL
 			IF @validcnt <> @validcnt2
 			BEGIN
 				SELECT @errmsg = 'Vendor Group is invalid '
 				GOTO error
 			END
 		END
 	END
	/*validate Vendor */
	IF UPDATE(Vendor)
 	BEGIN
 		SELECT @validcnt2 = count(*) 
 		FROM inserted i WHERE i.AutoAP = 'Y' 
 						  AND i.Vendor IS NOT NULL
 		IF @validcnt2 <> 0
 		BEGIN
 			SELECT @validcnt = count(*) 
 			FROM dbo.bAPVM p WITH(NOLOCK) 
 			JOIN inserted i ON p.VendorGroup = i.VendorGroup 
 						   AND p.Vendor = i.Vendor 
			WHERE i.AutoAP = 'Y' 
			  AND i.Vendor IS NOT NULL
 			IF @validcnt <> @validcnt2
 			BEGIN
 				SELECT @errmsg = 'Vendor is invalid '
 				GOTO error
 			END
 		END
 	END
	/*validate PayType*/
	IF UPDATE(PayType)
 	BEGIN
 		SELECT @validcnt2 = count(*) 
 		FROM inserted i WHERE i.AutoAP = 'Y' 
 						  AND i.PayType IS NOT NULL
 		IF @validcnt2 <> 0
 		BEGIN
 			SELECT @validcnt = COUNT(*) 
 			FROM inserted i 
 			JOIN dbo.bPRCO a WITH(NOLOCK) ON i.PRCo = a.PRCo 
 			JOIN bAPPT p ON a.APCo = p.APCo
 						AND i.PayType = p.PayType 
			WHERE i.AutoAP = 'Y' 
			  AND i.PayType IS NOT NULL
 			IF @validcnt <> @validcnt2
 			BEGIN
 				SELECT @errmsg = 'Invalid Payable Type '
 				GOTO error
 			END
 		END
 	END
	/*validate Frequency*/
	IF UPDATE(Frequency)
 	BEGIN
 	SELECT @validcnt2 = count(*) 
 	FROM inserted i WHERE i.AutoAP = 'Y' 
 					  AND i.Frequency IS NOT NULL
 	IF @validcnt2 <> 0
 	BEGIN
 		SELECT @validcnt = count(*) 
 		FROM dbo.bHQFC h WITH(NOLOCK) 
 		JOIN inserted i ON h.Frequency = i.Frequency 
		WHERE i.AutoAP = 'Y' 
		  AND i.Frequency IS NOT NULL
 		IF @validcnt <> @validcnt2
 			BEGIN
 				SELECT @errmsg = 'Invalid Frequency '
 				GOTO error
 			END
 		END
 	END

	/*validate GLCo*/
	IF UPDATE(GLCo)
 	BEGIN
 	SELECT @validcnt = count(*) 
 	FROM inserted i 
 	JOIN dbo.HQCO h WITH(NOLOCK) ON i.GLCo = h.HQCo
 	IF @validcnt <> @numrows
 		BEGIN
 			SELECT @errmsg = 'Invalid GL Company '
 			GOTO error
 		END
 	END
	/*validate GLAcct*/
	IF UPDATE(GLAcct)
 	BEGIN
 		SELECT @validcnt = count(*) 
 		FROM inserted i 
 		JOIN dbo.GLAC g WITH(NOLOCK) ON i.GLCo = g.GLCo 
 									AND i.GLAcct = g.GLAcct 
 		WHERE g.SubType IS NULL
 		IF @validcnt <> @numrows
 		BEGIN
 			SELECT @errmsg = 'Invalid GL Account '
 			GOTO error
 		END
	END
END	

/* validate ATO Category*/
IF EXISTS (SELECT * FROM inserted i WHERE i.ATOCategory NOT IN 
(SELECT DatabaseValue FROM dbo.vDDCI WHERE ComboType = 'PRAUTaxEarnCodeCateg'))
BEGIN
	SELECT @errmsg = 'ATO Category is not one of the available choices.'
	GOTO error
END
    
    /* add HQ Master Audit entry */
    if exists (select * from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditDLs = 'Y')
    begin
     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','Description',
         		d.Description, i.Description,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.Description,'') <> isnull(d.Description,'') and a.AuditDLs = 'Y'
     
    	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','Method',
     		d.Method, i.Method, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.Method <> d.Method and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','Factor',
     		convert(varchar(30),d.Factor), convert(varchar(30),i.Factor),getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.Factor,0) <> isnull(d.Factor,0) and a.AuditDLs='Y'

     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','SubjToAddOns',
     		d.SubjToAddOns, i.SubjToAddOns,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.SubjToAddOns <> d.SubjToAddOns and a.AuditDLs='Y'
 
     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','CertRpt',
     		d.CertRpt, i.CertRpt,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.CertRpt <> d.CertRpt and a.AuditDLs='Y'
 
     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','TrueEarns',
     		d.TrueEarns, i.TrueEarns, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.TrueEarns <> d.TrueEarns and a.AuditDLs='Y'
 
     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','OTCalcs',
     		d.OTCalcs, i.OTCalcs, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.OTCalcs,'') <> isnull(d.OTCalcs,'') and a.AuditDLs='Y'
 
     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','EarnType',
     		convert(varchar(30),d.EarnType), convert(varchar(30),i.EarnType),getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.EarnType,0) <> isnull(d.EarnType,0) and a.AuditDLs='Y'

      	insert into dbo.bHQMA
    	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','JCCostType',
         		d.JCCostType, i.JCCostType,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.JCCostType,'') <> isnull(d.JCCostType,'') and a.AuditDLs = 'Y'

     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','StandardLimit',
     		convert(varchar(30),d.StandardLimit), convert(varchar(30),i.StandardLimit),getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.StandardLimit,0) <> isnull(d.StandardLimit,0) and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','SubjToAutoEarns',
     		d.SubjToAutoEarns, i.SubjToAutoEarns, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.SubjToAutoEarns <> d.SubjToAutoEarns and a.AuditDLs='Y'
 
      	insert into dbo.bHQMA
    	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','LimitType',
         		d.LimitType, i.LimitType,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.LimitType,'') <> isnull(d.LimitType,'') and a.AuditDLs = 'Y'

     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','AutoAP',
     		d.AutoAP, i.AutoAP, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.AutoAP <> d.AutoAP and a.AuditDLs='Y'

     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','VendorGroup',
     		convert(varchar(10),d.VendorGroup), convert(varchar(10),i.VendorGroup),getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.VendorGroup <> d.VendorGroup and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','Vendor',
     		convert(varchar(10),d.Vendor), convert(varchar(10),i.Vendor),getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.Vendor,0) <> isnull(d.Vendor,0) and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','TransByEmployee',
     		d.TransByEmployee, i.TransByEmployee,getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.TransByEmployee,'') <> isnull(d.TransByEmployee,'') and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','PayType',
     		convert(varchar(10),d.PayType), convert(varchar(10),i.PayType),getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.PayType,0) <> isnull(d.PayType,0) and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','Frequency',
     		d.Frequency, i.Frequency, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.Frequency,'') <> isnull(d.Frequency,'') and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','GLCo',
     		convert(varchar(10),d.GLCo), convert(varchar(10),i.GLCo),getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.GLCo,'') <> isnull(d.GLCo,'') and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','GLAcct',
     		d.GLAcct, i.GLAcct,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.GLAcct,'') <> isnull(d.GLAcct,'') and a.AuditDLs='Y'

     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','IncldLiabDist',
     		d.IncldLiabDist, i.IncldLiabDist,getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.IncldLiabDist,'') <> isnull(d.IncldLiabDist,'') and a.AuditDLs='Y'

     	insert into dbo.bHQMA
     	select 'bPREC', 'EarnCode: ' + convert(varchar(10),i.EarnCode), i.PRCo, 'C','IncldSalaryDist',
     		d.IncldSalaryDist, i.IncldSalaryDist,getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.EarnCode = d.EarnCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.IncldSalaryDist,'') <> isnull(d.IncldSalaryDist,'') and a.AuditDLs='Y'

		 INSERT INTO dbo.bHQMA
    	 SELECT 'bPREC', 'EarnCode: ' + CONVERT(VARCHAR(10),i.EarnCode), i.PRCo, 'C','ATOCategory',
         		d.ATOCategory, i.ATOCategory,	GETDATE(), SUSER_SNAME() 
          FROM inserted i
          JOIN deleted d ON i.PRCo = d.PRCo AND i.EarnCode = d.EarnCode
          JOIN dbo.bPRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
          WHERE ISNULL(i.ATOCategory,'') <> ISNULL(d.ATOCategory,'') AND a.AuditDLs = 'Y'

      END
     
     return
     error:
		select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Earnings Code!'
     	RAISERROR(@errmsg, 11, -1);
     	rollback transaction
     
     
     
    
    
    
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPREC] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPREC] ON [dbo].[bPREC] ([PRCo], [EarnCode]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREC].[SubjToAddOns]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREC].[CertRpt]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREC].[TrueEarns]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREC].[OTCalcs]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bPREC].[OTCalcs]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREC].[SubjToAutoEarns]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREC].[AutoAP]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREC].[TransByEmployee]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREC].[IncldLiabDist]'
GO
