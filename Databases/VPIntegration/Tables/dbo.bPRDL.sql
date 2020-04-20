CREATE TABLE [dbo].[bPRDL]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[DLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[LiabType] [dbo].[bLiabilityType] NULL,
[Method] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Routine] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[DednCode] [dbo].[bEDLCode] NULL,
[GarnGroup] [dbo].[bGroup] NULL,
[RateAmt1] [dbo].[bUnitCost] NOT NULL,
[RateAmt2] [dbo].[bUnitCost] NOT NULL,
[SeqOneOnly] [dbo].[bYN] NOT NULL,
[YTDCorrect] [dbo].[bYN] NOT NULL,
[BonusOverride] [dbo].[bYN] NOT NULL,
[BonusRate] [dbo].[bRate] NULL,
[LimitBasis] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[LimitAmt] [dbo].[bDollar] NOT NULL,
[LimitPeriod] [char] (1) COLLATE Latin1_General_BIN NULL,
[LimitCorrect] [dbo].[bYN] NULL,
[AutoAP] [dbo].[bYN] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[TransByEmployee] [dbo].[bYN] NULL,
[PayType] [tinyint] NULL,
[Frequency] [dbo].[bFreq] NULL,
[AccumSubjAmts] [dbo].[bYN] NOT NULL,
[SelectPurge] [dbo].[bYN] NOT NULL,
[DetOnCert] [dbo].[bYN] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[CalcCategory] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPRDL_CalcCategory] DEFAULT ('A'),
[FedType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[RndToDollar] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRDL_RndToDollar] DEFAULT ('N'),
[IncldW2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRDL_IncldW2] DEFAULT ('N'),
[W2State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[W2Local] [dbo].[bLocalCode] NULL,
[TaxType] [char] (1) COLLATE Latin1_General_BIN NULL,
[LimitRate] [dbo].[bRate] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PreTax] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRDL_PreTax] DEFAULT ('N'),
[PreTaxGroup] [tinyint] NULL,
[ATOCategory] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[SchemeID] [smallint] NULL,
[PreTaxCatchUpYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRDL_PreTaxCatchUpYN] DEFAULT ('N'),
[SubjToArrearsPayback] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRDL_SubjToArrearsPayback] DEFAULT ('N'),
[RptArrearsThreshold] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPRDL_RptArrearsThreshold] DEFAULT ('F'),
[ThresholdFactor] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bPRDL_ThresholdFactor] DEFAULT ((0.0)),
[ThresholdAmount] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRDL_ThresholdAmount] DEFAULT ((0)),
[PaybackPerPayPeriod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPRDL_PaybackPerPayPeriod] DEFAULT ('F'),
[PaybackFactor] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bPRDL_PaybackFactor] DEFAULT ((0.0)),
[PaybackAmount] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRDL_PaybackAmount] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
   /****** Object:  Trigger dbo.btPRDLd    Script Date: 8/28/99 9:38:12 AM ******/
   CREATE        trigger [dbo].[btPRDLd] on [dbo].[bPRDL] for DELETE as
    

