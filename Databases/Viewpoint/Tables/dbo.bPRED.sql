CREATE TABLE [dbo].[bPRED]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL,
[EmplBased] [dbo].[bYN] NOT NULL,
[Frequency] [dbo].[bFreq] NULL,
[ProcessSeq] [tinyint] NULL,
[FileStatus] [char] (1) COLLATE Latin1_General_BIN NULL,
[RegExempts] [tinyint] NULL,
[AddExempts] [tinyint] NULL,
[OverMiscAmt] [dbo].[bYN] NOT NULL,
[MiscAmt] [dbo].[bDollar] NOT NULL,
[MiscFactor] [dbo].[bRate] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[APDesc] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[OverGLAcct] [dbo].[bGLAcct] NULL,
[OverCalcs] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RateAmt] [dbo].[bUnitCost] NULL,
[OverLimit] [dbo].[bYN] NOT NULL,
[Limit] [dbo].[bDollar] NULL,
[NetPayOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[MinNetPay] [dbo].[bDollar] NULL,
[AddonType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[AddonRateAmt] [dbo].[bUnitCost] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[CSCaseId] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CSFipsCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CSMedCov] [dbo].[bYN] NULL CONSTRAINT [DF_bPRED_CSMedCov] DEFAULT ('N'),
[EICStatus] [char] (1) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[LimitRate] [dbo].[bRate] NULL,
[CSAllocYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRED_CSAllocYN] DEFAULT ('N'),
[CSAllocGroup] [tinyint] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[MiscAmt2] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRED_MiscAmt2] DEFAULT ((0.00)),
[MembershipNumber] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[LifeToDateArrears] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRED_LifeToDateArrears] DEFAULT ((0.00)),
[LifeToDatePayback] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRED_LifeToDatePayback] DEFAULT ((0.00)),
[EligibleForArrearsCalc] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRED_EligibleForArrearsCalc] DEFAULT ('N'),
[OverrideStdArrearsThreshold] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRED_OverrideStdArrearsThreshold] DEFAULT ('N'),
[RptArrearsThresholdOverride] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPRED_RptArrearsThresholdOverride] DEFAULT ('F'),
[ThresholdFactorOverride] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bPRED_ThresholdFactorOverride] DEFAULT ((0.000000)),
[ThresholdAmountOverride] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRED_ThresholdAmountOverride] DEFAULT ((0.00)),
[OverrideStdPaybackSettings] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRED_OverrideStdPaybackSettings] DEFAULT ('N'),
[PaybackPerPayPeriodOverride] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPRED_PaybackPerPayPeriodOverride] DEFAULT ('F'),
[PaybackFactorOverride] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bPRED_PaybackFactorOverride] DEFAULT ((0.000000)),
[PaybackAmountOverride] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRED_PaybackAmountOverride] DEFAULT ((0.00)),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRED] ON [dbo].[bPRED] ([PRCo], [Employee], [DLCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRED] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPREDd    Script Date: 8/28/99 9:38:11 AM ******/
   CREATE   trigger [dbo].[btPREDd] on [dbo].[bPRED] for DELETE as
   

/*-----------------------------------------------------------------
    *	Created by: kb 12/21/98
    *	Modified by:	EN 10/9/02 - issue 18877 change double quotes to single
    *					EN 02/12/03 - issue 23061  added isnull check, with (nolock), and dbo
    *					MV 09/27/12 - B-10990 Arrears/Payback
    *
    */----------------------------------------------------------------
    
   DECLARE @errmsg varchar(255), @numrows int
   SELECT @numrows = @@rowcount
   IF @numrows = 0 RETURN
   
   SET NOCOUNT ON
   
	--B-10990 
	IF EXISTS  -- check for existence of Arrears/Payback history.
			(
				SELECT * 
				FROM dbo.vPRArrears a
				JOIN deleted d ON a.PRCo=d.PRCo AND a.Employee=d.Employee AND a.DLCode=d.DLCode 
			)
	BEGIN
		SELECT @errmsg = 'History exists for this d/l in PR Arrears/Payback History.'
		GOTO error	
	END
	ELSE
	BEGIN
		IF EXISTS		-- either Life To Date balance must bo 0 or
				(
					SELECT * 
					FROM deleted
					WHERE LifeToDateArrears - LifeToDatePayback <> 0 
				)
		BEGIN
			IF EXISTS	-- payback override must be zero
					(
						SELECT * 
						FROM deleted
						WHERE PaybackFactorOverride <> 0 AND PaybackAmountOverride <> 0
					)
			BEGIN
				SELECT @errmsg = 'An Arrears/Payback Life-To-Date balance exists or Payback Override is not set to 0.'
				GOTO error	
			END
		END
	END
      
   INSERT INTO dbo.bHQMA
					(
						TableName,
						KeyString,
						Co,
						RecType,
						FieldName,
						OldValue,
						NewValue,
						DateTime,
						UserName
					)
   SELECT	'bPRED',
			'PR Co#: ' + convert(char(3),d.PRCo) + ' Empl#: ' + convert(varchar(10),d.Employee) + ' DLCode: ' + convert(varchar(10),d.DLCode),
			d.PRCo,
			'D',
			NULL,
			NULL,
			NULL,
			GETDATE(),
			SUSER_SNAME()
   FROM deleted d
   JOIN dbo.bPRCO with (nolock) ON d.PRCo=bPRCO.PRCo
   WHERE dbo.bPRCO.AuditEmployees='Y'
   
   RETURN
   error:
   SELECT @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Employee Deductions/Liabilities!'
   RAISERROR(@errmsg, 11, -1);
   ROLLBACK TRANSACTION
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
 
 
 
 
 
 /****** Object:  Trigger dbo.btPREDi    Script Date: 8/28/99 9:38:11 AM ******/
  CREATE      trigger [dbo].[btPREDi] on [dbo].[bPRED] for INSERT as
  /*-----------------------------------------------------------------
   *   	Created by: kb 12/21/98
   * 	Modified by: ae 2/28/00
   *                  EN 3/31/00 - validate override GL Account, OverCalcs, NetPayOpt, and Addon Type
   *                  EN 4/11/00 - validate GLCo and Vendor Group
   *                  EN 4/11/00 - added the following validations to match checks being done in update trigger:
   *                                 check for null AP Description if Dedn/Liab Code is not set up for Auto updates to AP
   *                                 check for Rate/Amount of zero when Calculation Override Option is set to 'N'
   *                                 check for Limit of zero if the Override Limit flag is set to 'N'
   *                                 check for Minimum Net Pay of zero if the Net Pay Option is set to 'N'
   *                                 check for Addon Rate/Amount of zero if the Addon Type is set to 'N'
   *                  EN 10/03/00 - Null MiscAmt is not allowed (issue 10318)
   *					 EN 1/9/02 - issue 15822 - validate EICStatus
   *		     MV 1/28/02 - issue 15711 validate calccategory
   *					EN 10/9/02 - issue 18877 change double quotes to single
   *					EN 02/12/03 - issue 23061  added isnull check, with (nolock), and dbo
   *					EN 3/03/04 - issue 18862  added validation for CSAllocGroup
   *				mh 1/23/07 - issue 123435 - reject insert is MiscFactor is not null and Method is not "R-Routine"
   *				mh 7/23/07 - issue 123579 - cross update employee deductions to HRWI
   *				mh 9/26/07 - issue 123592 - Prevent insert when ProcessSeq is not null and EmplBased = 'N'
   *				EN 12/12/07 - issue 126457 - swapped location of @dlcode and @filestatus in fetchnext stmt to resolve error
   *				EN 1/7/2009 #130784  fixed Vendor validation
   *				EN 10/14/2009 #133605 verify that only dedns are copied to HRWI, not liabs such as AUS superannuation liab
   *
   *	This trigger rejects insertion in bPRED (PR Employee DL's)
   *	if the following error condition exists:
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
 
  /* validate Employee */
  select @validcnt = count(*) from dbo.bPREH c with (nolock) join inserted i on c.PRCo = i.PRCo
  	and c.Employee=i.Employee
  if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Employee # '
  	goto error
  	end
 
  select @validcnt = count(*) from inserted i join dbo.PRDL a with (nolock) on a.PRCo=i.PRCo and i.DLCode=a.DLCode
  if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Deduction/Liability Code '
  	goto error
  	end
 
  select @validcnt = count(*) from inserted i where i.EmplBased = 'N' and i.Frequency is not null
  if @validcnt > 0
  	begin
  	select @errmsg = 'Frequency code must be null if Employee Based Flag is ''N''. '
  	goto error
  	end
 
  select @validcnt = count(*) from inserted i where i.Frequency is null
  select @validcnt2 = count(*) from inserted i join dbo.HQFC f with (nolock) on i.Frequency = f.Frequency where
  	i.Frequency is not null
  if @validcnt + @validcnt2 <> @numrows
  	begin
  	select @errmsg = 'Frequency code is invalid. '
  	goto error
  	end

	--Issue 123592 mh 9/28/07
   select @validcnt = count(*) from inserted i
   	where i.ProcessSeq is not null and i.EmplBased = 'N'
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Processing Sequence can only be set for Employee Based D/L '
   	goto error
   	end
 
  select @validcnt = count(*) from inserted i where i.EmplBased = 'Y' and i.ProcessSeq is null
  if @validcnt > 0
  	begin
  	select @errmsg = 'Employee Based Flag is ''Y'' so Processing Sequence must not be null. '
  	goto error
  	end
 
  select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
  	i.PRCo = l.PRCo and i.DLCode = l.DLCode where l.Method <> 'R' and i.FileStatus is not null
  if @validcnt > 0
  	begin
  	select @errmsg = 'Filing Status must be null if Dedn/Liab Code method is not Routine. '
  	goto error
  	end
 
  select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
  	i.PRCo = l.PRCo and i.DLCode = l.DLCode where l.Method <> 'R' and i.RegExempts is not null
  if @validcnt > 0
  	begin
  	select @errmsg = 'Regular Exemptions must be null if Dedn/Liab Code method is not Routine. '
  	goto error
  	end
 
  select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
  	i.PRCo = l.PRCo and i.DLCode = l.DLCode where l.Method <> 'R' and i.AddExempts is not null
  if @validcnt > 0
  	begin
  	select @errmsg = 'Additional Exemptions must be null if Dedn/Liab Code method is not Routine. '
  	goto error
  	end
 
 
  select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
  	i.PRCo = l.PRCo and i.DLCode = l.DLCode where l.Method <> 'R' and i.OverMiscAmt = 'Y'
  if @validcnt > 0
  	begin
  	select @errmsg = 'Override Miscellaneous Amount Flag must be ''N'' if Dedn/Liab Code method is not Routine. '
  	goto error
  	end
 
  select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
  	i.PRCo = l.PRCo and i.DLCode = l.DLCode where l.Method <> 'R' and i.MiscAmt<>0
  if @validcnt > 0
  	begin
  	select @errmsg = 'Misc Amount must be zero if Dedn/Liab Code method is not Routine. '
  	goto error
  	end
 
  select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
  	i.PRCo = l.PRCo and i.DLCode = l.DLCode where l.Method = 'R' and i.OverMiscAmt = 'N' and
  	(i.MiscAmt <> 0.00 or i.MiscAmt <> 0)
  if @validcnt > 0
  	begin
  	select @errmsg = 'Misc Amount must be zero if the Override Misc Amount flag is set to ''N''. '
  	goto error
  	end
 
--  select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
--  	i.PRCo = l.PRCo and i.DLCode = l.DLCode where l.Method <> 'R' and i.FileStatus is not null
--  if @validcnt > 0
--  	begin
--  	select @errmsg = 'Misc Factor must be null if Dedn/Liab Code method is not Routine. '
--  	goto error
--  	end

--Issue 123435
	select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
  	i.PRCo = l.PRCo and i.DLCode = l.DLCode where l.Method <> 'R' and i.MiscFactor is not null
	if @validcnt <> 0
  	begin
  	select @errmsg = 'Miscellaneous Factor must be null if method is not routine '
  	goto error
  	end
 
  select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
  	i.PRCo = l.PRCo and i.DLCode = l.DLCode where l.AutoAP = 'N' and i.Vendor is not null
  if @validcnt > 0
  	begin
  	select @errmsg = 'Dedn/Liab Code is not set up for Auto updates to AP - vendor must be null '
  	goto error
  	end
 
 /*validate CalCategory.*/
 select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.DLCode = c.DLCode
     where c.CalcCategory not in ('E', 'A')and i.EmplBased = 'Y' 
 if @validcnt <> 0
 	begin
 	select @errmsg = 'Ded/Liab Code calculation category must be E or A when Employee based. '
 	goto error
 	end
 
 select @validcnt = count(*) from inserted i where
 	i.VendorGroup is null
 select @validcnt2 = count(*) from inserted i join dbo.HQGP g with (nolock) on
 	i.VendorGroup = g.Grp where i.VendorGroup is not null --and
 	--i.Vendor is not null
 if @validcnt + @validcnt2 <> @numrows
 	begin
 	select @errmsg = 'Vendor Group is invalid. '
 	goto error
 	end
 
  select @validcnt = count(*) from inserted i where
  	i.VendorGroup is null or i.Vendor is null
  select @validcnt2 = count(*) from inserted i join dbo.APVM v with (nolock) on
  	i.VendorGroup = v.VendorGroup and i.Vendor = v.Vendor where i.VendorGroup is not null and i.Vendor is not null
  if @validcnt + @validcnt2 <> @numrows
  	begin
  	select @errmsg = 'Invalid vendor. '
  	goto error
  	end
 
 select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
 	i.PRCo = l.PRCo and i.DLCode = l.DLCode where l.AutoAP = 'N'
 	and i.APDesc is not null
 if @validcnt > 0
 	begin
 	select @errmsg = 'Dedn/Liab Code is not set up for Auto updates to AP - AP Description must be null '
 	goto error
 	end
 
  /* validate GL Company */
  select @validcnt = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.GLCo
  if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid GL Company# '
  	goto error
  	end
 
  -- validate Override GL acct
  select @validcnt = count(*) from inserted where OverGLAcct is not null
  select @validcnt2 = count(*) from inserted i join dbo.GLAC a with (nolock) on a.GLCo = i.GLCo and a.GLAcct = i.OverGLAcct
     where i.OverGLAcct is not null
  if @validcnt <> @validcnt2
     begin
     select @errmsg = 'Invalid Override GL Account '
     goto error
     end
 
  -- validate OverCalcs
  select @validcnt = count(*) from inserted where OverCalcs <> 'N' and OverCalcs <> 'M' and OverCalcs <> 'R'
 	and OverCalcs <> 'A'
  if @validcnt > 0
 	begin
 	select @errmsg = 'Calculation Override Option must be ''N'', ''M'', ''R'', or ''A''. '
 	goto error
 	end
 
     select @validcnt = count(*) from inserted i where i.OverCalcs = 'N' and
     	RateAmt <> 0
     if @validcnt > 0
     	begin
     	select @errmsg = 'Rate/Amount must be zero when Calculation Override Option is set to ''N''. '
     	goto error
     	end
 
     select @validcnt = count(*) from inserted i where
     	i.OverLimit = 'N' and i.Limit <> 0
     if @validcnt > 0
     	begin
     	select @errmsg = 'Limit must be zero if the Override Limit flag is set to ''N''. '
     	goto error
     	end
 
  -- validate NetPayOpt
  select @validcnt = count(*) from inserted where NetPayOpt <> 'N' and NetPayOpt <> 'P' and NetPayOpt <> 'A'
  if @validcnt > 0
 	begin
 	select @errmsg = 'Net Pay Option must be ''N'', ''P'' or ''A''. '
 	goto error
 	end
 
  select @validcnt = count(*) from inserted i where
 	i.NetPayOpt = 'N' and i.MinNetPay <> 0
  if @validcnt > 0
 	begin
 	select @errmsg = 'Minimum Net Pay must be zero if the Net Pay Option is set to ''N''. '
 	goto error
 	end
 
  -- validate Addon Type
  select @validcnt = count(*) from inserted where	AddonType <> 'N' and AddonType <> 'A' and AddonType <> 'R'
  if @validcnt > 0
 	begin
 	select @errmsg = 'Addon Type must be ''N'', ''A'', or ''R''. '
 	goto error
 	end
 
  select @validcnt = count(*) from inserted i where
 	i.AddonType = 'N' and i.AddonRateAmt <> 0
  if @validcnt > 0
 	begin
 	select @errmsg = 'Addon Rate/Amount must be zero if the Addon Type is set to ''N''. '
 	goto error
 	end
 
  -- validate EICStatus - added with issue 15822
  select @validcnt = count(*) from inserted where EICStatus<>'N' and EICStatus<>'S' and EICStatus<>'M' and EICStatus<>'B'
  if @validcnt > 0
 	begin
 	select @errmsg = 'EICStatus must be ''N'', ''S'', ''M'', or ''B''. '
 	goto error
 	end
 
 -- validate CS Allocation Group
 select @validcnt = count(*) from inserted where CSAllocGroup<1 or CSAllocGroup>255
 if @validcnt > 0
 	begin
 	select @errmsg = 'Garnishment Allocation Group must be an integer from 1 to 255. '
 	goto error
 	end

	--Cross update to bHRWI
	declare @prco bCompany, @employee bEmployee, @filestatus char(1), @dlcode bEDLCode, @regexempts tinyint, 
	@addexempts tinyint, @overmiscamt bYN, @miscamt bDollar, @miscfactor bRate, @addontype char(1), @addonrateamt bUnitCost,
	@hrref bHRRef, @hrco bCompany, @opencurs tinyint

	declare insertCurs cursor local fast_forward for
	select i.PRCo, i.Employee, i.DLCode, i.FileStatus, i.RegExempts, i.AddExempts, i.OverMiscAmt, 
		i.MiscAmt, i.MiscFactor, i.AddonType,i.AddonRateAmt, m.HRCo, m.HRRef
	from inserted i
	Join bHRRM m on i.PRCo = m.PRCo and i.Employee = m.PREmp
	join bHRCO o on m.HRCo = o.HRCo and o.UpdateW4YN = 'Y'
	join bPRDL l on i.PRCo = l.PRCo and i.DLCode = l.DLCode and l.Method = 'R' and l.DLType = 'D' --#133605 added Type check


	open insertCurs

	select @opencurs = 1

	fetch next from insertCurs 
	into @prco, @employee, @dlcode, @filestatus,  @regexempts, @addexempts, @overmiscamt,
	@miscamt, @miscfactor, @addontype, @addonrateamt, @hrco, @hrref

	while @@fetch_status = 0
	begin

		if not exists(
			select 1 from bHRWI h 
			join bHRRM m on h.HRCo = m.HRCo and m.HRRef = h.HRRef and m.PRCo = @prco and m.PREmp = @employee
			join bHRCO o on h.HRCo = o.HRCo and o.UpdateW4YN = 'Y'
			where h.DednCode = @dlcode)
		begin
			insert bHRWI (HRCo, HRRef, DednCode, FileStatus, RegExemp, AddionalExemp,
				OverrideMiscAmtYN, MiscAmt1, MiscFactor, AddonType, AddonRateAmt)
			values (@hrco, @hrref, @dlcode, @filestatus, @regexempts, @addexempts, @overmiscamt,
			@miscamt, @miscfactor, @addontype, @addonrateamt)
		end
		else
		begin
			update bHRWI set FileStatus = @filestatus, RegExemp = @regexempts, AddionalExemp = @addexempts,
			OverrideMiscAmtYN = @overmiscamt, MiscAmt1 = @miscamt, MiscFactor = @miscfactor, 
			AddonType = @addontype, AddonRateAmt = @addonrateamt
			where HRCo = @hrco and HRRef = @hrref and DednCode = @dlcode
		end

		fetch next from insertCurs 
		into @prco, @employee, @dlcode, @filestatus, @regexempts, @addexempts, @overmiscamt, --issue 126457
		@miscamt, @miscfactor, @addontype, @addonrateamt, @hrco, @hrref

	end

	if @opencurs = 1
	begin
		close insertCurs
		deallocate insertCurs
	end
 
  /* add HQ Master Audit entry */
  insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	 select 'bPRED',  'PRCo: ' + convert(varchar(3),i.PRCo) +' Empl: ' + convert(varchar(10), Employee) +
  	 ' DLCode: ' + convert(varchar(10),DLCode), i.PRCo, 'A',
  	 null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.PRCO with (nolock)
  	 on i.PRCo=PRCO.PRCo where PRCO.AuditEmployees = 'Y'
 	
  return
	
  error:

	if @opencurs = 1
	begin
		close insertCurs
		deallocate insertCurs
	end

  	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Employee Deductions/Liabilites!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
 
 
 
 
 
 
 
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
 
 
 
 
 
 
 
 
 
/****** Object:  Trigger [dbo].[btPREDu]    Script Date: 12/27/2007 09:44:22 ******/
  CREATE             trigger [dbo].[btPREDu] on [dbo].[bPRED] for UPDATE as
  


/*-----------------------------------------------------------------
   *   	Created by: kb 12/21/98
   * 	Modified by: ae 03/05/00  --Vendor Group inaccurately checking if vendor is null
   *               EN 4/11/00 - added the following validations to match checks being done in insert trigger:
   *                              check for null Frequency code if Employee Based Flag is 'N'
   *                              check that Misc Amount is null or zero if the Override Misc Amount flag is set to 'N'
   *               EN 10/03/00 - Null MiscAmt is not allowed (issue 10318)
   *               EN 10/04/00 - Fixed bug in section to check for key changes (issue 10318)
   *				 EN 1/9/02 - issue 15822 - validate EICStatus
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *				EN 02/12/03 - issue 23061  added isnull check, with (nolock), and dbo
   *				EN 3/03/04 - issue 18862  added validation for CSAllocGroup
   *				mh 7/27/04 - issue 24623
   *				EN 10/26/05 - issue 30064  modified bHQMA insert statement to resolve Arithmetic overflow error
   *				EN 12/27/08 - #126315  allow for 20 character MiscAmt, Limit, and MinNetPay when logging to HQMA
   *				EN 7/09/08 - #127015 - added code for MiscAmt2 to HQMA auditing
   *				mh 8/7/2008 - #129198 - added code to cross update MiscAmt2 to HRWI
   *				EN 1/7/2009 #130784  fixed Vendor validation
   *				EN 8/2/2012 Epic B-07873/User Story B-10147 - added bHQMA auditing for new arrears/payback fields
   *
   *	This trigger rejects updates in bPRED (PR Employee Deductions/Liabilities)
   *	if the following error condition exists:
   *
   *	Adds HQ Master Audit entry.
   */----------------------------------------------------------------
  declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
  select @numrows = @@rowcount
  if @numrows = 0 return
  set nocount on
  
  /* check for key changes */
  if update(PRCo)
   	begin
   	select @errmsg = 'Cannot change PR Company '
   	goto error
   	end
  if update(Employee)
   	begin
   	select @errmsg = 'Cannot change Employee '
   	goto error
   	end
  if update(DLCode)
   	begin
   	select @errmsg = 'Cannot change Deduction/Liability Code '
   	goto error
   	end
  
   select @validcnt = count(*) from inserted i where i.EmplBased = 'Y' and i.ProcessSeq is null
   if @validcnt > 0
   	begin
   	select @errmsg = 'Employee Based Flag is ''Y'' so Processing Sequence must not be null. '
   	goto error
   	end
  
   select @validcnt = count(*) from inserted i where i.EmplBased = 'N' and i.Frequency is not null
   if @validcnt > 0
   	begin
   	select @errmsg = 'Frequency code must be null if Employee Based Flag is ''N''. '
   	goto error
   	end
  
   select @validcnt = count(*) from inserted i where i.Frequency is null
   select @validcnt2 = count(*) from inserted i join dbo.HQFC f with (nolock)
   	on i.Frequency = f.Frequency where i.Frequency is not null
   if @validcnt + @validcnt2 <> @numrows
   	begin
   	select @errmsg = 'Invalid Frequency Code '
   	goto error
   	end
  
   select @validcnt = count(*) from inserted i
   	where i.ProcessSeq is not null and i.EmplBased = 'N'
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Processing Sequence can only be set for Employee Based D/L '
   	goto error
   	end
  
   select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
   	i.PRCo = l.PRCo and i.DLCode = l.DLCode where
   	l.Method <> 'R' and i.FileStatus is not null
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Filing Status must be null if method is not routine '
   	goto error
   	end
  
   select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
   	i.PRCo = l.PRCo and i.DLCode = l.DLCode where
   	l.Method <> 'R' and i.RegExempts is not null
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Regular Exemptions must be null if method is not routine '
   	goto error
   	end
  
   select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
   	i.PRCo = l.PRCo and i.DLCode = l.DLCode where
   	l.Method <> 'R' and i.AddExempts is not null
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Additional Exemptions must be null if method is not routine '
   	goto error
   	end
  
   select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
   	i.PRCo = l.PRCo and i.DLCode = l.DLCode where
   	l.Method <> 'R' and i.OverMiscAmt = 'Y'
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Override Miscellaneous Amount flag must be ''N'' if method is not routine '
   	goto error
   	end
  
   select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
   	i.PRCo = l.PRCo and i.DLCode = l.DLCode where
   	l.Method <> 'R' and i.MiscAmt <> 0
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Miscellaneous Amount must be zero if method is not routine '
   	goto error
   	end
  
   select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
   	i.PRCo = l.PRCo and i.DLCode = l.DLCode where l.Method = 'R' and i.OverMiscAmt = 'N' and
   	(i.MiscAmt <> 0.00 or i.MiscAmt <> 0)
   if @validcnt > 0
   	begin
   	select @errmsg = 'Misc Amount must be zero if the Override Misc Amount flag is set to ''N''. '
   	goto error
   	end
  
   select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
   	i.PRCo = l.PRCo and i.DLCode = l.DLCode where
   	l.Method <> 'R' and i.MiscFactor is not null
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Miscellaneous Factor must be null if method is not routine '
   	goto error
   	end
  
  if update(VendorGroup)
  	begin
  	select @validcnt = count(*) from inserted i where
  		i.VendorGroup is null
  	select @validcnt2 = count(*) from inserted i join dbo.HQGP g with (nolock) on
  		i.VendorGroup = g.Grp where i.VendorGroup is not null --and
  		--i.Vendor is not null
  	if @validcnt + @validcnt2 <> @numrows
  		begin
  		select @errmsg = 'Vendor Group is invalid. '
  		goto error
  		end
  	end
  
  if update(Vendor)
  	begin
  	select @validcnt = count(*) from inserted i where
  		i.VendorGroup is null or i.Vendor is null
  	select @validcnt2 = count(*) from inserted i join dbo.APVM v with (nolock) on
  		i.VendorGroup = v.VendorGroup and i.Vendor = v.Vendor where
  		i.VendorGroup is not null and i.Vendor is not null
  
  	if @validcnt + @validcnt2 <> @numrows
  		begin
  		select @errmsg = 'Vendor is invalid. '
  		goto error
  		end
  	select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
  		i.PRCo = l.PRCo and i.DLCode = l.DLCode where l.AutoAP = 'N'
  		and i.Vendor is not null
  	if @validcnt > 0
  		begin
  		select @errmsg = 'Dedn/Liab Code is not set up for Auto updates to AP - vendor must be null '
  		goto error
  		end
  	end
  
  if update(APDesc)
  	begin
  	select @validcnt = count(*) from inserted i join dbo.PRDL l with (nolock) on
  		i.PRCo = l.PRCo and i.DLCode = l.DLCode where l.AutoAP = 'N'
  		and i.APDesc is not null
  	if @validcnt > 0
  		begin
  		select @errmsg = 'Dedn/Liab Code is not set up for Auto updates to AP - AP Description must be null '
  		goto error
  		end
  	end
  
  if update(GLCo)
  	begin
  	select @validcnt = count(*) from inserted i join dbo.GLCO g with (nolock) on
  		i.GLCo = g.GLCo
  	if @validcnt <> @numrows
  		begin
  		select @errmsg = 'GL Company is invalid. '
  		goto error
  		end
  	end
  
  if update(OverGLAcct)
  	begin
  	select @validcnt = count(*) from inserted i where
  		i.OverGLAcct is null
  	select @validcnt2 = count(*) from inserted i join dbo.GLAC v with (nolock) on
  		i.GLCo = v.GLCo and i.OverGLAcct = v.GLAcct where
  		i.OverGLAcct is not null
  	if @validcnt + @validcnt2 <> @numrows
  		begin
  		select @errmsg = 'Override GL Account is invalid. '
  		goto error
  		end
  	end
  
  select @validcnt = count(*) from inserted i where
  	i.OverCalcs <> 'N' and i.OverCalcs <> 'M' and i.OverCalcs <> 'R'
  	and i.OverCalcs <> 'A'
  if @validcnt > 0
  	begin
  	select @errmsg = 'Calculation Override Option must be ''N'', ''M'', ''R'', or ''A''. '
  	goto error
  	end
  
  select @validcnt = count(*) from inserted i where i.OverCalcs = 'N' and
  	RateAmt <> 0
  if @validcnt > 0
  	begin
  	select @errmsg = 'Rate/Amount must be zero when Calculation Override Option is set to ''N''. '
  	goto error
  	end
  
  select @validcnt = count(*) from inserted i where
  	i.OverLimit = 'N' and i.Limit <> 0
  if @validcnt > 0
  	begin
  	select @errmsg = 'Limit must be zero if the Override Limit flag is set to ''N''. '
  	goto error
  	end
  
  select @validcnt = count(*) from inserted i where
  	i.NetPayOpt <> 'N' and i.NetPayOpt <> 'P' and i.NetPayOpt <> 'A'
  if @validcnt > 0
  	begin
  	select @errmsg = 'Net Pay Option must be ''N'', ''P'' or ''A''. '
  	goto error
  	end
  
  select @validcnt = count(*) from inserted i where
  	i.NetPayOpt = 'N' and i.MinNetPay <> 0
  if @validcnt > 0
  	begin
  	select @errmsg = 'Minimum Net Pay must be zero if the Net Pay Option is set to ''N''. '
  	goto error
  	end
  
  select @validcnt = count(*) from inserted i where
  	i.AddonType <> 'N' and i.AddonType <> 'A' and i.AddonType <> 'R'
  if @validcnt > 0
  	begin
  	select @errmsg = 'Addon Type must be ''N'', ''A'', or ''R''. '
  	goto error
  	end
  
  select @validcnt = count(*) from inserted i where
  	i.AddonType = 'N' and i.AddonRateAmt <> 0
  if @validcnt > 0
  	begin
  	select @errmsg = 'Addon Rate/Amount must be zero if the Addon Type is set to ''N''. '
  	goto error
  	end
  
  -- validate EICStatus - added with issue 15822
  select @validcnt = count(*) from inserted where EICStatus<>'N' and EICStatus<>'S' and EICStatus<>'M' and EICStatus<>'B'
  if @validcnt > 0
  	begin
  	select @errmsg = 'EICStatus must be ''N'', ''S'', ''M'', or ''B''. '
  	goto error
  	end
  
  -- validate CS Allocation Group
  select @validcnt = count(*) from inserted where CSAllocGroup<1 or CSAllocGroup>255
  if @validcnt > 0
  	begin
  	select @errmsg = 'Garnishment Allocation Group must be an integer from 1 to 255. '
  	goto error
  	end

  --Cross update Deductions to HRWI if Employee exists in HR

	if exists(select 1 from bHRRM h join inserted i on h.PRCo = i.PRCo and h.PREmp = i.Employee)
	begin
		--Employee exists in HR
		if update(FileStatus) or update(RegExempts) or update(AddExempts) or update(OverMiscAmt) or
		update(MiscAmt) or update(MiscFactor) or update(AddonType) or update(AddonRateAmt) or 
		update(MiscAmt2)
		begin
			update bHRWI set bHRWI.FileStatus = i.FileStatus, bHRWI.RegExemp = i.RegExempts, bHRWI.AddionalExemp = i.AddExempts,
			bHRWI.OverrideMiscAmtYN = i.OverMiscAmt, bHRWI.MiscAmt1 = i.MiscAmt, bHRWI.MiscFactor = i.MiscFactor,
			bHRWI.AddonType = i.AddonType, bHRWI.AddonRateAmt = i.AddonRateAmt, bHRWI.MiscAmt2 = i.MiscAmt2
			from inserted i
			Join bHRRM m on i.PRCo = m.PRCo and i.Employee = m.PREmp
			join bHRWI h on m.HRCo = h.HRCo and m.HRRef = h.HRRef and h.DednCode = i.DLCode
			join bHRCO o on m.HRCo = o.HRCo and o.UpdateW4YN = 'Y'
			where h.FileStatus <> i.FileStatus or h.RegExemp <> i.RegExempts or h.AddionalExemp <> i.AddExempts or
			h.OverrideMiscAmtYN <> i.OverMiscAmt or h.MiscAmt1 <> i.MiscAmt or h.MiscFactor <> i.MiscFactor or
			h.AddonType <> i.AddonType or h.AddonRateAmt <> i.AddonRateAmt
		end
	end

  --End cross update
  
  /* add HQ Master Audit entry */
  if exists (select * from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditEmployees = 'Y')
  	begin
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Employee Based', d.EmplBased, i.EmplBased,
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where d.EmplBased <> i.EmplBased and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Frequency', d.Frequency, i.Frequency,
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.Frequency,'') <> isnull(i.Frequency,'') and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Processing Seq', convert(varchar(10),d.ProcessSeq), convert(varchar(10),i.Frequency),
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.ProcessSeq,0) <> isnull(i.ProcessSeq,0) and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','File Status', d.FileStatus, i.FileStatus,
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.FileStatus,'') <> isnull(i.FileStatus,'') and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Regular Exemptions', convert(varchar(10),d.RegExempts), convert(varchar(10),i.RegExempts),
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.RegExempts,0) <> isnull(i.RegExempts,0) and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Additional Exemptions', convert(varchar(10),d.AddExempts), convert(varchar(10),i.AddExempts),
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.AddExempts,0) <> isnull(i.AddExempts,0) and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Override Misc Amt', d.OverMiscAmt, i.OverMiscAmt,
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
  
     where isnull(d.OverMiscAmt,0) <> isnull(i.OverMiscAmt,0) and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Misc Amt', convert(varchar(20),d.MiscAmt), convert(varchar(20),i.MiscAmt),
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.MiscAmt,0) <> isnull(i.MiscAmt,0) and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Misc Factor', convert(varchar(10),d.MiscFactor), convert(varchar(10),i.MiscFactor),
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.MiscFactor,0) <> isnull(i.MiscFactor,0) and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Vendor Group', convert(varchar(10),d.VendorGroup), convert(varchar(10),i.VendorGroup),
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.VendorGroup,'') <> isnull(i.VendorGroup,'') and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Vendor', convert(varchar(10),d.Vendor), convert(varchar(10),i.Vendor),
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.Vendor,0) <> isnull(i.Vendor,0) and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','AP Description', d.APDesc, i.APDesc,
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.APDesc,'') <> isnull(i.APDesc,'') and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','GL Company', convert(varchar(10),d.GLCo), convert(varchar(10),i.GLCo),
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where d.GLCo <> i.GLCo and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Override GL Account', d.OverGLAcct, i.OverGLAcct,
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.OverGLAcct,'') <> isnull(i.OverGLAcct,'') and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
      	i.PRCo, 'C','Override Calculations Option', d.OverCalcs, i.OverCalcs,
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where d.OverCalcs <> i.OverCalcs and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Rate/Amount', convert(varchar(20),d.RateAmt), convert(varchar(20),i.RateAmt), --#30064
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.RateAmt,0) <> isnull(i.RateAmt,0) and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Override Limit', d.OverLimit, i.OverLimit,
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where d.OverLimit <> i.OverLimit and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Limit', convert(varchar(20),d.Limit), convert(varchar(20),i.Limit),
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.Limit,0) <> isnull(i.Limit,0) and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Net Pay Option', d.NetPayOpt, i.NetPayOpt,
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where d.NetPayOpt <> i.NetPayOpt and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Minimum Net Pay', convert(varchar(20),d.MinNetPay), convert(varchar(20),i.MinNetPay),
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.MinNetPay,0) <> isnull(i.MinNetPay,0) and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Addon Type', d.AddonType, i.AddonType,
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where d.AddonType <> i.AddonType and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','Addon Rate/Amount', convert(varchar(20),d.AddonRateAmt), convert(varchar(20),i.AddonRateAmt), --#30064
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.AddonRateAmt,0) <> isnull(i.AddonRateAmt,0) and a.AuditEmployees = 'Y'
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 'C','MiscAmt2', convert(varchar(20),d.MiscAmt2), convert(varchar(20),i.MiscAmt2),
        	getdate(), SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.MiscAmt2,0) <> isnull(i.MiscAmt2,0) and a.AuditEmployees = 'Y'
          
       insert into dbo.bHQMA select 'bPRED', 'PR Co#: ' + convert(char(3),i.PRCo) +
       	' Empl#: ' + convert(varchar(10),i.Employee) + ' DLCode: ' + convert(varchar(10),i.DLCode),
       	i.PRCo, 
       	'C',
       	'MembershipNumber', 
       	convert(varchar(60),d.MembershipNumber), 
       	convert(varchar(60),i.MembershipNumber),
        	getdate(), 
        	SUSER_SNAME()
        	from inserted i join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.DLCode = d.DLCode
          join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(d.MembershipNumber,0) <> isnull(i.MembershipNumber,0) and a.AuditEmployees = 'Y'
       
       -- LifeToDateArrears   
       INSERT INTO dbo.bHQMA 
       SELECT 'bPRED', 
			  'PR Co#: ' + CONVERT(char(3),i.PRCo) + ' Empl#: ' + CONVERT(varchar(10),i.Employee) + 
			  ' DLCode: ' + CONVERT(varchar(10),i.DLCode), i.PRCo, 'C', 
			  'LifeToDateArrears', CONVERT(varchar(20),d.LifeToDateArrears), CONVERT(varchar(20),i.LifeToDateArrears), 
       		  GETDATE(), SUSER_SNAME()
       FROM inserted i 
       JOIN deleted d ON i.PRCo = d.PRCo AND i.Employee = d.Employee AND i.DLCode = d.DLCode
       JOIN dbo.PRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
       WHERE d.LifeToDateArrears <> i.LifeToDateArrears AND a.AuditEmployees = 'Y'

       -- LifeToDatePayback   
       INSERT INTO dbo.bHQMA 
       SELECT 'bPRED', 
			  'PR Co#: ' + CONVERT(char(3),i.PRCo) + ' Empl#: ' + CONVERT(varchar(10),i.Employee) + 
			  ' DLCode: ' + CONVERT(varchar(10),i.DLCode), i.PRCo, 'C', 
			  'LifeToDatePayback', CONVERT(varchar(20),d.LifeToDatePayback), CONVERT(varchar(20),i.LifeToDatePayback), 
       		  GETDATE(), SUSER_SNAME()
       FROM inserted i 
       JOIN deleted d ON i.PRCo = d.PRCo AND i.Employee = d.Employee AND i.DLCode = d.DLCode
       JOIN dbo.PRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
       WHERE d.LifeToDatePayback <> i.LifeToDatePayback AND a.AuditEmployees = 'Y'
       
       -- EligibleForArrearsCalc   
       INSERT INTO dbo.bHQMA 
       SELECT 'bPRED', 
			  'PR Co#: ' + CONVERT(char(3),i.PRCo) + ' Empl#: ' + CONVERT(varchar(10),i.Employee) + 
			  ' DLCode: ' + CONVERT(varchar(10),i.DLCode), i.PRCo, 'C', 
			  'EligibleForArrearsCalc', CONVERT(varchar(20),d.EligibleForArrearsCalc), CONVERT(varchar(20),i.EligibleForArrearsCalc), 
       		  GETDATE(), SUSER_SNAME()
       FROM inserted i 
       JOIN deleted d ON i.PRCo = d.PRCo AND i.Employee = d.Employee AND i.DLCode = d.DLCode
       JOIN dbo.PRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
       WHERE d.EligibleForArrearsCalc <> i.EligibleForArrearsCalc AND a.AuditEmployees = 'Y'
       
       -- OverrideStdArrearsThreshold   
       INSERT INTO dbo.bHQMA 
       SELECT 'bPRED', 
			  'PR Co#: ' + CONVERT(char(3),i.PRCo) + ' Empl#: ' + CONVERT(varchar(10),i.Employee) + 
			  ' DLCode: ' + CONVERT(varchar(10),i.DLCode), i.PRCo, 'C', 
			  'OverrideStdArrearsThreshold', CONVERT(varchar(20),d.OverrideStdArrearsThreshold), CONVERT(varchar(20),i.OverrideStdArrearsThreshold), 
       		  GETDATE(), SUSER_SNAME()
       FROM inserted i 
       JOIN deleted d ON i.PRCo = d.PRCo AND i.Employee = d.Employee AND i.DLCode = d.DLCode
       JOIN dbo.PRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
       WHERE d.OverrideStdArrearsThreshold <> i.OverrideStdArrearsThreshold AND a.AuditEmployees = 'Y'
       
       -- RptArrearsThresholdOverride   
       INSERT INTO dbo.bHQMA 
       SELECT 'bPRED', 
			  'PR Co#: ' + CONVERT(char(3),i.PRCo) + ' Empl#: ' + CONVERT(varchar(10),i.Employee) + 
			  ' DLCode: ' + CONVERT(varchar(10),i.DLCode), i.PRCo, 'C', 
			  'RptArrearsThresholdOverride', CONVERT(varchar(20),d.RptArrearsThresholdOverride), CONVERT(varchar(20),i.RptArrearsThresholdOverride), 
       		  GETDATE(), SUSER_SNAME()
       FROM inserted i 
       JOIN deleted d ON i.PRCo = d.PRCo AND i.Employee = d.Employee AND i.DLCode = d.DLCode
       JOIN dbo.PRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
       WHERE d.RptArrearsThresholdOverride <> i.RptArrearsThresholdOverride AND a.AuditEmployees = 'Y'
       
       -- ThresholdFactorOverride   
       INSERT INTO dbo.bHQMA 
       SELECT 'bPRED', 
			  'PR Co#: ' + CONVERT(char(3),i.PRCo) + ' Empl#: ' + CONVERT(varchar(10),i.Employee) + 
			  ' DLCode: ' + CONVERT(varchar(10),i.DLCode), i.PRCo, 'C', 
			  'ThresholdFactorOverride', CONVERT(varchar(20),d.ThresholdFactorOverride), CONVERT(varchar(20),i.ThresholdFactorOverride), 
       		  GETDATE(), SUSER_SNAME()
       FROM inserted i 
       JOIN deleted d ON i.PRCo = d.PRCo AND i.Employee = d.Employee AND i.DLCode = d.DLCode
       JOIN dbo.PRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
       WHERE d.ThresholdFactorOverride <> i.ThresholdFactorOverride AND a.AuditEmployees = 'Y'
       
       -- ThresholdAmountOverride   
       INSERT INTO dbo.bHQMA 
       SELECT 'bPRED', 
			  'PR Co#: ' + CONVERT(char(3),i.PRCo) + ' Empl#: ' + CONVERT(varchar(10),i.Employee) + 
			  ' DLCode: ' + CONVERT(varchar(10),i.DLCode), i.PRCo, 'C', 
			  'ThresholdAmountOverride', CONVERT(varchar(20),d.ThresholdAmountOverride), CONVERT(varchar(20),i.ThresholdAmountOverride), 
       		  GETDATE(), SUSER_SNAME()
       FROM inserted i 
       JOIN deleted d ON i.PRCo = d.PRCo AND i.Employee = d.Employee AND i.DLCode = d.DLCode
       JOIN dbo.PRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
       WHERE d.ThresholdAmountOverride <> i.ThresholdAmountOverride AND a.AuditEmployees = 'Y'
       
       -- OverrideStdPaybackSettings   
       INSERT INTO dbo.bHQMA 
       SELECT 'bPRED', 
			  'PR Co#: ' + CONVERT(char(3),i.PRCo) + ' Empl#: ' + CONVERT(varchar(10),i.Employee) + 
			  ' DLCode: ' + CONVERT(varchar(10),i.DLCode), i.PRCo, 'C', 
			  'OverrideStdPaybackSettings', CONVERT(varchar(20),d.OverrideStdPaybackSettings), CONVERT(varchar(20),i.OverrideStdPaybackSettings), 
       		  GETDATE(), SUSER_SNAME()
       FROM inserted i 
       JOIN deleted d ON i.PRCo = d.PRCo AND i.Employee = d.Employee AND i.DLCode = d.DLCode
       JOIN dbo.PRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
       WHERE d.OverrideStdPaybackSettings <> i.OverrideStdPaybackSettings AND a.AuditEmployees = 'Y'
       
       -- PaybackPerPayPeriodOverride   
       INSERT INTO dbo.bHQMA 
       SELECT 'bPRED', 
			  'PR Co#: ' + CONVERT(char(3),i.PRCo) + ' Empl#: ' + CONVERT(varchar(10),i.Employee) + 
			  ' DLCode: ' + CONVERT(varchar(10),i.DLCode), i.PRCo, 'C', 
			  'PaybackPerPayPeriodOverride', CONVERT(varchar(20),d.PaybackPerPayPeriodOverride), CONVERT(varchar(20),i.PaybackPerPayPeriodOverride), 
       		  GETDATE(), SUSER_SNAME()
       FROM inserted i 
       JOIN deleted d ON i.PRCo = d.PRCo AND i.Employee = d.Employee AND i.DLCode = d.DLCode
       JOIN dbo.PRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
       WHERE d.PaybackPerPayPeriodOverride <> i.PaybackPerPayPeriodOverride AND a.AuditEmployees = 'Y'
       
       -- PaybackFactorOverride   
       INSERT INTO dbo.bHQMA 
       SELECT 'bPRED', 
			  'PR Co#: ' + CONVERT(char(3),i.PRCo) + ' Empl#: ' + CONVERT(varchar(10),i.Employee) + 
			  ' DLCode: ' + CONVERT(varchar(10),i.DLCode), i.PRCo, 'C', 
			  'PaybackFactorOverride', CONVERT(varchar(20),d.PaybackFactorOverride), CONVERT(varchar(20),i.PaybackFactorOverride), 
       		  GETDATE(), SUSER_SNAME()
       FROM inserted i 
       JOIN deleted d ON i.PRCo = d.PRCo AND i.Employee = d.Employee AND i.DLCode = d.DLCode
       JOIN dbo.PRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
       WHERE d.PaybackFactorOverride <> i.PaybackFactorOverride AND a.AuditEmployees = 'Y'
       
       -- PaybackAmountOverride   
       INSERT INTO dbo.bHQMA 
       SELECT 'bPRED', 
			  'PR Co#: ' + CONVERT(char(3),i.PRCo) + ' Empl#: ' + CONVERT(varchar(10),i.Employee) + 
			  ' DLCode: ' + CONVERT(varchar(10),i.DLCode), i.PRCo, 'C', 
			  'PaybackAmountOverride', CONVERT(varchar(20),d.PaybackAmountOverride), CONVERT(varchar(20),i.PaybackAmountOverride), 
       		  GETDATE(), SUSER_SNAME()
       FROM inserted i 
       JOIN deleted d ON i.PRCo = d.PRCo AND i.Employee = d.Employee AND i.DLCode = d.DLCode
       JOIN dbo.PRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
       WHERE d.PaybackAmountOverride <> i.PaybackAmountOverride AND a.AuditEmployees = 'Y'

      end
  
  
  return
  error:
  	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Employee Deductions/Liabilities!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
  
  
  
  
  
  
  
  
  
  
  
  
  
  
 
 







GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRED].[EmplBased]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRED].[OverMiscAmt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRED].[RateAmt]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRED].[OverLimit]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRED].[CSMedCov]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRED].[CSAllocYN]'
GO
