CREATE TABLE [dbo].[bHRBL]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NULL,
[BenefitCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[DependentSeq] [int] NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL,
[DLType] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL,
[EmplBasedYN] [dbo].[bYN] NOT NULL,
[Frequency] [dbo].[bFreq] NULL,
[ProcessSeq] [tinyint] NULL,
[OverrideCalc] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL,
[RateAmt] [dbo].[bUnitCost] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[OverrideGLAcct] [dbo].[bGLAcct] NULL,
[OverrideLimit] [dbo].[bDollar] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[APTransDesc] [dbo].[bDesc] NULL,
[ReadyYN] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[BenefitOption] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE     trigger [dbo].[btHRBLd] on [dbo].[bHRBL] for Delete
    as
    

	/**************************************************************
    * Created: 04/03/00 ae
    * Last Modified: mh 10/21/02 - Added update to HREH
    *					mh 3/4/03 - Issue 20486
    *					mh 3/15/04 - Issue 23061
	*					mh 10/28/2008 - Issue 127008
    *
    *
    **************************************************************/
    declare @errmsg varchar(255), @validcnt int, @validcnt2 int,@errno int, @numrows int, @nullcnt int, @rcode int
   
    declare @hrco bCompany, @hrref bHRRef, @seq int, @code varchar(10),
    @benefithistcode varchar(10), @dependseq int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
	/* Issue 20486 - no longer writing HREH record. mh*/
   
	/* Audit inserts */
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' HRRef: ' + 
	convert(varchar(6),isnull(d.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(d.BenefitCode,'')) + 
	' DependentSeq: ' + convert(varchar(6),isnull(d.DependentSeq,'')) + ' DLCode: ' + 
	convert(varchar(6),isnull(d.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(d.DLType,'')),
	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
	from deleted d
	join bHRCO e on d.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

    Return
    error:
    select @errmsg = (@errmsg + ' - cannot delete HRBL! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

   CREATE      trigger [dbo].[btHRBLi] on [dbo].[bHRBL] for INSERT as
    

	/*-----------------------------------------------------------------
     *   	Created by: ae  3/31/00
     * 	Modified by:	mh 10/4/01 Issue 14756
     * 			  mh 6/12/03 - Need to loop through all entries in inserted.
   	 *						Also tightened down trigger to look at EmplBasedYN, 
   	 *						ProcessSeq, Frequency, and OverrideCalc.
     *					mh 3/15/04 - 23061
	 *					mh 07/15/08 - 128988 - Corrected update of HREB.  Was using variables from
	 *					cursor loop but doing the update outside the loop.  Only one Resource was being
	 *					updated.  Removed the cursor and corrected the update.
	 *					mh 10/28/2008 - Issue 127008
	 *					AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
    @HRCo bCompany, @HRRef bHRRef, @BenefitCode varchar(10), @DependentSeq int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
	--#142350 - removing @hrco bCompany,@hrref bHRRef,@benefitcode varchar(10),@dependentseq int,
    DECLARE @emplbasedyn bYN,
			@procseq tinyint,
			@frequency bFreq,
			@opencurs tinyint,
			@overridecalc varchar(1)
   

	if exists(select 1 from inserted i where i.EmplBasedYN = 'N' and i.ProcessSeq is not null)
	begin
		select @errmsg = 'Processing Sequence must be null when Employee Based = ''N'''
		goto error
	end

	if exists(select 1 from inserted i where i.EmplBasedYN = 'N' and i.Frequency is not null)
	begin
		select @errmsg = 'Frequency must be null when Employee Based = ''N'''
		goto error	
	end

	if exists(select 1 from inserted i where i.EmplBasedYN = 'Y' and i.ProcessSeq is null)
	begin
		select @errmsg = 'Processing Sequence required when Employee Based = ''Y'''
		goto error
	end

	if exists(select 1 from inserted i where i.OverrideCalc is not null and i.OverrideCalc not in ('N', 'R', 'A'))
	begin
		select @errmsg = 'OverrideCalc must be N,R, or A'
		goto error
	end
   
	update bHREB set UpdatedYN = 'N'
	from bHREB h join inserted i on h.HRCo = i.HRCo and h.HRRef = i.HRRef and h.BenefitCode = i.BenefitCode
	and h.DependentSeq = i.DependentSeq and i.DependentSeq = 0
   
    /* Audit inserts */
	if not exists (select 1 from inserted i, bHRCO e
    	where i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y')

   	return

	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
   	select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
	convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) + 
	' DependentSeq: ' + convert(varchar(6),isnull(i.DependentSeq,'')) + ' DLCode: ' + 
	convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
    i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    from inserted i
	join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'	
   
	return
   
    error:
    	select @errmsg = @errmsg + ' - cannot insert into HRBL!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
CREATE         trigger [dbo].[btHRBLu] on [dbo].[bHRBL] for update as

/*--------------------------------------------------------------
*
*	Update trigger for HRBL
*	Created By:  ae 03/29/00
*	Modified by:	mh 6/2/03 - Getting overflow error.  See comment tags below
* 					mh 6/12/03 - Need to loop through all entries in inserted.
					Also tightened down trigger to look at EmplBasedYN, 
					ProcessSeq, Frequency, and OverrideCalc.

					mh 3/16/04 23061
					mh 4/29/05 - 28581 Corrected conversion of HRRef from varchar(5) to varchar(6)
*					mh 07/15/08 - 128988 - Corrected update of HREB.  Was using variables from
*					cursor loop but doing the update outside the loop.  Only one Resource was being
*					updated.  Removed the cursor and corrected the update.
*					mh 7/23/08 - added audit for BenefitOption
*					mh 10/28/2008 - Issue 127008
*
*--------------------------------------------------------------*/
    
      /***  basic declares for SQL Triggers ****/
	declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
	@errno tinyint, @audit bYN, @validcnt int, @nullcnt int, @rcode int

	select @numrows = @@rowcount
	if @numrows = 0 return

	set nocount on

	declare @hrco bCompany, @hrref bHRRef, @benefitcode varchar(10), @dependentseq int,
	@emplbasedyn bYN, @procseq tinyint, @frequency bFreq, @opencurs tinyint, @overridecalc varchar(1)

	if exists(select 1 from inserted i where i.EmplBasedYN = 'N' and i.ProcessSeq is not null)
	begin
		select @errmsg = 'Processing Sequence must be null when Employee Based = ''N'''
		goto error
	end

	if exists(select 1 from inserted i where i.EmplBasedYN = 'N' and i.Frequency is not null)
	begin
		select @errmsg = 'Frequency must be null when Employee Based = ''N'''
		goto error	
	end

	if exists(select 1 from inserted i where i.EmplBasedYN = 'Y' and i.ProcessSeq is null)
	begin
		select @errmsg = 'Processing Sequence required when Employee Based = ''Y'''
		goto error
	end

	if exists(select 1 from inserted i where i.OverrideCalc is not null and i.OverrideCalc not in ('N', 'R', 'A'))
	begin
		select @errmsg = 'OverrideCalc must be N,R, or A'
		goto error
	end
   
	update bHREB set UpdatedYN = 'N'
	from bHREB h join inserted i on h.HRCo = i.HRCo and h.HRRef = i.HRRef and h.BenefitCode = i.BenefitCode
	and h.DependentSeq = i.DependentSeq and i.DependentSeq = 0
    
    /*Insert HQMA records*/

	if update(EmplBasedYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		' DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' DLCode: ' + 
		convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
        i.HRCo, 'C','EmplBasedYN', convert(varchar(1),d.EmplBasedYN), Convert(varchar(1),i.EmplBasedYN),
    	getdate(), SUSER_SNAME()
    	from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.DLCode = d.DLCode and i.DLType = d.DLType and 
		i.EmplBasedYN <> d.EmplBasedYN
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(Frequency)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		' DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' DLCode: ' + 
		convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
        i.HRCo, 'C','Frequency', convert(varchar(10),d.Frequency), Convert(varchar(10),i.Frequency),
    	getdate(), SUSER_SNAME()
    	from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.DLCode = d.DLCode and i.DLType = d.DLType and 
		i.Frequency <> d.Frequency
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(ProcessSeq)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		' DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' DLCode: ' + 
		convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
        i.HRCo, 'C','ProcessSeq', convert(varchar(5),d.ProcessSeq), Convert(varchar(5),i.ProcessSeq),
    	getdate(), SUSER_SNAME()
    	from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.DLCode = d.DLCode and i.DLType = d.DLType and 
		i.ProcessSeq <> d.ProcessSeq
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(OverrideCalc)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
		select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		' DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' DLCode: ' + 
		convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
        i.HRCo, 'C','OverrideCalc', convert(varchar(1),d.OverrideCalc), Convert(varchar(1),i.OverrideCalc),
    	getdate(), SUSER_SNAME()
    	from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.DLCode = d.DLCode and i.DLType = d.DLType and 
		i.OverrideCalc <> d.OverrideCalc
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(RateAmt)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName) 
		select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		' DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' DLCode: ' + 
		convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
        i.HRCo, 'C','RateAmt', convert(varchar(17),d.RateAmt), Convert(varchar(17),i.RateAmt),
    	getdate(), SUSER_SNAME()
    	from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.DLCode = d.DLCode and i.DLType = d.DLType and 
		i.RateAmt <> d.RateAmt
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(GLCo)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName) 
		select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' 
		+ convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +
		' DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' DLCode: ' + 
		convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
        i.HRCo, 'C','GLCo', convert(varchar(5),d.GLCo), Convert(varchar(5),i.GLCo),
    	getdate(), SUSER_SNAME()
    	from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.DLCode = d.DLCode and i.DLType = d.DLType and 
		i.GLCo <> d.GLCo
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

--Duplicate? 
--    insert into bHQMA select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
--        ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) +
--        ' DLCode: ' + convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
--        i.HRCo, 'C','GLCo',
--        convert(varchar(20),d.GLCo), Convert(varchar(20),i.GLCo),
--    	getdate(), SUSER_SNAME()
--    	from inserted i, deleted d, HRCO e
--    	where i.HRCo = d.HRCo and i.HRRef = d.HRRef and
--              i.BenefitCode = d.BenefitCode and i.DependentSeq = d.DependentSeq
--              and i.DLCode = d.DLCode and i.DLType = d.DLType
--              and i.GLCo <> d.GLCo
--        and i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'
    
	if update(OverrideGLAcct)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
		select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		' DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' DLCode: ' + 
		convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
		i.HRCo, 'C','OverrideGLAcct', convert(varchar(20),d.OverrideGLAcct), Convert(varchar(20),i.OverrideGLAcct),
		getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.DLCode = d.DLCode and i.DLType = d.DLType and 
		i.OverrideGLAcct <> d.OverrideGLAcct
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'
    
	if update(OverrideLimit)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		' DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' DLCode: ' + 
		convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
        i.HRCo, 'C','OverrideLimit', convert(varchar(13),d.OverrideLimit), Convert(varchar(13),i.OverrideLimit),
    	getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.DLCode = d.DLCode and i.DLType = d.DLType and 
		i.OverrideLimit <> d.OverrideLimit
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(VendorGroup)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		' DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' DLCode: ' + 
		convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
        i.HRCo, 'C','VendorGroup', convert(varchar(6),d.VendorGroup), Convert(varchar(6),i.VendorGroup),
    	getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.DLCode = d.DLCode and i.DLType = d.DLType and 
		i.VendorGroup <> d.VendorGroup
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(Vendor)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		' DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' DLCode: ' + 
		convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
        i.HRCo, 'C','Vendor', convert(varchar(6),d.Vendor), Convert(varchar(6),i.Vendor),
    	getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.DLCode = d.DLCode and i.DLType = d.DLType 
		and i.Vendor <> d.Vendor
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(APTransDesc)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
		select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		' DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' DLCode: ' + 
		convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
        i.HRCo, 'C','APTransDesc', convert(varchar(30),d.APTransDesc), Convert(varchar(30),i.APTransDesc),
    	getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.DLCode = d.DLCode and i.DLType = d.DLType
		and i.APTransDesc <> d.APTransDesc
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(ReadyYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName) 
		select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		' DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' DLCode: ' + 
		convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
        i.HRCo, 'C','ReadyYN', convert(varchar(1),d.ReadyYN), Convert(varchar(1),i.ReadyYN),
    	getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.DLCode = d.DLCode and i.DLType = d.DLType
		and i.ReadyYN <> d.ReadyYN
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(BenefitOption)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName) 
		select 'bHRBL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		' DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' DLCode: ' + 
		convert(varchar(6),isnull(i.DLCode,'')) + ' DLType: ' + convert(varchar(1),isnull(i.DLType,'')),
        i.HRCo, 'C','BenefitOption', convert(varchar(1),d.BenefitOption), Convert(varchar(1),i.BenefitOption),
    	getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.DLCode = d.DLCode and i.DLType = d.DLType
		and i.BenefitOption <> d.BenefitOption
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

return
    
	error:
    
		if @opencurs = 1
		begin
			close update_curs
			deallocate update_curs
		end

		select @errmsg = @errmsg + ' - cannot update HRBL'
		RAISERROR(@errmsg, 11, -1);
		rollback transaction

 
GO
CREATE UNIQUE CLUSTERED INDEX [biHRBL] ON [dbo].[bHRBL] ([HRCo], [HRRef], [BenefitCode], [DependentSeq], [DLCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRBL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRBL].[EmplBasedYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRBL].[ReadyYN]'
GO