/*-----------------------------------------------------------------
     *	Created by: kb 10/22/99
     *	Modified by: EN 11/29/00 - raise error if DL code exists in other PR tables
     *				 EN 3/22/02 - issue 16528 When check for d/l code in empl accums make sure EDLType<>'E'
     *				EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
     *				EN 6/13/05 - issue 28941  removed Active HR check and simplified check for DL code in bHRBL
     *				EN 9/07/05 - issue 26938  handle validation for Misc lines 3 & 4
	 *				EN 7/09/08  #127015  added code to make sure DL being deleted does not exist in bPRFI fields FUTALiab, MiscFedDL1, MiscFedDL2, MiscFedDL3, or MiscFedDL4
     *				Dan So 07/24/2012 - D-02774 - commented out references to PRWM
     *				MV 09/27/12 - B-10990 - check for d/l code in Arrears/Payback history table.
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int
    declare @prco integer, @employee integer
   
    select @numrows = @@rowcount
   
    if @numrows = 0 return
   
    if exists(select * from dbo.bPRDL e with (nolock) join deleted d on e.PRCo=d.PRCo and e.DLCode<>d.DLCode and e.DednCode=d.DLCode)
    	begin
    	select @errmsg='Code in use as deduction code for Rate of Deduction'
    	goto error
    	end
    if exists(select * from dbo.bPRLI e with (nolock) join deleted d on e.PRCo=d.PRCo and e.TaxDedn=d.DLCode)
    	begin
    	select @errmsg='Local info exists for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRLD e with (nolock) join deleted d on e.PRCo=d.PRCo and e.DLCode=d.DLCode)
    	begin
    	select @errmsg='Local detail(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRFI e with (nolock) join deleted d on e.PRCo=d.PRCo and e.TaxDedn=d.DLCode)
    	begin
    	select @errmsg='Federal info exists for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRFI e with (nolock) join deleted d on e.PRCo=d.PRCo and e.FUTALiab=d.DLCode)
    	begin
    	select @errmsg='Federal info exists for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRFI e with (nolock) join deleted d on e.PRCo=d.PRCo and e.MiscFedDL1=d.DLCode)
    	begin
    	select @errmsg='Federal info exists for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRFI e with (nolock) join deleted d on e.PRCo=d.PRCo and e.MiscFedDL2=d.DLCode)
    	begin
    	select @errmsg='Federal info exists for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRFI e with (nolock) join deleted d on e.PRCo=d.PRCo and e.MiscFedDL3=d.DLCode)
    	begin
    	select @errmsg='Federal info exists for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRFI e with (nolock) join deleted d on e.PRCo=d.PRCo and e.MiscFedDL4=d.DLCode)
    	begin
    	select @errmsg='Federal info exists for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRFD e with (nolock) join deleted d on e.PRCo=d.PRCo and e.DLCode=d.DLCode)
    	begin
    	select @errmsg='Federal detail exists for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRGB e with (nolock) join deleted d on e.PRCo=d.PRCo and e.LiabCode=d.DLCode)
    	begin
    	select @errmsg='Group liability(s) exist for this Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRGI e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDCode=d.DLCode where e.EDType<>'E')
    	begin
    	select @errmsg='Garnishment group item(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRID e with (nolock) join deleted d on e.PRCo=d.PRCo and e.DLCode=d.DLCode)
    	begin
    	select @errmsg='Insurance code detail(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRSI e with (nolock)join deleted d on e.PRCo=d.PRCo and e.TaxDedn=d.DLCode)
    	begin
    	select @errmsg='State info exists for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRSD e with (nolock) join deleted d on e.PRCo=d.PRCo and e.DLCode=d.DLCode)
    	begin
    	select @errmsg='State detail(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRED e with (nolock) join deleted d on e.PRCo=d.PRCo and e.DLCode=d.DLCode)
    	begin
    	select @errmsg='Employee dedn/liab record(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPREA e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.DLCode where e.EDLType<>'E') --issue 16528 filter out EDLType 'E' entries
    	begin
    	select @errmsg='Employee accumulations exist for this Dedn/Liab code'
    	goto error
    	end
   
    if exists(select * from dbo.bPRCA e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.DLCode where e.EDLType<>'E')
    	begin
    	select @errmsg='Craft accumulation record(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRCI e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.DLCode where e.EDLType<>'E')
    	begin
    	select @errmsg='Craft item(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRCX e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.DLCode where e.EDLType<>'E')
    	begin
    	select @errmsg='Craft accumulation rate detail(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRCD e with (nolock) join deleted d on e.PRCo=d.PRCo and e.DLCode=d.DLCode)
    	begin
    	select @errmsg='Class dedn/liab record(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRCB e with (nolock) join deleted d on e.PRCo=d.PRCo and e.ELCode=d.DLCode where e.ELType<>'E')
    	begin
    	select @errmsg='Craft capped basis record(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRTD e with (nolock) join deleted d on e.PRCo=d.PRCo and e.DLCode=d.DLCode)
    	begin
    	select @errmsg='Template dedn/liab record(s) exist for this Dedn/Liab code'
    	goto error
    	end
   if exists(select * from dbo.bPRTI e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.DLCode where e.EDLType<>'E')
    	begin
    	select @errmsg='Template item(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRTR e with (nolock) join deleted d on e.PRCo=d.PRCo and e.DLCode=d.DLCode)
    	begin
    	select @errmsg='Template reciprocal item(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRTL e with (nolock) join deleted d on e.PRCo=d.PRCo and e.LiabCode=d.DLCode)
    	begin
    	select @errmsg='Timecard liability record(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRDT e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.DLCode where e.EDLType<>'E')
    	begin
    	select @errmsg='Pay sequence total record(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRIA e with (nolock) join deleted d on e.PRCo=d.PRCo and e.DLCode=d.DLCode)
    	begin
    	select @errmsg='Insurance accumulation record(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRCS e with (nolock) join deleted d on e.PRCo=d.PRCo and e.ELCode=d.DLCode where e.ELType<>'E')
    	begin
    	select @errmsg='Craft Capped Sequence detail(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRWH e with (nolock) join deleted d on e.PRCo=d.PRCo and e.Misc1EDLCode=d.DLCode where e.Misc1EDLType<>'E')
    	begin
    	select @errmsg='W2 Header detail(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRWH e with (nolock) join deleted d on e.PRCo=d.PRCo and e.Misc2EDLCode=d.DLCode where e.Misc2EDLType<>'E')
    	begin
    	select @errmsg='W2 Header detail(s) exist for this Dedn/Liab code'
    	goto error
    	end
    --#26938
    if exists(select * from dbo.bPRWH e with (nolock) join deleted d on e.PRCo=d.PRCo and e.Misc3EDLCode=d.DLCode where e.Misc3EDLType<>'E')
    	begin
    	select @errmsg='W2 Header detail(s) exist for this Dedn/Liab code'
    	goto error
    	end
    --#26938
    if exists(select * from dbo.bPRWH e with (nolock) join deleted d on e.PRCo=d.PRCo and e.Misc4EDLCode=d.DLCode where e.Misc4EDLType<>'E')
    	begin
    	select @errmsg='W2 Header detail(s) exist for this Dedn/Liab code'
    	goto error
    	end
    	
    -- B-10990 PR Arrears/Payback table	
    IF EXISTS
			(
				SELECT * 
				FROM dbo.vPRArrears a
				JOIN deleted d ON a.PRCo=d.PRCo AND a.DLCode=d.DLCode AND a.EDLType=d.DLType
			)
	BEGIN
		SELECT @errmsg='Arrears/payback history exists for this Dedn/Liab code'
    	GOTO error
	END
    	
    -----------------------
    ---- D-02774 START ----
    -----------------------
    ----if exists(select * from dbo.bPRWM e with (nolock) join deleted d on e.PRCo=d.PRCo and e.Misc1EDLCode=d.DLCode where e.Misc1EDLType<>'E')
    ----	begin
    ----	select @errmsg='W2 State Misc item detail(s) exist for this Dedn/Liab code'
    ----	goto error
    ----	end
    ----if exists(select * from dbo.bPRWM e with (nolock) join deleted d on e.PRCo=d.PRCo and e.Misc2EDLCode=d.DLCode where e.Misc2EDLType<>'E')
    ----	begin
    ----	select @errmsg='W2 State Misc item detail(s) exist for this Dedn/Liab code'
    ----	goto error
    ----	end
    ------#26938
    ----if exists(select * from dbo.bPRWM e with (nolock) join deleted d on e.PRCo=d.PRCo and e.Misc3EDLCode=d.DLCode where e.Misc3EDLType<>'E')
    ----	begin
    ----	select @errmsg='W2 State Misc item detail(s) exist for this Dedn/Liab code'
    ----	goto error
    ----	end
    ------#26938
    ----if exists(select * from dbo.bPRWM e with (nolock) join deleted d on e.PRCo=d.PRCo and e.Misc4EDLCode=d.DLCode where e.Misc4EDLType<>'E')
    ----	begin
    ----	select @errmsg='W2 State Misc item detail(s) exist for this Dedn/Liab code'
    ----	goto error
    ----	end
    ---------------------
    ---- D-02774 END ----
    ---------------------
    
    if exists(select * from dbo.bPRWC e with (nolock) join deleted d on e.PRCo=d.PRCo and e.EDLCode=d.DLCode where e.EDLType<>'E')
    	begin
    	select @errmsg='W2 Report Item Code detail(s) exist for this Dedn/Liab code'
    	goto error
    	end
    if exists(select * from dbo.bPRWT e with (nolock) join deleted d on e.PRCo=d.PRCo and e.DednCode=d.DLCode)
    	begin
    	select @errmsg='W2 State/Local Init detail(s) exist for this Dedn/Liab code'
    	goto error
    	end
   
    --if (select Active from dbo.DDMO with (nolock) where Mod = 'HR') = 1 <-issue 28941 commented out the Active HR check
   	--begin
   		--if exists(select h.HRCo, h.HRRef, h.BenefitCode, d.DLCode
   		if exists(select top 1 1 --issue 28941 replaces commented out line above - don't need to read individual fields ... also removed the code to check for active HR - this check should be sufficient
   		from deleted d join dbo.HRBL h with (nolock) on d.PRCo = h.HRCo --issue 28941 commented out the following code because it is in the where clause already -> and d.DLCode = h.DLCode
   		where h.DLCode = d.DLCode)
   			begin
   				select @errmsg = 'DL Code exists in HR'
   				goto error
   			end
   	--end
   
   
    set nocount on
    INSERT INTO dbo.bHQMA
        (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
            SELECT 'bPRDL', 'DLCode:' + convert(varchar(10),d.DLCode),
              d.PRCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
            FROM deleted d
    	JOIN dbo.bPRCO a with (nolock) ON d.PRCo=a.PRCo
            where a.AuditDLs='Y'
    return
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Deductions and Liabilities!'
        	RAISERROR(@errmsg, 11, -1);
        	rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   CREATE       trigger [dbo].[btPRDLi] on [dbo].[bPRDL] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: kb 10/22/99
    * 	Modified: EN 4/4/00 - validate Earn Code
    *            EN 4/12/00 - fixed PayType and Frequency validations which were not fully allowing for null
    *            JRE 8/30/00 - fixed Limit Period Problem if null
    *            JRE 9/05/00 - fixed GarnGroup validation to handle null correctly
    *			GG 12/07/00 - removed EarnCode
    *          MV 5/2/01 - validate that Limit Period is not null when Limit = S or C
    *			GG 01/28/02 - added FedType validation
    *			GG 07/18/02 - #16595 - added columns for W-2 info
    *			EN 3/21/03 - issue 11030 added 'R' to list of possible Limit Methods
    *			EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	This trigger validates insertion in bPRDL (PR Deductions/Liabilities)
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
   /* validate DL Type*/
   select @validcnt = count(*) from inserted i where i.DLType = 'D' or i.DLType = 'L'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'DL Type must be ''D'' for Deductions or ''L'' for Liabilities '
   	goto error
   	end
   
   /*validate Liability Type*/
   select @validcnt2 = count(*) from inserted i where i.DLType = 'L'
   if @validcnt2<>0
   	begin
   	select @validcnt = count(*) from inserted i where i.DLType = 'L' and LiabType is not null
   	if @validcnt<>@validcnt2
   		begin
   		select @errmsg = 'Liability Type is missing, it is required for Liability records '
   		goto error
   		end
   	else
   		begin
   		select @validcnt = count(*) from dbo.bHQLT h with (nolock) join inserted i on h.LiabType = i.LiabType
               where DLType = 'L'
   		if @validcnt <> @validcnt2
   			begin
   			select @errmsg = 'Invalid Liability Type '
   			goto error
   			end
   		end
   	end
   -- check limit basis
   select @validcnt = count(*) from inserted i where i.DLType = 'D' and i.LimitBasis = 'R'
   if @validcnt > 0
   	begin
   	select @errmsg = 'Rate of Earnings Limit is only valid on a Liability '
   	goto error
   	end
   /*validate Method*/
   select @validcnt = count(*) from inserted i where i.Method in ('A','D','F','G','H','N','S','DN','V','R')
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Method must be ''A'', ''D'', ''F'', ''G'', ''H'', ''N'', ''S'', ''DN'', ''V'' or ''R'' ' + convert(varchar(10),@validcnt)
   	goto error
   	end
   
   /*validate Routine*/
   select @validcnt2 = count(*) from inserted i where i.Routine is not null
   if @validcnt2<>0
   	begin
   	select @validcnt = count(*) from dbo.bPRRM p with (nolock) join inserted i on p.PRCo = i.PRCo and
   	  p.Routine = i.Routine where i.Routine is not null
   	if @validcnt <> @validcnt2
   		begin
   		select @errmsg = 'Invalid Routine '
   		goto error
   		end
   	end
   
   /*validate Deduction Code for 'DN' - Rate of Deduction Methods*/
   select @validcnt2 = count(*) from inserted i where i.DednCode is not null
   if @validcnt2<>0
   	begin
   	select @validcnt = count(*) from dbo.bPRDL p with (nolock) join inserted i on p.PRCo = i.PRCo and p.DLCode = i.DLCode
     	  where i.DednCode is not null
   	if @validcnt <> @validcnt2
   		begin
   		select @errmsg = 'Invalid Deduction Code for records with method of ''DN'' '
   		goto error
   		end
   	end
   
   
   /*validate Garnishement Group if entered*/
   select @validcnt2 = count(*) from inserted i where GarnGroup is null
   if @validcnt2<>@numrows
      	begin
      	select @validcnt = count(*) from dbo.bPRGG p with (nolock) join inserted i on p.PRCo = i.PRCo and p.GarnGroup = i.GarnGroup
      	  where i.GarnGroup is not null
      	if @validcnt + @validcnt2 <> @numrows
      		begin
      		select @errmsg = 'Invalid Garnishment Group'
      		goto error
      		end
      	end
   
   /*validate Limit Basis*/
   select @validcnt = count(*) from inserted i where LimitBasis = 'C' or LimitBasis= 'N' or 
   	LimitBasis='S' or LimitBasis='R'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Limit Basis must be ''C'', ''N'', ''S'' or ''R'' '
   	goto error
   	end
   
   /*validate required Limit Period*/
   select @validcnt = count (*) from inserted i where LimitBasis in ('C','S') and LimitPeriod is null
   if @validcnt <> 0
       begin
       select @errmsg = 'Limit Period is missing, it is required for Limit Basis ''C'' or ''S'' '
       goto error
       end
   
   /*validate Limit Period*/
   select @validcnt = count(*) from inserted i
   where LimitPeriod is null or LimitPeriod in ('P','M','Q','A','L')
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Limit Period must be ''P'', ''M'', ''Q'', ''A'' or ''L'' '
   	goto error
   	end
   
   /*validate Vendor Group*/
   select @validcnt2 = count(*) from inserted i where VendorGroup is not null
   if @validcnt2<>0
   	begin
   	select @validcnt = count(*) from dbo.bHQGP p with (nolock) join inserted i on p.Grp = i.VendorGroup where VendorGroup is not null
   	if @validcnt <> @validcnt2
   		begin
   		select @errmsg = 'Vendor Group is invalid '
   		goto error
   		end
   	end
   
   /*validate Vendor */
   select @validcnt2 = count(*) from inserted i where Vendor is not null
   if @validcnt2 <> 0
   	begin
   	select @validcnt = count(*) from dbo.bAPVM p with (nolock) join inserted i on p.VendorGroup = i.VendorGroup and
   	  p.Vendor = i.Vendor where i.Vendor is not null
   	if @validcnt <> @validcnt2
   		begin
   		select @errmsg = 'Vendor is invalid '
   		goto error
   		end
   	end
   
   /*validate PayType*/
   select @validcnt2 = count(*) from inserted i where PayType is not null
   if @validcnt2 <> 0
   	begin
   	select @validcnt = count(*) from inserted i join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo join bAPPT p on a.APCo = p.APCo
   	  and i.PayType = p.PayType where i.PayType is not null
   	if @validcnt <> @validcnt2
   		begin
   		select @errmsg = 'Invalid Payable Type '
   		goto error
   		end
   	end
   
   select @validcnt2 = count(*) from inserted i where Frequency is not null
   if @validcnt2 <> 0
   	begin
   	select @validcnt = count(*) from dbo.bHQFC h with (nolock) join inserted i on h.Frequency = i.Frequency where i.Frequency is not null
   	if @validcnt <> @validcnt2
   		begin
   		select @errmsg = 'Invalid Frequency '
   		goto error
   		end
   	end
   
   select @validcnt = count(*) from inserted i join dbo.HQCO h with (nolock) on i.GLCo = h.HQCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid GL Company '
   	goto error
   	end
   
   select @validcnt = count(*) from inserted i join dbo.GLAC g with (nolock) on i.GLCo = g.GLCo and i.GLAcct = g.GLAcct where g.SubType is null
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid GL Account '
   	goto error
   	end
   
   /*validate Calculation category*/
   select @validcnt = count(*) from inserted
   where CalcCategory in ('F','S','L','I','C','E','A')
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Calculation category must be ''F'', ''S'', ''L'', ''I'',''C'',''E'' or ''A'' '
   	goto error
   	end
   
   if exists(select 1 from inserted where CalcCategory = 'F' and (FedType is null or FedType not in ('1','2','3','4')))
   	begin
   	select @errmsg = 'Federal Type must be ''1'',''2'',''3'', or ''4'' on all Federal D/Ls'
   	goto error
   	end
   if exists(select 1 from inserted where CalcCategory <> 'F' and FedType is not null)
   	begin
   	select @errmsg = 'Federal Type is only allowed on Federal D/Ls'
   	goto error
   	end
   
   --validate W-2 info
   if exists(select 1 from inserted where IncldW2 = 'Y' and (DLType = 'L' or CalcCategory not in ('E','A')))
   	begin
   	select @errmsg = 'To be included on W-2s this code must be an Employee or Any based deduction'
   	goto error
   	end
   if exists(select 1 from inserted where IncldW2 = 'Y' and (W2State is null or W2Local is null))
   	begin
   	select @errmsg = 'Both State and Local values are required when included for W-2s'
   	goto error
   	end
   if exists(select 1 from inserted where IncldW2 = 'Y' and TaxType not in ('C','D','E','F'))
   	begin
   	select @errmsg = 'Invalid Tax Type, must be ''C'',''D'',''E'', or ''F'''
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRDL',  'DLCode: ' + convert(char(10), i.DLCode), i.PRCo, 'A',
   	 null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.PRCO a with (nolock) on i.PRCo=a.PRCo
        where a.AuditDLs='Y'
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Deductions and Liabilities!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

   
   CREATE            trigger [dbo].[btPRDLu] on [dbo].[bPRDL] for UPDATE as
    

