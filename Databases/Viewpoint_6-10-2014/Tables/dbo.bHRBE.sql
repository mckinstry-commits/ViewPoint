CREATE TABLE [dbo].[bHRBE]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NULL,
[BenefitCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[DependentSeq] [int] NOT NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[AutoEarnSeq] [int] NOT NULL,
[Department] [dbo].[bDept] NULL,
[InsCode] [dbo].[bInsCode] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[RateAmount] [dbo].[bUnitCost] NOT NULL,
[AnnualLimit] [dbo].[bDollar] NOT NULL,
[Frequency] [dbo].[bFreq] NOT NULL,
[ReadyYN] [dbo].[bYN] NOT NULL,
[StdHours] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRBE_StdHours] DEFAULT ('N'),
[Hours] [dbo].[bHrs] NULL,
[PaySeq] [tinyint] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[BenefitOption] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 

   CREATE     trigger [dbo].[btHRBEd] on [dbo].[bHRBE] for Delete
    as
    

/**************************************************************
    * Created: 04/03/00 ae
    * Last Modified: mh 10/21/02 - Added update to HREH
    *					mh Issue 20486 3/4/03
    *					mh 3/15/04 23061
	*					mh 10/28/2008 - Issue 127008
    *
    *
    **************************************************************/
    declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, @rcode int
   
    declare @hrco bCompany, @hrref bHRRef, @seq int, @code varchar(10),
    @benefithistcode varchar(10), @dependseq int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   --Issue 20486 no longer writing record to HREH.  mh 3/4/03
    /*insert HREH record if flag set in HRCO*/
   
   /*
    select @hrco = min(d.HRCo), @benefithistcode = h.BenefitHistCode from deleted d, bHRCO h
      where d.HRCo = h.HRCo and h.BenefitHistYN = 'Y' group by h.BenefitHistCode
   
    while @hrco is not null
    	begin
    	select @hrref = min(HRRef) from deleted where HRCo = @hrco
    	while @hrref is not null
    		begin
    		select @dependseq= min(DependentSeq) from deleted where HRCo = @hrco and HRRef = @hrref
    		while @dependseq is not null
    			begin
    			select @seq = isnull(max(Seq),0)+1 from bHREH where HRCo = @hrco and
    				HRRef = @hrref
   
    			insert bHREH (HRCo, HRRef, Seq, Code, DateChanged)
    			values (@hrco, @hrref, @seq, @benefithistcode, getdate())
   
    			select @dependseq = min(DependentSeq) from deleted where HRCo = @hrco and HRRef = @hrref
    				and DependentSeq > @dependseq
    			if @@rowcount = 0 select @dependseq = null
    			end
    		select @hrref = min(HRRef) from deleted where HRCo = @hrco and HRRef > @hrref
    		if @@rowcount = 0 select @hrref = null
    		end
    	select @hrco = min(d.HRCo), @benefithistcode = h.BenefitHistCode from deleted d, bHRCO h
    	  where d.HRCo = h.HRCo and h.BenefitHistYN = 'Y' and d.HRCo > @hrco group by h.BenefitHistCode
    	if @@rowcount = 0 select @hrco = null
    	end
   end issue 20486 */
   
   /* Audit inserts */
   insert into bHQMA select 'bHRBE','HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' HRRef: ' + convert(varchar(6),d.HRRef) +
       ' BenefitCode: ' + convert(varchar(10),isnull(d.BenefitCode,'')) + ' DependentSeq: ' + convert(varchar(6),isnull(d.DependentSeq,'')) +
       ' EarnCode: ' + convert(varchar(6),isnull(d.EarnCode,'')),
    	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    	from deleted d,  bHRCO e
       where e.HRCo = d.HRCo and e.AuditBenefitsYN = 'Y'
   
    Return
    error:
    select @errmsg = (@errmsg + ' - cannot delete HRBE! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHRBEi    Script Date: 2/3/2003 8:52:55 AM ******/
   
   /****** Object:  Trigger dbo.btHRBEi    Script Date: 10/4/2001 2:45:36 PM ******/
   
   /****** Object:  Trigger dbo.btHRBEi    Script Date: 10/4/2001 1:04:19 PM ******/
   /****** Object:  Trigger dbo.btHRBEi******/
   CREATE     trigger [dbo].[btHRBEi] on [dbo].[bHRBE] for INSERT as
    

/*-----------------------------------------------------------------
     *   	Created by: ae  3/31/00
     * 	Modified by: mh 10/4/01 Issue 14756
     *					mh 3/15/04 23061
						mh 07/15/08 - 128988
	 *					mh 10/28/2008 - Issue 127008
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
    @HRCo bCompany, @HRRef bHRRef, @BenefitCode varchar(10), @DependentSeq int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   --MH 10/4/01 issue 14756 - Need to update the UpdateYN flag in bHREB to N 
   --on a change.
--   select @HRCo = i.HRCo, @HRRef = i.HRRef, @BenefitCode = i.BenefitCode, @DependentSeq = i.DependentSeq
--       from inserted i
--   
--   update bHREB set UpdatedYN = 'N' where HRCo = @HRCo and HRRef = @HRRef
--           and BenefitCode = @BenefitCode and DependentSeq = @DependentSeq
   
	update bHREB set UpdatedYN = 'N'
	from bHREB h join inserted i on h.HRCo = i.HRCo and h.HRRef = i.HRRef and h.BenefitCode = i.BenefitCode
	and h.DependentSeq = i.DependentSeq and i.DependentSeq = 0



    /* Audit inserts */
   if not exists (select * from inserted i, bHRCO e
    	where i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y')
    	return
   
   insert into bHQMA select 'bHRBE', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
       ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) + ' DependentSeq: ' + convert(varchar(6),isnull(i.DependentSeq,'')) +
       ' EarnCode: ' + convert(varchar(6),isnull(i.EarnCode,'')),
    	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    	from inserted i,  bHRCO e
       where e.HRCo = i.HRCo and e.AuditBenefitsYN = 'Y'
   
   return
   
    error:
    	select @errmsg = @errmsg + ' - cannot insert into HRBE!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btHRBEu] on [dbo].[bHRBE] for update as

	/*--------------------------------------------------------------
	*
    *  Update trigger for HRBE
    *  Created By:  ae 03/29/00
    *  Modified by: ae 04/04/00 added triggers.
    *					mh 8/12/03 - corrected arithmetic overflow error. Issue 22130
    *					mh 3/15/04 - 23061
    *					mh 4/29/05 - 28581
	*					mh 07/15/08 - 128988
	*					mh 7/31/08 - Added audit for benefit option
	*				    mh 10/18/2008 - 127008
    *
    *--------------------------------------------------------------*/
    
    /***  basic declares for SQL Triggers ****/
	declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
    @errno tinyint, @audit bYN, @validcnt int, @nullcnt int, @rcode int
    
	select @numrows = @@rowcount
	if @numrows = 0 return
	set nocount on
    
	update bHREB set UpdatedYN = 'N'
	from bHREB h join inserted i on h.HRCo = i.HRCo and h.HRRef = i.HRRef and h.BenefitCode = i.BenefitCode
	and h.DependentSeq = i.DependentSeq and i.DependentSeq = 0
        
    /*Insert HQMA records*/
	if update(AutoEarnSeq)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRBE', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' EarnCode: ' + 
		convert(varchar(6),isnull(i.EarnCode,'')), i.HRCo, 'C','AutoEarnSeq', convert(varchar(1),d.AutoEarnSeq), 
		Convert(varchar(1),i.AutoEarnSeq), getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.EarnCode = d.EarnCode and i.AutoEarnSeq <> d.AutoEarnSeq
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(Department)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)	
		select 'bHRBE', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +
		'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' EarnCode: ' + 
		convert(varchar(6),isnull(i.EarnCode,'')), i.HRCo, 'C','Department', convert(varchar(10),d.Department), 
		Convert(varchar(10),i.Department), getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.EarnCode = d.EarnCode and i.Department <> d.Department
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'
	    
	if update(InsCode)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)	
		select 'bHRBE', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' EarnCode: ' + 
		convert(varchar(6),isnull(i.EarnCode,'')), i.HRCo, 'C','InsCode', convert(varchar(10),d.InsCode), 
		Convert(varchar(10),i.InsCode), getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.EarnCode = d.EarnCode and i.InsCode <> d.InsCode
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(GLCo)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)	
		select 'bHRBE', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' EarnCode: ' + 
		convert(varchar(6),isnull(i.EarnCode,'')), i.HRCo, 'C','GLCo', convert(varchar(5),d.GLCo), 
		Convert(varchar(5),i.GLCo), getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.EarnCode = d.EarnCode and i.GLCo <> d.GLCo
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(RateAmount)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)	
		select 'bHRBE', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' EarnCode: ' + 
		convert(varchar(6),isnull(i.EarnCode,'')), i.HRCo, 'C','RateAmount', convert(varchar(17),d.RateAmount), 
		Convert(varchar(17),i.RateAmount), getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.EarnCode = d.EarnCode and i.RateAmount <> d.RateAmount
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(AnnualLimit)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)	   
		select 'bHRBE', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' EarnCode: ' + 
		convert(varchar(6),isnull(i.EarnCode,'')), i.HRCo, 'C','AnnualLimit', convert(varchar(13),d.AnnualLimit), 
		Convert(varchar(13),i.AnnualLimit), getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.EarnCode = d.EarnCode and i.AnnualLimit <> d.AnnualLimit
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(Frequency)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)   
		select 'bHRBE', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' EarnCode: ' + 
		convert(varchar(6),isnull(i.EarnCode,'')), i.HRCo, 'C','Frequency', convert(varchar(10),d.Frequency), 
		Convert(varchar(10),i.Frequency), getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.EarnCode = d.EarnCode and i.Frequency <> d.Frequency
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(ReadyYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName) 
		select 'bHRBE', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' EarnCode: ' + 
		convert(varchar(6),isnull(i.EarnCode,'')), i.HRCo, 'C','ReadyYN', convert(varchar(1),d.ReadyYN), 
		Convert(varchar(1),i.ReadyYN), getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.EarnCode = d.EarnCode and i.ReadyYN <> d.ReadyYN
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

	if update(BenefitOption)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRBE', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + 
		convert(varchar(6),isnull(i.HRRef,'')) + ' BenefitCode: ' + convert(varchar(10),isnull(i.BenefitCode,'')) +  
		'DependentSeq: ' + convert(varchar(5),isnull(i.DependentSeq,'')) + ' EarnCode: ' + 
		convert(varchar(6),isnull(i.EarnCode,'')), i.HRCo, 'C','BenefitOption', convert(varchar(1),d.BenefitOption), 
		Convert(varchar(1),i.BenefitOption), getdate(), SUSER_SNAME()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.BenefitCode = d.BenefitCode and 
		i.DependentSeq = d.DependentSeq and i.EarnCode = d.EarnCode and i.BenefitOption <> d.BenefitOption
		join bHRCO e on i.HRCo = e.HRCo and e.AuditBenefitsYN = 'Y'

   
return
    
	error:
		select @errmsg = @errmsg + ' - cannot update HRBE'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
    
    
    
    
    
    
    
   
   
  
 



GO
ALTER TABLE [dbo].[bHRBE] WITH NOCHECK ADD CONSTRAINT [CK_bHRBE_ReadyYN] CHECK (([ReadyYN]='Y' OR [ReadyYN]='N'))
GO
ALTER TABLE [dbo].[bHRBE] WITH NOCHECK ADD CONSTRAINT [CK_bHRBE_StdHours] CHECK (([StdHours]='Y' OR [StdHours]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biHRBE] ON [dbo].[bHRBE] ([HRCo], [HRRef], [BenefitCode], [DependentSeq], [EarnCode], [AutoEarnSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRBE] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