/*-----------------------------------------------------------------
* Created: kb 10/22/99
* Modified: EN 4/4/00 - validate Earn Code
*            EN 4/12/00 - fixed PayType and Frequency validations
*			GG 12/7/00 - removed EarnCode
*			MV 5/2/01 - validate that the Limit Period is not null when Limit = C or S
*			GG 01/28/02 - added FedType validation
*			GG 05/24/02 - #17478 - reject DLType change in code in use
*			GG 07/18/02 - #16595 - added columns for W-2 info 
*			EN 3/21/03 - issue 11030 added 'R' to list of possible Limit Methods and added to HQMA audit checks
*			EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
*			mh 1/28/05 - issue 25515.  Throw error if type changes and code is in use elsewhere.  See 
*						comment tags below.
*			EN 9/07/05 - issue 26938  handle validation for Misc lines 3 & 4
*			LS 10/21/2010 -#140541 Add Auditing to PreTax and PreTaxGroup Fields
*			EN 12/14/2010 #127269 include ATOCategory for grouping Dedn/Liab Codes (Australia)
*			EN 1/27/2011 #139033 added validation for new SchemeID field
*			CHS 10/27/2011 - TK-09425 added PreTaxCatchUpYN
*			Dan So 07/24/2012 - D-02774 - commented out references to PRWM
*			MAV 08/01/2012 - TK-16684 added Arrears/Payback fields 
*
*	This trigger validates updates to bPRDL (PR Deductions/Liabilities)
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------
    
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
    
    select @numrows = @@rowcount
    
    if @numrows = 0 return
    
    set nocount on
    
    /* validate PR Company */
    if update(PRCo)
    	begin
    	select @errmsg = 'PR Company cannot be updated, it is a key value '
    	goto error
    	end
    if update(DLCode)
    	begin
    	select @errmsg = 'DLCode cannot be updated, it is a key value '
    	goto error
    	end
    
     /* validate DL Type*/
     if update(DLType)
     	begin
     	select @validcnt = count(*) from inserted i where i.DLType in ('D','L')
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'DL Type must be ''D'' for Deductions or ''L'' for Liabilities '
     		goto error
     		end
     	-- check is already used in Employee Accums
     	if exists(select 1 from inserted i join dbo.bPREA a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.EDLCode
     				where a.EDLType in ('D','L'))
     		begin
     		select @errmsg = 'In use in Employee Accumulations, cannot change DL Type '
     		goto error
     		end
     	-- check if used in Employee Pay Seq Detail
     	if exists(select 1 from inserted i join dbo.bPRDT a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.EDLCode
     				where a.EDLType in ('D','L'))
     		begin
     		select @errmsg = 'In use in Employee Pay Sequence Detail, cannot change DL Type '
     		goto error
     		end
   
   --begin 25515
   	--PRCI
   
     	if exists(select 1 from inserted i join dbo.bPRCI a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.EDLCode
     				where a.EDLType in ('D','L'))
     		begin
     		select @errmsg = 'In use in Craft Master, cannot change DL Type '
     		goto error
     		end
   
   
   	--PRTI
   
     	if exists(select 1 from inserted i join dbo.bPRTI a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.EDLCode
     				where a.EDLType in ('D','L'))
     		begin
     		select @errmsg = 'In use in Craft Template, cannot change DL Type '
     		goto error
     		end
   
   	--PRGB
   
     	if exists(select 1 from inserted i join dbo.bPRGB a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.LiabCode
   	join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType = 'L')
     		begin
     		select @errmsg = 'In use in Group Master, cannot change DL Type '
     		goto error
     		end
   
   	--PRCB
   
     	if exists(select 1 from inserted i join dbo.bPRCB a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.ELCode
   				join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType
   				where a.ELType = 'L'
     				)
     		begin
     		select @errmsg = 'In use in Craft Master, cannot change DL Type '
     		goto error
     		end
   
   	--PRCS
   
     	if exists(select 1 from inserted i join dbo.bPRCS a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.ELCode and a.ELType = 'L' 
   				join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType
   				where a.ELType = 'L')
     		begin
     		select @errmsg = 'In use in Craft Master, cannot change DL Type '
     		goto error
     		end
   
   	--PRCD
     	if exists(select 1 from inserted i join dbo.bPRCD a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.DLCode 
   				join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType)
     		begin
     		select @errmsg = 'In use in Craft Class, cannot change DL Type '
     		goto error
     		end
   
   
   	--PRTD
     	if exists(select 1 from inserted i join dbo.bPRTD a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.DLCode 
   				join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType)
     		begin
     		select @errmsg = 'In use in Craft Class Template, cannot change DL Type '
     		goto error
     		end
   
   	--PRGI
     	if exists(select 1 from inserted i join dbo.bPRGI a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.EDCode
   				join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType
   				where a.EDType = 'D')
     		begin
     		select @errmsg = 'In use in Garnish Group, cannot change DL Type '
     		goto error
     		end
   
   
   	--PRCX
   	if exists(select 1 from inserted i join dbo.bPRCX a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.EDLCode
   				join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType
   				where a.EDLType in ('D','L'))
   	begin
   	select @errmsg = 'In use in PRCX, cannot change DL Type '
   	goto error
   	end
   
	-------------------------
	---- D-02774 - START ----
	-------------------------
   	------PRWM
   	----if exists(select 1 from inserted i join dbo.bPRWM a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.Misc1EDLCode
   	----			join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType
   	----			where a.Misc1EDLType in ('D','L'))
   	----begin
   	----select @errmsg = 'In use in PRW2 Header, cannot change DL Type '
   	----goto error
   	----end
   
   	----if exists(select 1 from inserted i join dbo.bPRWM a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.Misc2EDLCode
   	----			join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType
   	----			where a.Misc2EDLType in ('D','L'))
   	----begin
   	----select @errmsg = 'In use in PRW2 Header, cannot change DL Type '
   	----goto error
   	----end
   
   	------#26938
   	----if exists(select 1 from inserted i join dbo.bPRWM a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.Misc3EDLCode
   	----			join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType
   	----			where a.Misc3EDLType in ('D','L'))
   	----begin
   	----select @errmsg = 'In use in PRW2 Header, cannot change DL Type '
   	----goto error
   	----end
   
   	------#26938
   	----if exists(select 1 from inserted i join dbo.bPRWM a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.Misc4EDLCode
   	----			join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType
   	----			where a.Misc4EDLType in ('D','L'))
   	----begin
   	----select @errmsg = 'In use in PRW2 Header, cannot change DL Type '
   	----goto error
   	----end
   	-----------------------
	---- D-02774 - END ----
	-----------------------
	
   	--PRWH
   
   	if exists(select 1 from inserted i join dbo.bPRWH a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.Misc1EDLCode
   				join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType
   				where a.Misc1EDLType in ('D','L'))
   	begin
   	select @errmsg = 'In use in PRWH, cannot change DL Type '
   	goto error
   	end
   	
   	if exists(select 1 from inserted i join dbo.bPRWH a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.Misc2EDLCode
   				join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType
   				where a.Misc2EDLType in ('D','L'))
   	begin
   	select @errmsg = 'In use in PRWH, cannot change DL Type '
   	goto error
   	end
   
   	--#26938
   	if exists(select 1 from inserted i join dbo.bPRWH a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.Misc3EDLCode
   				join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType
   				where a.Misc3EDLType in ('D','L'))
   	begin
   	select @errmsg = 'In use in PRWH, cannot change DL Type '
   	goto error
   	end
   	
   	--#26938
   	if exists(select 1 from inserted i join dbo.bPRWH a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.Misc4EDLCode
   				join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType
   				where a.Misc4EDLType in ('D','L'))
   	begin
   	select @errmsg = 'In use in PRWH, cannot change DL Type '
   	goto error
   	end
   
   	--PRWC
   
   	if exists(select 1 from inserted i join dbo.bPRWC a with (nolock) on i.PRCo = a.PRCo and i.DLCode = a.EDLCode
   				join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode and d.DLType <> i.DLType
   				where a.EDLType in ('D', 'L'))
   	begin
   	select @errmsg = 'In use in W2 Init Details, cannot change DL Type '
   	goto error
   	end
   
   	--HRBD
   
   	if exists(select 1 from inserted i join dbo.bHRCO a with (nolock) on 
   		i.PRCo = a.PRCo Join dbo.bHRBD d on a.HRCo = d.Co where i.DLCode = d.EDLCode
   		and d.EDLType in ('D', 'L'))
   
     		begin
     		select @errmsg = 'In use in HR Resource Benefits, cannot change DL Type '
     		goto error
     		end
   
   	--HRBI
   
   	if exists(select 1 from inserted i join dbo.bHRCO a with (nolock) on 
   		i.PRCo = a.PRCo Join dbo.bHRBI d on a.HRCo = d.HRCo where i.DLCode = d.EDLCode
   		and d.EDLType in ('D', 'L'))
   
     		begin
     		select @errmsg = 'In use in HR Benefit Codes, cannot change DL Type '
     		goto error
     		end
   
   	--HRBL
   	if exists(select 1 from inserted i join dbo.bHRCO a with (nolock) on 
   		i.PRCo = a.PRCo Join dbo.bHRBL d on a.HRCo = d.HRCo where i.DLCode = d.DLCode
   		and d.DLType in ('D', 'L'))
   
     		begin
     		select @errmsg = 'In use in HR Benefit Codes, cannot change DL Type '
     		goto error
     		end
   --end 25515
   
   	-- check limit basis
   	select @validcnt = count(*) from inserted i where i.DLType = 'D' and i.LimitBasis = 'R'
   	if @validcnt > 0
   		begin
   		select @errmsg = 'Rate of Earnings Limit is only valid on a Liability '
   		goto error
   		end
     	end
     
     /*validate Liability Type*/
     if update(LiabType)
     	begin
     	select @validcnt2 = count(*) from inserted i where i.DLType = 'L'
     	if @validcnt2<>0
     		begin
     		select @validcnt = count(*) from inserted i where i.DLType = 'L' and LiabType is not null
     		if @validcnt<>@validcnt2
     			begin
     			select @errmsg = 'Liability Type is missing, it is required for Liability records '
     			goto error
     			end
     		else
     			begin
     			select @validcnt = count(*) from dbo.bHQLT h with (nolock) join inserted i on h.LiabType = i.LiabType where
     				DLType = 'L'
     			if @validcnt <> @validcnt2
     				begin
     				select @errmsg = 'Invalid Liability Type '
     				goto error
     				end
     			end
     		end
     	end
     
     /*validate Method*/
     if update(Method)
     	begin
     	select @validcnt = count(*) from inserted i where i.Method in ('A','D','F','G','H','N','S','DN','V','R')
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'Method must be ''A'', ''D'', ''F'', ''G'', ''H'', ''N'', ''S'', ''DN'', ''V'' or ''R'' '
     		goto error
     		end
     	end
     
     /*validate Routine*/
     if update(Routine)
     	begin
     	select @validcnt2 = count(*) from inserted i where i.Routine is not null
     	if @validcnt2<>0
     		begin
     		select @validcnt = count(*) from dbo.bPRRM p with (nolock) join inserted i on p.PRCo = i.PRCo and
     		  p.Routine = i.Routine where i.Routine is not null
     		if @validcnt <> @validcnt2
     			begin
     			select @errmsg = 'Invalid Routine '
     			goto error
     			end
     		end
     	end
     
     /*validate Deduction Code for 'DN' - Rate of Deduction Methods*/
     if update(DednCode)
     	begin
     	select @validcnt2 = count(*) from inserted i where i.DednCode is not null
     	if @validcnt2<>0
     		begin
     		select @validcnt = count(*) from dbo.bPRDL p with (nolock) join inserted i on p.PRCo = i.PRCo and p.DLCode = i.DLCode
   
       		  where i.DednCode is not null
     		if @validcnt <> @validcnt2
     			begin
     			select @errmsg = 'Invalid Deduction Code for records with method of ''DN'' '
     			goto error
     			end
     		end
     	end
     
     /*validate Garnishement Group if entered*/
     if update(GarnGroup)
     	begin
     	select @validcnt2 = count(*) from inserted i where GarnGroup is not null
     	if @validcnt2<>0
     		begin
   
     		select @validcnt = count(*) from dbo.bPRGG p with (nolock) join inserted i on p.PRCo = i.PRCo and p.GarnGroup = i.GarnGroup
     		  where i.GarnGroup is not null
     		if @validcnt <>@validcnt2
     			begin
     			select @errmsg = 'Invalid Garnishment Group '
     			goto error
     			end
     		end
     	end
     
     /*validate Limit Basis*/
     if update(LimitBasis)
     	begin
     	select @validcnt = count(*) from inserted i where LimitBasis = 'C' or LimitBasis= 'N' or
   		LimitBasis='S' or LimitBasis='R'
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'Limit Basis must be ''C'', ''N'', ''S'' or ''R'' '
     		goto error
     		end
     	end
     
     /*validate required Limit Period*/
     select @validcnt = count (*) from inserted i where LimitBasis in ('C','S') and LimitPeriod is null
     if @validcnt <> 0
         begin
         select @errmsg = 'Limit Period is missing, it is required for Limit Basis ''C'' or ''S'' '
         goto error
         end
     
     /*validate Limit Period*/
     if update(LimitPeriod)
     	begin
     	select @validcnt2 = count(*) from inserted i where LimitPeriod is not null
     	if @validcnt2 <>0
     		begin
     		select @validcnt = count(*) from inserted i where LimitPeriod = 'P' or LimitPeriod= 'M' or LimitPeriod='Q'  and LimitPeriod is not null
     		  or LimitPeriod='A' or LimitPeriod='L'
     		if @validcnt <> @numrows
     			begin
     			select @errmsg = 'Limit Period must be ''P'', ''M'', ''Q'', ''A'' or ''L'' '
     			goto error
     			end
     		end
     	end
     
     /*validate Vendor Group*/
     if update(VendorGroup)
     	begin
     	select @validcnt2 = count(*) from inserted i where VendorGroup is not null
     	if @validcnt2<>0
     		begin
     		select @validcnt = count(*) from dbo.bHQGP p with (nolock) join inserted i on p.Grp = i.VendorGroup where i.VendorGroup is not null
     		if @validcnt <> @validcnt2
     			begin
     			select @errmsg = 'Vendor Group is invalid '
     			goto error
     			end
     		end
     	end
     
     /*validate Vendor */
     if update(Vendor)
     	begin
     	select @validcnt2 = count(*) from inserted i where Vendor is not null
     	if @validcnt2 <> 0
     		begin
     		select @validcnt = count(*) from dbo.bAPVM p with (nolock) join inserted i on p.VendorGroup = i.VendorGroup and
     		  p.Vendor = i.Vendor where i.Vendor is not null
     		if @validcnt <> @validcnt2
     			begin
     			select @errmsg = 'Vendor is invalid '
     			goto error
     			end
     		end
     	end
     
     /*validate PayType*/
     if update(PayType)
     	begin
     	select @validcnt2 = count(*) from inserted i where PayType is not null
     	if @validcnt2 <> 0
     		begin
     		select @validcnt = count(*) from inserted i join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo join bAPPT p on a.APCo = p.APCo
     		  and i.PayType = p.PayType where i.PayType is not null
     		if @validcnt <> @validcnt2
     			begin
     			select @errmsg = 'Invalid Payable Type '
     			goto error
     			end
     		end
     	end
     
     /*validate Frequency*/
     if update(Frequency)
     	begin
     	select @validcnt2 = count(*) from inserted i where Frequency is not null
     	if @validcnt2 <> 0
     		begin
 
     		select @validcnt = count(*) from dbo.bHQFC h with (nolock) join inserted i on h.Frequency = i.Frequency where i.Frequency is not null
     		if @validcnt <> @validcnt2
     			begin
     			select @errmsg = 'Invalid Frequency '
     			goto error
     			end
     		end
     	end
     
     /*validate GLCo*/
     if update(GLCo)
     	begin
     	select @validcnt = count(*) from inserted i join dbo.HQCO h with (nolock) on i.GLCo = h.HQCo
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'Invalid GL Company '
     		goto error
     		end
     	end
     
     /*validate GLAcct*/
     if update(GLAcct)
     	begin
     	select @validcnt = count(*) from inserted i join dbo.GLAC g with (nolock) on i.GLCo = g.GLCo and i.GLAcct = g.GLAcct where g.SubType is null
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'Invalid GL Account '
     		goto error
     		end
     	end
     
     /*validate calculation category*/
     if update(CalcCategory) or update(FedType)
     	begin
     	select @validcnt = count(*) from inserted where CalcCategory in ('F','S','L','I','C','E','A')
     	if @validcnt <> @numrows
     		begin
     		select @errmsg = 'Calculation category must be ''F'', ''S'', ''L'', ''I'', ''C'', ''E'' or ''A'' '
     		goto error
     		end
     	if exists(select 1 from inserted where CalcCategory = 'F' and (FedType is null or FedType not in ('1','2','3','4')))
     		begin
     		select @errmsg = 'Federal Type must be ''1'',''2'',''3'', or ''4'' on all Federal D/Ls'
     		goto error
     		end
     	if exists(select 1 from inserted where CalcCategory <> 'F' and FedType is not null)
     		begin
     		select @errmsg = 'Federal Type is only allowed on Federal D/Ls'
     		goto error
     		end
     	end
     
    --validate W-2 info
    if update(CalcCategory) or update(DLType) or update(IncldW2)
    	begin
    	if exists(select 1 from inserted where IncldW2 = 'Y' and (DLType = 'L' or CalcCategory not in ('E','A')))
    		begin
    		select @errmsg = 'To be included on W-2s this code must be an Employee or Any based deduction'
    		goto error
    		end
    	end
    if update(W2State) or update(W2Local) or update(IncldW2)
    	begin
    	if exists(select 1 from inserted where IncldW2 = 'Y' and (W2State is null or W2Local is null))
    		begin
    		select @errmsg = 'Both State and Local values are required when included for W-2s'
    		goto error
    		end
    	end
    if update(TaxType) or update(IncldW2)
    	begin
    	if exists(select 1 from inserted where IncldW2 = 'Y' and TaxType not in ('C','D','E','F'))
    		begin
    		select @errmsg = 'Invalid Tax Type, must be ''C'',''D'',''E'', or ''F'''
    		goto error
    		end
    	end
     
    /* add HQ Master Audit entry */
    if exists (select * from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditDLs = 'Y')
     	begin
     	insert into dbo.bHQMA
     	select 'bPRDL', 'DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','Description',
         		d.Description, i.Description,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.Description,'') <> isnull(d.Description,'') and a.AuditDLs = 'Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','DLType',
     		d.DLType, i.DLType, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.DLType <> d.DLType and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','LiabType',
     		convert(varchar(6),d.LiabType), convert(varchar(6),i.LiabType), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.LiabType,0) <> isnull(d.LiabType,0) and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','Method',
     		d.Method, i.Method, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.Method <> d.Method and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C', 'Routine',
     		d.Routine, i.Routine, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.Routine,'') <> isnull(d.Routine,'') and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C', 'DednCode',
     		convert(varchar(6),d.DednCode), convert(varchar(6),i.DednCode), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.DednCode,0) <> isnull(d.DednCode,0) and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C', 'GarnGroup',
     		convert(varchar(6),d.GarnGroup), convert(varchar(6),i.GarnGroup), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.GarnGroup,0) <> isnull(d.GarnGroup,0) and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C', 'RateAmt1',
     		convert(varchar(30),d.RateAmt1), convert(varchar(30),i.RateAmt1), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.RateAmt1 <> d.RateAmt1 and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL', 'DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','RateAmt2',
     		convert(varchar(30),d.RateAmt2), convert(varchar(30),i.RateAmt2), getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.RateAmt2 <> d.RateAmt2 and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','SeqOneOnly',
     		d.SeqOneOnly, i.SeqOneOnly, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.SeqOneOnly <> d.SeqOneOnly and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','YTDCorrect',
     		d.YTDCorrect, i.YTDCorrect, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.YTDCorrect <> d.YTDCorrect and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','BonusOverride',
     		d.BonusOverride, i.BonusOverride, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.BonusOverride <> d.BonusOverride and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','BonusRate',
     		convert(varchar(30),d.BonusRate), convert(varchar(30),i.BonusRate),getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.BonusRate,0) <> isnull(d.BonusRate,0) and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','LimitBasis',
     		d.LimitBasis, i.LimitBasis, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.LimitBasis <> d.LimitBasis and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL', 'DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','LimitAmt',
     		convert(varchar(30),d.LimitAmt), convert(varchar(30),i.LimitAmt),getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.LimitAmt,0) <> isnull(d.LimitAmt,0) and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','LimitPeriod',
     		d.LimitPeriod, i.LimitPeriod,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.LimitPeriod,'') <> isnull(d.LimitPeriod,'') and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','LimitCorrect',
     		d.LimitCorrect, i.LimitCorrect,getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.LimitCorrect <> d.LimitCorrect and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','AutoAP',
     		d.AutoAP, i.AutoAP,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
        	join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
         	where i.AutoAP <> d.AutoAP and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','VendorGroup',
     		convert(varchar(10),d.VendorGroup), convert(varchar(10),i.VendorGroup),getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.VendorGroup <> d.VendorGroup and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','Vendor',
     		convert(varchar(10),d.Vendor), convert(varchar(10),i.Vendor),getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.Vendor,0) <> isnull(d.Vendor,0) and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','TransByEmployee',
     		d.TransByEmployee, i.TransByEmployee,getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.TransByEmployee,'') <> isnull(d.TransByEmployee,'') and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','PayType',
     		convert(varchar(10),d.PayType), convert(varchar(10),i.PayType),getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.PayType,0) <> isnull(d.PayType,0) and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','Frequency',
     		d.Frequency, i.Frequency, getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.Frequency,'') <> isnull(d.Frequency,'') and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','AccumSubjAmts',
     		d.AccumSubjAmts, i.AccumSubjAmts,getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.AccumSubjAmts <> d.AccumSubjAmts and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','SelectPurge',
     		d.SelectPurge, i.SelectPurge,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.SelectPurge<>d.SelectPurge and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','DetailOnCert',
     		d.DetOnCert, i.DetOnCert,getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.DetOnCert <> d.DetOnCert and a.AuditDLs='Y'
		
		INSERT INTO dbo.bHQMA
		SELECT 'bPRDL','DLCode: ' + CONVERT(varchar(10), i.DLCode), i.PRCo, 'C','PreTax',
				d.PreTax, i.PreTax, GETDATE(), SUSER_SNAME()
			FROM inserted i
			JOIN deleted d ON i.PRCo = d.PRCo AND i.DLCode = d.DLCode
			JOIN dbo.bPRCO a WITH (NOLOCK) on i.PRCo = a.PRCo
			WHERE i.PreTax <> d.PreTax AND a.AuditDLs='Y'
		
		INSERT INTO dbo.bHQMA
     	SELECT 'bPRDL','DLCode: ' + CONVERT(varchar(10), i.DLCode), i.PRCo, 'C','PreTaxGroup',
     		CONVERT(varchar(6),d.PreTaxGroup), CONVERT(varchar(6),i.PreTaxGroup), GETDATE(), SUSER_SNAME()
          FROM inserted i
          JOIN deleted d ON i.PRCo = d.PRCo AND i.DLCode = d.DLCode
          JOIN dbo.bPRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
          WHERE ISNULL(i.PreTaxGroup,0) <> ISNULL(d.PreTaxGroup,0) AND a.AuditDLs='Y'
		
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','GLCo',
     		convert(varchar(10),d.GLCo), convert(varchar(10),i.GLCo),getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.GLCo,'') <> isnull(d.GLCo,'') and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','GLAcct',
     		d.GLAcct, i.GLAcct,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.GLAcct,'') <> isnull(d.GLAcct,'') and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','CalcCategory',
     		d.CalcCategory, i.CalcCategory,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.CalcCategory <> d.CalcCategory and a.AuditDLs='Y'
    
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','FedType',
     		d.FedType, i.FedType,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.FedType,'') <> isnull(d.FedType,'') and a.AuditDLs='Y'
     
     	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','RndToDollar',
     		d.RndToDollar, i.RndToDollar,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.RndToDollar <> d.RndToDollar and a.AuditDLs='Y'
    
    	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','IncldW2',
     		d.IncldW2, i.IncldW2,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where i.IncldW2 <> d.IncldW2 and a.AuditDLs='Y'
   
    	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','W2State',
     		d.W2State, i.W2State,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.W2State,'') <> isnull(d.W2State,'') and a.AuditDLs='Y'
   
    	insert into dbo.bHQMA
     	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','W2Local',
     		d.W2Local, i.W2Local,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.W2Local,'') <> isnull(d.W2Local,'') and a.AuditDLs='Y'
   
   		insert into dbo.bHQMA
    	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','TaxType',
     		d.TaxType, i.TaxType,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.TaxType,'') <> isnull(d.TaxType,'') and a.AuditDLs='Y'
   
   		insert into dbo.bHQMA
    	select 'bPRDL','DLCode: ' + convert(varchar(10),i.DLCode), i.PRCo, 'C','LimitRate',
     		d.LimitRate, i.LimitRate,	getdate(), SUSER_SNAME()
          from inserted i
          join deleted d on i.PRCo = d.PRCo and i.DLCode = d.DLCode
          join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
          where isnull(i.LimitRate,-1) <> isnull(d.LimitRate,-1) and a.AuditDLs='Y'
 
		INSERT INTO dbo.bHQMA
		SELECT 'bPRDL', 'DLCode: ' + CONVERT(VARCHAR(10),i.DLCode), i.PRCo, 'C','ATOCategory',
     			d.ATOCategory, i.ATOCategory,	GETDATE(), SUSER_SNAME() 
		FROM inserted i
		JOIN deleted d ON i.PRCo = d.PRCo AND i.DLCode = d.DLCode
		JOIN dbo.bPRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
		WHERE ISNULL(i.ATOCategory,'') <> ISNULL(d.ATOCategory,'') AND a.AuditDLs = 'Y'
    
 		INSERT INTO dbo.bHQMA
 		SELECT 'bPRDL',
			   'DLCode: ' + CONVERT(varchar(10),i.DLCode), 
			   i.PRCo, 
			   'C',
			   'Scheme',
 			   CONVERT(varchar(6),d.SchemeID), CONVERT(varchar(6),i.SchemeID),
			   GETDATE(), 
			   SUSER_SNAME()
		FROM inserted i
		JOIN deleted d ON i.PRCo = d.PRCo and i.DLCode = d.DLCode
		JOIN dbo.bPRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
		WHERE ISNULL(i.SchemeID,'') <> ISNULL(d.SchemeID,'') 
			  AND a.AuditDLs='Y'


 		INSERT INTO dbo.bHQMA
 		SELECT 'bPRDL',
			   'DLCode: ' + CONVERT(varchar(10),i.DLCode), 
			   i.PRCo, 
			   'C',
			   'PreTax',
 			   d.PreTax, 
 			   i.PreTax,
			   GETDATE(), 
			   SUSER_SNAME()
		FROM inserted i
		JOIN deleted d ON i.PRCo = d.PRCo and i.DLCode = d.DLCode
		JOIN dbo.bPRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
		WHERE ISNULL(i.PreTax,'') <> ISNULL(d.PreTax,'') 
			  AND a.AuditDLs='Y'			  
			  
 		INSERT INTO dbo.bHQMA
 		SELECT 'bPRDL',
			   'DLCode: ' + CONVERT(varchar(10),i.DLCode), 
			   i.PRCo, 
			   'C',
			   'PreTaxCatchUpYN',
 			   d.PreTaxCatchUpYN, 
 			   i.PreTaxCatchUpYN,
			   GETDATE(), 
			   SUSER_SNAME()
		FROM inserted i
		JOIN deleted d ON i.PRCo = d.PRCo and i.DLCode = d.DLCode
		JOIN dbo.bPRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
		WHERE ISNULL(i.PreTaxCatchUpYN,'') <> ISNULL(d.PreTaxCatchUpYN,'') 
			  AND a.AuditDLs='Y'	

		INSERT INTO dbo.bHQMA
 		SELECT 'bPRDL',
			   'DLCode: ' + CONVERT(varchar(10),i.DLCode), 
			   i.PRCo, 
			   'C',
			   'SubjToArrearsPayback',
 			   d.SubjToArrearsPayback, 
 			   i.SubjToArrearsPayback,
			   GETDATE(), 
			   SUSER_SNAME()
		FROM inserted i
		JOIN deleted d ON i.PRCo = d.PRCo and i.DLCode = d.DLCode
		JOIN dbo.bPRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
		WHERE ISNULL(i.SubjToArrearsPayback,'') <> ISNULL(d.SubjToArrearsPayback,'') 
			  AND a.AuditDLs='Y'

		INSERT INTO dbo.bHQMA
 		SELECT 'bPRDL',
			   'DLCode: ' + CONVERT(varchar(10),i.DLCode), 
			   i.PRCo, 
			   'C',
			   'RptArrearsThreshold',
 			   d.RptArrearsThreshold, 
 			   i.RptArrearsThreshold,
			   GETDATE(), 
			   SUSER_SNAME()
		FROM inserted i
		JOIN deleted d ON i.PRCo = d.PRCo and i.DLCode = d.DLCode
		JOIN dbo.bPRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
		WHERE ISNULL(i.RptArrearsThreshold,'') <> ISNULL(d.RptArrearsThreshold,'') 
			  AND a.AuditDLs='Y'

		INSERT INTO dbo.bHQMA
 		SELECT 'bPRDL',
			   'DLCode: ' + CONVERT(varchar(10),i.DLCode), 
			   i.PRCo, 
			   'C',
			   'ThresholdFactor',
 			   CONVERT(VARCHAR(30),d.ThresholdFactor), 
 			   CONVERT(VARCHAR(30),i.ThresholdFactor),
			   GETDATE(), 
			   SUSER_SNAME()
		FROM inserted i
		JOIN deleted d ON i.PRCo = d.PRCo and i.DLCode = d.DLCode
		JOIN dbo.bPRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
		WHERE ISNULL(i.ThresholdFactor,'') <> ISNULL(d.ThresholdFactor,'') 
			  AND a.AuditDLs='Y'

		INSERT INTO dbo.bHQMA
 		SELECT 'bPRDL',
			   'DLCode: ' + CONVERT(varchar(10),i.DLCode), 
			   i.PRCo, 
			   'C',
			   'ThresholdAmount',
 			   CONVERT(VARCHAR(30),d.ThresholdAmount), 
 			   CONVERT(VARCHAR(30),i.ThresholdAmount),
			   GETDATE(), 
			   SUSER_SNAME()
		FROM inserted i
		JOIN deleted d ON i.PRCo = d.PRCo and i.DLCode = d.DLCode
		JOIN dbo.bPRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
		WHERE ISNULL(i.ThresholdAmount,'') <> ISNULL(d.ThresholdAmount,'') 
			  AND a.AuditDLs='Y'
		
		INSERT INTO dbo.bHQMA
 		SELECT 'bPRDL',
			   'DLCode: ' + CONVERT(varchar(10),i.DLCode), 
			   i.PRCo, 
			   'C',
			   'PaybackPerPayPeriod',
 			   d.PaybackPerPayPeriod, 
 			   i.PaybackPerPayPeriod,
			   GETDATE(), 
			   SUSER_SNAME()
		FROM inserted i
		JOIN deleted d ON i.PRCo = d.PRCo and i.DLCode = d.DLCode
		JOIN dbo.bPRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
		WHERE ISNULL(i.PaybackPerPayPeriod,'') <> ISNULL(d.PaybackPerPayPeriod,'') 
			  AND a.AuditDLs='Y'
			  
		
		INSERT INTO dbo.bHQMA
 		SELECT 'bPRDL',
			   'DLCode: ' + CONVERT(varchar(10),i.DLCode), 
			   i.PRCo, 
			   'C',
			   'PaybackFactor',
 			   CONVERT(VARCHAR(30),d.PaybackFactor), 
 			   CONVERT(VARCHAR(30),i.PaybackFactor),
			   GETDATE(), 
			   SUSER_SNAME()
		FROM inserted i
		JOIN deleted d ON i.PRCo = d.PRCo and i.DLCode = d.DLCode
		JOIN dbo.bPRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
		WHERE ISNULL(i.PaybackFactor,'') <> ISNULL(d.PaybackFactor,'') 
			  AND a.AuditDLs='Y'	  
			
		INSERT INTO dbo.bHQMA
 		SELECT 'bPRDL',
			   'DLCode: ' + CONVERT(varchar(10),i.DLCode), 
			   i.PRCo, 
			   'C',
			   'PaybackAmount',
 			   CONVERT(VARCHAR(30),d.PaybackAmount), 
 			   CONVERT(VARCHAR(30),i.PaybackAmount),
			   GETDATE(), 
			   SUSER_SNAME()
		FROM inserted i
		JOIN deleted d ON i.PRCo = d.PRCo and i.DLCode = d.DLCode
		JOIN dbo.bPRCO a WITH (NOLOCK) ON i.PRCo = a.PRCo
		WHERE ISNULL(i.PaybackAmount,'') <> ISNULL(d.PaybackAmount,'') 
			  AND a.AuditDLs='Y'  
		
     END
     
     return
     error:
     	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Deductions and Liabilities!'
     	RAISERROR(@errmsg, 11, -1);
     	rollback transaction
     
     
     
    
    
    
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRDL] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRDL] ON [dbo].[bPRDL] ([PRCo], [DLCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPRDL] WITH NOCHECK ADD CONSTRAINT [FK_bPRDL_PRCo_PreTaxGroup] FOREIGN KEY ([PRCo], [PreTaxGroup]) REFERENCES [dbo].[bPRDeductionGroup] ([PRCo], [DednGroup])
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRDL].[RateAmt1]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRDL].[RateAmt2]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRDL].[SeqOneOnly]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRDL].[YTDCorrect]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRDL].[BonusOverride]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRDL].[LimitCorrect]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRDL].[AutoAP]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRDL].[TransByEmployee]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRDL].[AccumSubjAmts]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRDL].[SelectPurge]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRDL].[DetOnCert]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRDL].[RndToDollar]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRDL].[IncldW2]'
GO
