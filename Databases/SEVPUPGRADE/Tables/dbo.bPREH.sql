CREATE TABLE [dbo].[bPREH]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[LastName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[FirstName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MidName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[SortName] [dbo].[bSortName] NOT NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Phone] [dbo].[bPhone] NULL,
[SSN] [char] (11) COLLATE Latin1_General_BIN NOT NULL,
[Race] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[Sex] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[BirthDate] [smalldatetime] NULL,
[HireDate] [dbo].[bDate] NULL,
[TermDate] [dbo].[bDate] NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PRDept] [dbo].[bDept] NOT NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[InsCode] [dbo].[bInsCode] NOT NULL,
[TaxState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[UnempState] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[InsState] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[LocalCode] [dbo].[bLocalCode] NULL,
[GLCo] [dbo].[bCompany] NULL,
[UseState] [dbo].[bYN] NOT NULL,
[UseIns] [dbo].[bYN] NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [dbo].[bDate] NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[HrlyRate] [dbo].[bUnitCost] NOT NULL,
[SalaryAmt] [dbo].[bDollar] NOT NULL,
[OTOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[OTSched] [tinyint] NULL,
[JCFixedRate] [dbo].[bUnitCost] NOT NULL,
[EMFixedRate] [dbo].[bUnitCost] NOT NULL,
[YTDSUI] [dbo].[bDollar] NOT NULL,
[OccupCat] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CatStatus] [char] (1) COLLATE Latin1_General_BIN NULL,
[DirDeposit] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RoutingId] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[BankAcct] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[AcctType] [char] (1) COLLATE Latin1_General_BIN NULL,
[ActiveYN] [dbo].[bYN] NOT NULL,
[PensionYN] [dbo].[bYN] NOT NULL,
[PostToAll] [dbo].[bYN] NOT NULL,
[CertYN] [dbo].[bYN] NOT NULL,
[ChkSort] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[AuditYN] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Email] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[DefaultPaySeq] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPREH_DefaultPaySeq] DEFAULT ('N'),
[DDPaySeq] [tinyint] NULL,
[Suffix] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[TradeSeq] [tinyint] NULL,
[CSLimit] [dbo].[bPct] NULL,
[CSGarnGroup] [dbo].[bGroup] NULL,
[CSAllocMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPREH_CSAllocMethod] DEFAULT ('P'),
[Shift] [tinyint] NULL,
[NonResAlienYN] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPREH_NonResAlienYN] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[HDAmt] [dbo].[bDollar] NULL,
[F1Amt] [dbo].[bDollar] NULL,
[LCFStock] [dbo].[bDollar] NULL,
[LCPStock] [dbo].[bDollar] NULL,
[NAICS] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[AUEFTYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPREH_AUEFTYN] DEFAULT ('N'),
[AUAccountNumber] [varchar] (9) COLLATE Latin1_General_BIN NULL,
[AUBSB] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[AUReference] [varchar] (18) COLLATE Latin1_General_BIN NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[PayMethodDelivery] [char] (1) COLLATE Latin1_General_BIN NULL CONSTRAINT [DF_bPREH_PayMethodDelivery] DEFAULT ('N'),
[CPPQPPExempt] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPREH_CPPQPPExempt] DEFAULT ('N'),
[EIExempt] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPREH_EIExempt] DEFAULT ('N'),
[PPIPExempt] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPREH_PPIPExempt] DEFAULT ('N'),
[TimesheetRevGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UpdatePRAEYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPREH_UpdatePRAEYN] DEFAULT ('N'),
[WOTaxState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[WOLocalCode] [dbo].[bLocalCode] NULL,
[UseLocal] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPREH_UseLocal] DEFAULT ('N'),
[UseUnempState] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPREH_UseUnempState] DEFAULT ('N'),
[UseInsState] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPREH_UseInsState] DEFAULT ('N'),
[NewHireActStartDate] [dbo].[bDate] NULL,
[NewHireActEndDate] [dbo].[bDate] NULL,
[CellPhone] [dbo].[bPhone] NULL,
[ArrearsActiveYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPREH_ArrearsActiveYN] DEFAULT ('N'),
[udOrigHireDate] [smalldatetime] NULL,
[udEmpGroup] [varchar] (25) COLLATE Latin1_General_BIN NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL,
[RecentRehireDate] [dbo].[bDate] NULL,
[RecentSeparationDate] [dbo].[bDate] NULL,
[SeparationRedundancyRetirement] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPREH_SeparationRedundancyRetirement] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btPREHd] on [dbo].[bPREH] for DELETE as
/*-----------------------------------------------------------------
* Created: kb 10/29/98
* Modified: mh 8/24/99 - deleting related records from PRED per issue  4654
*			EN 2/7/00 - maintain DDDU for PR group security
*          	EN 3/30/00 - update HQMA
*         	EN 4/4/00 - modify PRED purge to handle multiple deletion batch and
*                         add code to also purge PRAE/PRCW/PRDD/PREL/PRLB
*          	DANF 04/12/00 - Added check to delete data security
*			GG 12/14/00 - Added checks for both detail and setup info, removed deletion of setup info
*				-- users must delete setup info manually, or use PR Purge program
*			GG 01/16/01 - added checks for bPRTB, bPRDT, and bPRSQ
*			DANF 04/05/01 - Added check to not remove security entries from DDDU and DDDS if the employee exist in HRRM
*           09/30/02 DANF - Added Document Exporting (14550)
*			EN 02/12/03 - issue 23061  added isnull check, with (nolock), and dbo
*							and corrected old syle joins
*			mh 2/07/07 - 123806 - Switch DDDT to DDDTShared
*			GG 4/27/07 - #30116 - data security review, leave security entries in DD
*			AR 11/4/2010 -#129574 - sp_makewebtask is deprecated so removing call to proc
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @employee int,
    @deleted_prco bCompany, @deleted_employee bEmployee
   
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
   
-- check for Employee Accumulations
if (select count(*) from dbo.bPREA e with (nolock) join deleted d on e.PRCo = d.PRCo and e.Employee = d.Employee) > 0
	begin
	select @errmsg = 'Payroll Accumulations exist'
	goto error
	end
-- check for Timecards
if (select count(*) from dbo.bPRTH t with (nolock) join deleted d on t.PRCo = d.PRCo and t.Employee = d.Employee) > 0
	begin
	select @errmsg = 'Timecards exist'
	goto error
	end
-- check for Payment History
if (select count(*) from dbo.bPRPH p with (nolock) join deleted d on p.PRCo = d.PRCo and p.Employee = d.Employee) > 0
	begin
	select @errmsg = 'Payment History exists'
	goto error
	end
-- check for Leave History
if (select count(*) from dbo.bPRLH l with (nolock) join deleted d on l.PRCo = d.PRCo and l.Employee = d.Employee) > 0
	begin
	select @errmsg = 'Leave History exists'
	goto error
	end
-- check for W-2s
if (select count(*) from dbo.bPRWE w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Employee = d.Employee) > 0
	begin
	select @errmsg = 'W-2 detail exists'
	goto error
	end
-- check for Employee DL overrides
if (select count(*) from dbo.bPRED w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Employee = d.Employee) > 0
	begin
	select @errmsg = 'Deduction/Liability overrides exist'
	goto error
	end
-- check for Auto Earnings
if (select count(*) from dbo.bPRAE w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Employee = d.Employee) > 0
	begin
	select @errmsg = 'Auto Earnings exist'
	goto error
	end
-- check for Crew
if (select count(*) from dbo.bPRCW w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Employee = d.Employee) > 0
	begin
	select @errmsg = 'Crew entries exist'
	goto error
	end
-- check for Direct Deposit
if (select count(*) from dbo.bPRDD w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Employee = d.Employee) > 0
	begin
	select @errmsg = 'Direct Deposit distributions exist'
	goto error
	end
-- check for Leave Codes
if (select count(*) from dbo.bPREL w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Employee = d.Employee) > 0
	begin
	select @errmsg = 'Employee Leave Codes exist'
	goto error
	end
-- check for Leave Basis
if (select count(*) from dbo.bPRLB w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Employee = d.Employee) > 0
	begin
	select @errmsg = 'Employee Leave Basis exists'
	goto error
	end
-- check for unposted Timecards
if (select count(*) from dbo.bPRTB w with (nolock) join deleted d on w.Co = d.PRCo and w.Employee = d.Employee) > 0
	begin
	select @errmsg = 'Unposted Timecards exist'
	goto error
	end
-- check for Pay Period Sequence
if (select count(*) from dbo.bPRSQ w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Employee = d.Employee) > 0
	begin
	select @errmsg = 'Employee Sequence Control entries exists'
	goto error
	end
-- check for Pay Period Detail
if (select count(*) from dbo.bPRDT w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Employee = d.Employee) > 0
	begin
	select @errmsg = 'Employee Pay Sequence detail entries exist'
	goto error
	end
   
-- When Deleting the employee and employee level security has been invoked set the the HR Empl to null.
if exists (select 1 from deleted join dbo.bHRRM h (nolock) on deleted.PRCo = h.PRCo and deleted.Employee = h.PREmp) and
       exists (select 1 from dbo.DDDTShared (nolock) where Secure = 'Y' and Datatype = 'bEmployee')
	begin
    update dbo.bHRRM
   	set PREmp = null, ExistsInPR = 'N'
   	from dbo.bHRRM
   	join deleted on deleted.PRCo = bHRRM.PRCo and deleted.Employee = bHRRM.PREmp
   	end
else if exists (select 1 from deleted join dbo.bHRRM h with (nolock) on deleted.PRCo = h.PRCo and deleted.Employee = h.PREmp)
	begin
	update dbo.bHRRM
   	set ExistsInPR = 'N'
   	from dbo.bHRRM
	join deleted on deleted.PRCo = bHRRM.PRCo and deleted.Employee = bHRRM.PREmp
	end
   
-- finished with checks
 
-- #30116 - leave data security entries, purged from VA   
--   /* delete DDDS - Data Security */
--   delete dbo.DDDS
--   from dbo.DDDS
--   join deleted d on DDDS.Qualifier=d.PRCo and DDDS.Instance=convert(char(30),d.Employee)
--   where DDDS.Datatype='bEmployee'
--   	and not exists (select * from dbo.bHRRM h with (nolock) where d.PRCo = h.PRCo and d.Employee = h.PREmp)
--   /* delete DDDU - Data Security By User */
--   delete dbo.DDDU
--   from dbo.DDDU
--   join deleted d on DDDU.Qualifier=d.PRCo and DDDU.Instance=convert(char(30),d.Employee)
--   where DDDU.Datatype='bEmployee'
--   	and not exists (select * from dbo.bHRRM h with (nolock) where d.PRCo = h.PRCo and d.Employee = h.PREmp)
   
/* Document exporting */
declare @group tinyint, @opencursor int, @rcode int,
	@stdxmlformat bYN, @userstoredrroc varchar(30), @hqco bCompany, @hqdxcursor int,
	@sql varchar(300), @exportdirectory varchar(256), @msg varchar(255)

if exists (select top 1 i.PRCo from deleted i join dbo.bHQDX d (nolock) on d.Co = i.PRCo
				and d.Package = 'Employees' and d.TriggerName = 'Delete' and d.Enable = 'Y')
	begin
 	-- Execute Export document for each customer in deleted
   	if @numrows = 1
		begin
   		-- if only one row inserted, no cursor is needed
   		select @hqco = i.PRCo, @employee = i.Employee
   		from deleted i
   		join dbo.bHQDX d (nolock) on d.Co = i.PRCo and d.Package = 'Employees' and d.TriggerName = 'Delete' and d.Enable = 'Y'
   	   	if @@rowcount = 0 goto btexit
   		end
   	else
   		    begin
   		    -- use a cursor to process deleted rows
   		    declare bPREH_cursor cursor for
   		    select i.PRCo, i.Employee
   		    from deleted i
   			join dbo.bHQDX d with (nolock)
   			on d.Co = i.PRCo and d.Package = 'Employees' and d.TriggerName = 'Delete' and d.Enable = 'Y'
   			--from bPREH
   		
   		    open bPREH_cursor
   		    select @opencursor = 1
   		
   		    -- get 1st row deleted
   		    fetch next from bPREH_cursor into @hqco , @employee
   		    if @@fetch_status <> 0 goto btexit
   		    end
   		
   		PREH_export:
   			-- Export Employee Document
   				
   
   					select @stdxmlformat=null, @userstoredrroc=null, @exportdirectory = null
   
   					select @stdxmlformat=StdXMLFormat, @userstoredrroc=UserStoredProc, @exportdirectory=ExportDirectory 
   					from dbo.bHQDX d with (nolock)
   					where d.Co = @hqco and d.Package = 'Employees' and d.TriggerName = 'Delete' and d.Enable = 'Y'
   
      	 -- 129574 - sp_makewebtask is deprecated so removing call to proc						
         IF ISNULL(@stdxmlformat, '') <> 'Y' 
            BEGIN
                IF ISNULL(@userstoredrroc, '') <> '' 
                    BEGIN	
                        SELECT  @sql = 'declare @xrcode int '
                        SELECT  @group = PRGroup
                        FROM    inserted
                        WHERE   PRCo = @hqco
                                AND Employee = @employee
                        SELECT  @sql = @sql + 'exec @xrcode = '
                                + @userstoredrroc + ' ' 
                        SELECT  @sql = @sql + CONVERT(varchar(300), @employee)
                                + ',' 
                        SELECT  @sql = @sql + CONVERT(varchar(300), @group)
                                + ',' 
                        SELECT  @sql = @sql + CONVERT(varchar(300), @hqco)
                                + ',' 
                        SELECT  @sql = @sql + CHAR(39)
                                + ISNULL(@exportdirectory, '') + CHAR(39)
                                + ',' 
                        SELECT  @sql = @sql + CHAR(39) + '*' + CHAR(39)
   
                        EXEC(@sql)
                    END
            END
   		
   		
   		 	-- get next row
   		 	if @numrows > 1
   		    	begin
   		    	fetch next from bPREH_cursor into @group , @employee
   		    	if @@fetch_status = 0 goto PREH_export
   				end
   	end
   btexit:
   /* End Document exporting */
   
/* HQ Master Audit entry */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPREH',  'PR Employee: ' + convert(varchar, Employee), d.PRCo, 'D',
 null, null, null, getdate(), SUSER_SNAME()
from deleted d
join dbo.bPRCO c (nolock) on d.PRCo=c.PRCo
where c.AuditEmployees='Y'
   
   
    return
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Employee'
        	RAISERROR(@errmsg, 11, -1);
        	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[btPREHi] on [dbo].[bPREH] for INSERT as
/*-----------------------------------------------------------------
* Created: kb 10/28/98
* Modified: 04/22/99 GG    (SQL 7.0)
*		  	2/7/00 EN - maintain DDDU for PR group security
*	        02/28/00 GG - fixed join with bPRGS for Security update
*        	4/4/00 EN - validate race code
*        	4/12/00 EN - validate that Crafts exist for non-null Classes
*       	9/28/00 EN - include ability to select category status J (for NY DOT reporting)
*		  	11/02/01 GG - #15188 - added Direct Deposit validation, require RoutingId, BankAcct, AcctType
*			12/18/01 GG - #15655 - fix SortName validation , skip security updates if bEmployee datatype is not secured
*           09/30/02 DANF - Added Document Exporting (14550)
*			02/12/03 EN - issue 23061  added isnull check, with (nolock), and dbo
*			3/3/04 EN - issue 20564  validate Shift
*			10/03/05 GG - #29019 - make sure SortName is upper case before testing for uniqueness
*			10/14/05 GG -  #28967 - cleanup security update
*			2/7/07 mh - 123806 - Switch DDDT to DDDTShared
*			GG 04/20/07 - #30116 - data security review, validation cleanup
*			mh 3/11/2008 - #127081 - Added Country validation.
*			EN 3/21/08 - #127081  modified HQST validation to include country for TaxState, InsState and UnempState
*			GG 06/05/08 - #128324 - State/Country validation fix
*			mh 02/13/09 - #125436 - Reject inserts if PayMethodDeliv is not 'N-None' and Email address is null
*			TJL 02/16/10 - #135490, Add new fields for Work Office Tax State and Work Office Local Code 
*			AR	11/4/2010 -#129574 - sp_makewebtask is deprecated so removing call to proc
*				CHS	09/26/2011	- B-06080 allow duplication of 333-333-333, 444-444-444, 111-111-111, and 000-000-000.
*
*	Insert trigger for PR Employee Header table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
	@prco bCompany, @employee bEmployee, @prgroup bGroup, @nullcnt int
  
select @numrows = @@rowcount
if @numrows = 0 return
  
set nocount on
  
/* validate PR Company */
select @validcnt = count(*) from dbo.bPRCO c (nolock) join inserted i on c.PRCo = i.PRCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid PR Company#'
	goto error
	end
-- #29019 check SortName for upper case before uniqueness
if exists(select top 1 1 from inserted where SortName <> upper(SortName))
  	begin
  	select @errmsg = 'Sort Name must be uppercase'
  	goto error
  	end
/*check for uniqueness in Sort Name*/
select @validcnt = count(*) from dbo.bPREH a (nolock)
join inserted i	on a.SortName = i.SortName and a.PRCo = i.PRCo
if @validcnt<>@numrows
  	begin
  	select @errmsg = 'Sort Name must be unique'
  	goto error
  	end
  	
-- validate Country 
select @validcnt = count(1)
from dbo.bHQCountry c (nolock) 
join inserted i on i.Country = c.Country
select @nullcnt = count(1) from inserted where Country is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country'
	goto error
	end
-- validate Country/State combinations
select @validcnt = count(1) -- Country/State combos are unique
from inserted i
join dbo.bHQCO c (nolock) on c.HQCo = i.PRCo	-- join to get Default Country
join dbo.bHQST s (nolock) on isnull(i.Country,c.DefaultCountry) = s.Country and i.State = s.State
select @nullcnt = count(1) from inserted where State is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country and State combination'
	goto error
	end
	
/* validate Sex */
select @validcnt = count(*) from inserted i where i.Sex in ('M','F')
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Sex must be ''M'' or ''F'''
  	goto error
  	end
  	
/*check for uniqueness in SSN*/
	declare @Country char(2), @SSN char(11)
		
	select @validcnt = count(*), @Country = c.DefaultCountry, @SSN = i.SSN
	from dbo.bPREH a (nolock)
	join inserted i	on a.SSN = upper(i.SSN) and a.PRCo = i.PRCo
	JOIN dbo.bHQCO c (NOLOCK) ON c.HQCo = i.PRCo	-- join to get Default Country
	group by c.DefaultCountry, i.SSN
			
	if @validcnt <> @numrows
		begin
		IF @Country <> 'AU' OR (@Country = 'AU' AND @SSN NOT IN ('333-333-333', '444-444-444', '111-111-111', '000-000-000'))
			BEGIN
			select @errmsg = '@validcnt = ' + cast(@validcnt as varchar(10)) + '@numrows = ' + cast(@numrows as varchar(10)) + 'SSN already exists for an employee in this company'
			goto error				
			END

		end		
	
 
/* validate Race */
select @validcnt = count(*) from dbo.bPRRC c (nolock) join inserted i on c.PRCo = i.PRCo and c.Race=i.Race
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Race Code'
  	goto error
  	end
/* validate PR Group */
select @validcnt = count(*) from dbo.bPRGR c (nolock) join inserted i on c.PRCo = i.PRCo and c.PRGroup=i.PRGroup
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid PR Group'
  	goto error
  	end
/* validate PR Department */
select @validcnt = count(*) from dbo.bPRDP c (nolock) join inserted i on c.PRCo = i.PRCo and c.PRDept=i.PRDept
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid PR Department'
  	goto error
  	end
/* validate PR Craft */
select @nullcnt = count(*) from inserted i where i.Craft is null
select @validcnt = count(*) from dbo.bPRCM c (nolock) join inserted i on c.PRCo = i.PRCo and c.Craft=i.Craft
if @nullcnt + @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Craft'
  	goto error
  	end
/* validate Craft/Class */
select @validcnt = count(*) from inserted i where i.Craft is null and i.Class is not null
if @validcnt <> 0
	begin
    select @errmsg = 'Missing Craft'
    goto error
	end
  
select @nullcnt = count(*) from inserted i where i.Class is null
select @validcnt = count(*) from dbo.bPRCC c (nolock) join inserted i on c.PRCo = i.PRCo and c.Craft=i.Craft and c.Class=i.Class

--select @nullcnt '@nullcnt'
--select @validcnt '@validcnt'
--select @numrows '@numrows'
--if @validcnt <> @validcnt2
if @nullcnt + @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Craft Class combination'
  	goto error
  	end
/* validate PR Insurance */
select @validcnt = count(*) from dbo.bHQIC c (nolock) join inserted i on c.InsCode=i.InsCode
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Insurance Code'
  	goto error
  	end
/* validate Tax State */
select @validcnt = count(*) from inserted where TaxState is not null
select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
	join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.TaxState
if @validcnt2 <> @validcnt
  	begin
  	select @errmsg = 'Invalid Tax State'
  	goto error
  	end
/* validate Unemp State */
select @validcnt = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
	join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.UnempState
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Unemployment State'
  	goto error
  	end
/* validate Insurance State */
select @validcnt = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
	join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.InsState
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Insurance State'
  	goto error
  	end
/* validate Local Code*/
select @nullcnt = count(*) from inserted i where i.LocalCode is null
select @validcnt = count(*) from dbo.bPRLI c (nolock) join inserted i on c.PRCo = i.PRCo and c.LocalCode = i.LocalCode
if @nullcnt + @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Local Code'
  	goto error
  	end
/* validate Work Office Tax State */
select @validcnt = count(*) from inserted where WOTaxState is not null
select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
	join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.WOTaxState
if isnull(@validcnt2,0) <> isnull(@validcnt,0)
	begin
	select @errmsg = 'Invalid Work Office Tax State'
	goto error
	end
/* validate Work Office Local Code*/
select @nullcnt = count(*) from inserted i where i.WOLocalCode is null
select @validcnt = count(*) from dbo.bPRLI c (nolock) join inserted i on c.PRCo = i.PRCo and c.LocalCode = i.WOLocalCode
if isnull(@nullcnt,0) + isnull(@validcnt,0) <> isnull(@numrows,0)
	begin
	select @errmsg = 'Invalid Work Office Local Code'
	goto error
	end
/* validate GLCo */
select @nullcnt = count(*) from inserted i where i.GLCo is null
select @validcnt = count(*) from dbo.bGLCO c (nolock) join inserted i on c.GLCo = i.GLCo 
if @nullcnt + @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid GL Company'
  	goto error
  	end
/* validate JCCo */
select @nullcnt = count(*) from inserted i where i.JCCo is null
select @validcnt = count(*) from dbo.bJCCO c (nolock) join inserted i on c.JCCo = i.JCCo 
if @nullcnt + @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid JC Company'
  	goto error
  	end
/* validate Job */
select @nullcnt = count(*) from inserted i where i.Job is null
select @validcnt = count(*) from dbo.bJCJM c (nolock) join inserted i on c.JCCo = i.JCCo and c.Job=i.Job
if @nullcnt + @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Job'
  	goto error
  	end
/* validate Crew */

--select Crew, PRCo, Employee from inserted
select @nullcnt = count(*) from inserted i where i.Crew is null
select @validcnt = count(*) from dbo.bPRCR c (nolock) join inserted i on c.PRCo = i.PRCo and c.Crew = i.Crew

--select @nullcnt 'PRCrew Null Count'
--select @validcnt 'PRCrew Valid Count'
--select @numrows 'PRCrew Num Rows'

if @nullcnt + @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Crew ' + 'Nullcnt = ' + convert(varchar(5),@nullcnt) + 
' @validcnt = ' + convert(varchar(5),@validcnt) + ' @numrows ' + convert(varchar(5),@numrows)
  	goto error
  	end
/* validate Earnings Code */
select @validcnt = count(*) from dbo.bPREC c with (nolock) join inserted i on c.PRCo = i.PRCo and c.EarnCode = i.EarnCode
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Earnings Code'
  	goto error
  	end
/* validate Overtime Option*/
select @validcnt = count(*) from inserted i where i.OTOpt in ('N','D','W','C','J')
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Overtime Option must be ''N'', ''D'', ''W'', ''C'' or ''J'''
  	goto error
  	end
/* validate Overtime Schedule */
select @nullcnt = count(*) from inserted i where i.OTSched is null
select @validcnt = count(*) from dbo.bPROT c with (nolock) join inserted i on c.PRCo = i.PRCo and c.OTSched = i.OTSched
if @nullcnt + @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid OT Schedule'
  	goto error
  	end
/* validate Occupational Category*/
select @nullcnt = count(*) from inserted i where i.OccupCat is null
select @validcnt = count(*) from dbo.bPROP c with (nolock) join inserted i on c.PRCo = i.PRCo and c.OccupCat = i.OccupCat
if @nullcnt + @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Occupational Category'
  	goto error
  	end
/* validate Category Status*/
select @nullcnt = count(*) from inserted i where i.CatStatus is null
select @validcnt = count(*) from inserted i where i.CatStatus in ('A','T','J','N')
if @nullcnt + @validcnt <> @numrows
  	begin
  	select @errmsg = 'Category Status must be ''A'', ''T'' or ''N'''
  	goto error
  	end
/* validate Direct Deposit Option*/
select @validcnt = count(*) from inserted where DirDeposit in ('N','P','A')
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Direct Deposit Option must be ''N'', ''P'', ''A'''
  	goto error
  	end
-- validate required info for Direct Deposits
if exists(select top 1 1 from inserted
  		where DirDeposit in ('P','A') and (RoutingId is null or BankAcct is null or AcctType is null))
  	begin
  	select @errmsg = 'Routing Transit#, Bank Acct, and Account Type are required with PreNote or Active Direct Deposits'
  	goto error
  	end
/* validate Direct Deposit Account Type*/
if exists(select top 1 1 from inserted where DirDeposit in ('P','A') and AcctType not in ('C','S'))
  	begin
  	select @errmsg = 'Direct Deposit Account Type must be ''C'' or ''S'''
  	goto error
  	end
-- validate Shift
select @nullcnt = count(*) from inserted where Shift is null
select @validcnt = count(*) from inserted where Shift > 0 and Shift < 256
if @nullcnt + @validcnt <> @numrows
  	begin
  	select @errmsg = 'Shift must be an integer between 1 and 255'
  	goto error
  	end
-- Check Email is populated when PayMethodDelivery is not 'N-None'
if exists(select top 1 1 from inserted 
	where PayMethodDelivery in ('E','A') and Email is null)
	begin
	select @errmsg = 'EMail address is required when Method of Pay Stub Delivery is ''Email'''
	goto error
	end
  
  /* Document exporting */
  declare @group tinyint, @opencursor int, @rcode int,
  		@stdxmlformat bYN, @userstoredrroc varchar(30), @hqco bCompany, @hqdxcursor int,
  		@sql varchar(300), @exportdirectory varchar(256), @msg varchar(255)
  
  if exists (select top 1 i.PRCo
  			from inserted i 
  			join dbo.bHQDX d with (nolock) 
  			on d.Co = i.PRCo and d.Package = 'Employees' and d.TriggerName = 'Insert' and d.Enable = 'Y')
  
  	begin
  
  		-- Execute Export document for each customer in Inserted
  		if @numrows = 1
  		    begin
  		    -- if only one row inserted, no cursor is needed
  		    select @hqco = i.PRCo, @employee = i.Employee
  			from inserted i
  			join dbo.bHQDX d with (nolock) 
  			on d.Co = i.PRCo and d.Package = 'Employees' and d.TriggerName = 'Insert' and d.Enable = 'Y'
  		
  			if @@rowcount = 0 goto btexit
  		    end
  		else
  		    begin
  		    -- use a cursor to process inserted rows
  		    declare bPREH_cursor cursor for
  		    select i.PRCo, i.Employee
  		    from inserted i
  			join dbo.bHQDX d with (nolock) 
  			on d.Co = i.PRCo and d.Package = 'Employees' and d.TriggerName = 'Insert' and d.Enable = 'Y'
  			--from bPREH
  		
  		    open bPREH_cursor
  		    select @opencursor = 1
  		
  		    -- get 1st row inserted
  		    fetch next from bPREH_cursor into @hqco , @employee
  		    if @@fetch_status <> 0 goto btexit
  		    end
  		
  		PREH_export:
  			-- Export Employee Document
  				
  
  					select @stdxmlformat=null, @userstoredrroc=null, @exportdirectory = null
  
  					select @stdxmlformat=StdXMLFormat, @userstoredrroc=UserStoredProc, @exportdirectory=ExportDirectory 
  					from dbo.bHQDX d with (nolock) 
  					where d.Co = @hqco and d.Package = 'Employees' and d.TriggerName = 'Insert' and d.Enable = 'Y'
  
  
			 -- 129574 - sp_makewebtask is deprecated so removing call to proc
             IF ISNULL(@stdxmlformat, '') <> 'Y' 
                BEGIN
                    IF ISNULL(@userstoredrroc, '') <> '' 
                        BEGIN	
                            SELECT  @sql = 'declare @xrcode int '
                            SELECT  @group = PRGroup
                            FROM    inserted
                            WHERE   PRCo = @hqco
                                    AND Employee = @employee
                            SELECT  @sql = @sql + 'exec @xrcode = '
                                    + @userstoredrroc + ' ' 
                            SELECT  @sql = @sql
                                    + CONVERT(varchar(300), @employee) + ',' 
                            SELECT  @sql = @sql + CONVERT(varchar(300), @group)
                                    + ',' 
                            SELECT  @sql = @sql + CONVERT(varchar(300), @hqco)
                                    + ',' 
                            SELECT  @sql = @sql + CHAR(39)
                                    + ISNULL(@exportdirectory, '') + CHAR(39)
                                    + ',' 
                            SELECT  @sql = @sql + CHAR(39) + '*' + CHAR(39)
  
                            EXEC(@sql)
                        END
                END
  		
  		
  		 	-- get next row
  		 	if @numrows > 1
  		    	begin
  		    	fetch next from bPREH_cursor into @group , @employee
  		    	if @@fetch_status = 0 goto PREH_export
  				end
  	end
  btexit:
  /* End Document exporting */
  

-- #30116 - data security for Employee#
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bEmployee' and Secure = 'Y'
if @@rowcount > 0
	begin
 	-- add security entries for users assigned to the PRGroup
  	insert dbo.vDDDU (Datatype, Qualifier, Instance, VPUserName)
  	select 'bEmployee', i.PRCo, convert(char(30),i.Employee), s.VPUserName
  	from inserted i
  	join dbo.bPRGS s (nolock) on i.PRCo = s.PRCo and i.PRGroup = s.PRGroup
 		and not exists(select top 1 1 from dbo.vDDDU u (nolock)
 				where u.Qualifier = i.PRCo and u.Instance = convert(char(30),i.Employee)
 				and u.Datatype = 'bEmployee' and u.VPUserName = s.VPUserName)
 	-- add security entries for default security group		
	if @dfltsecgroup is not null
		begin
		insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
		select 'bEmployee', i.PRCo, convert(char(30),i.Employee), @dfltsecgroup
		from inserted i 
		where not exists(select top 1 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bEmployee' and s.Qualifier = i.PRCo 
							and s.Instance = convert(char(30),i.Employee) and s.SecurityGroup = @dfltsecgroup)
		end
	end
 
/* add HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPREH',  'PR Employee: ' + convert(char(10), Employee), i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i
join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
where a.AuditEmployees = 'Y'
  
return

error:
  	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Employee Header!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction

GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   trigger [dbo].[btPREHu] on [dbo].[bPREH] for UPDATE as
/*-----------------------------------------------------------------
* Created: kb 10/28/98
* Modified: GG 07/20/99    - fixed Craft/Class validation
*   		JE 10/11/99    - fixed key changes where clause
*		 	EN 2/7/00	- maintain DDDU for PR group security
*			GG 02/28/00 - fixed join with bPRGS for Security update
*      		EN 4/12/00 - validate that Crafts exist for non-null Classes
*      		EN 9/28/00 - include ability to select category status J (for NY DOT reporting)
*      		EN 10/09/00 - Checking for key changes incorrectly
*      		RM 03/15/01 - Clear TermDate if HireDate is more current
*		 	GG 11/02/01 - #15188 - Added Direct Deposit validation
*		 	GG 11/07/01 - #15198 - Removed HR TermDate update
*		 	GG 12/18/01 - #15655 - fix SortName validation
*		 	EN 1/23/02 - #16023 - added auditing code for fields DefaultPaySeq, DDPaySeq, and Suffix
*		 	EN 1/29/02 - #16023 - fixed audit code for all non-null fields to write to HQMA if field is changed to or from null
*      		EN 2/12/02 - #16023 - slight mod to isnull for PaySeq field ... changed isnull default from -1 to ''
*		 	GG 03/01/02 - skip Data Security updates if bEmployee is not a secure datatype
*		 	EN 8/15/02 - issue 17502 added auditing code for field TradeSeq
*      		09/30/02 DANF - Added Document Exporting (14550)
*			mh 5/7/03 Issue 19538
*			mh 8/14/03 Issue 22166 - corrected Category Status error message
*			EN 02/12/03 - issue 23061  added isnull check, with (nolock), and dbo
*			EN 3/3/04 - issue 20564  validate Shift
*			10/03/05 GG - #29019 - make sure SortName is upper case before testing for uniqueness
*			MH 10/6/05 - #28967 - update PRGroup changes to HRRM - data security cleanup
*			EN 3/9/06 - issue 120402  fixed to include full year in date when insert BirthDate, HireDate, TermDate, and LastUpdated date to HQMA
*			mh 2/7/07 - 123806 - Switch DDDT to DDDTShared
*			GG 5/2/07 - #30116 - data security review, cleanup
*			mh 9/26/07 - #29630 - Adding cross update for OTSched, OTOpt, Shift.
*			mh 3/11/2008 - #127081 - Added Country validation in addition to cross update and audit code
*							for Country.
*			EN 3/21/08 - #127081  modified HQST validation to include country for TaxState, InsState and UnempState
*			GG 06/05/08 - #128324 - State/Country validation fix
*			EN 7/07/08 - #127015 - add code for HDAmt, F1Amt, LCFStock and LCPStock to HQMA auditing
*			MH 8/6/2008 - #129198 - added cross update to bHRRM for HDAmt, F1Amt, LCFStock, LCPStock
*			MH 01/09/2009 - #131214 - Corrected to not delete term reason in HRRM if only changing term date to another date.
*									Should continue to delete term reason is term date removed.
*			mh 02/14/2009 - #125436 - Added audit entry for PayMethodDelivery.  Rejecting updates if Email is null
*					and PayMethodDelivery is not 'N-None'
*			EN 4/17/2009 #133253  Added with (nolock) to bHRRM to prevent deadlocks
*			mh 02/10/2010 #124598 - Added code to update bPRAE with earnings code change in bPREH
*									where the earnings code exists in bPRAE and newly added flag
*									UpdatePRAEYN = 'Y'.  Added auditing for new column UpdatePRAEYN.  
*			TJL 02/16/10 - #135490, Add new fields for Work Office Tax State and Work Office Local Code 
*			AR 11/4/2010 -#129574 - sp_makewebtask is deprecated so removing call to proc
*			MV	04/11/11 - Backlog Item# B-04112 - Add cellphone to HR cross update.
*			CHS	09/26/2011	- B-06080 allow duplication of 333-333-333, 444-444-444, 111-111-111, and 000-000-000.
*			MV	08/13/2012	-	B-10397 audit ArrearsActiveYN 
*			DAN SO 02/19/2013 - TFS-40964 - Audit newly added columns - RecentRehireDate, RecentSeparationDate, SeparationRedundancyRetirement
*
*	Update trigger for PR Employee Master
*
*	Adds record to HQ Master Audit.
*/----------------------------------------------------------------
   
declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, 
	@prco bCompany, @employee bEmployee, @prgroup bGroup, @nullcnt int
   
--19538
declare @active int, @hrco bCompany, @hrref bHRRef
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
/* check for key changes */
if update(PRCo)
	begin
    select @validcnt = count(*) from deleted d join inserted i on d.PRCo = i.PRCo
    if @validcnt <> @numrows
   		begin
        select @errmsg = 'Cannot change PR Company'
        goto error
        end
    end
if update(Employee)
    begin
    select @validcnt = count(*) from deleted d join inserted i on d.PRCo = i.PRCo and d.Employee = i.Employee
    if @validcnt <> @numrows
   		begin
        select @errmsg = 'Cannot change Employee'
        goto error
        end
    end
   
/*check for uniqueness in Sort Name*/
if update(SortName)
   	begin
	-- #29019 check for upper case before uniqueness
	if exists(select top 1 1 from inserted where SortName <> upper(SortName))
   		begin
   		select @errmsg = 'Sort Name must be uppercase'
   		goto error
   		end
   	select @validcnt = count(*) from dbo.bPREH a (nolock)
	join inserted i on i.PRCo = a.PRCo and a.SortName = i.SortName
   	if @validcnt<>@numrows
   		begin
   		select @errmsg = 'Sort Name is not unique'
   		goto error
   		end
   	end

if update([State]) or update(Country)
	begin
	select @validcnt = count(1) 
	from dbo.bHQCountry c with (nolock) 
	join inserted i on i.Country = c.Country
	select @nullcnt = count(1) from inserted where Country is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Country'
		goto error
		end
	-- validate Country/State combinations
	select @validcnt = count(1) -- Country/State combos are unique
	from inserted i
	join dbo.bHQCO c (nolock) on c.HQCo = i.PRCo	-- join to get Default Country
	join dbo.bHQST s (nolock) on isnull(i.Country,c.DefaultCountry) = s.Country and i.State = s.State
	select @nullcnt = count(1) from inserted where [State] is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Country and State combination'
		goto error
		end
	end

/* validate Sex */
if UPDATE(Sex)
   	begin
   	select @validcnt = count(*) from inserted i where i.Sex='M' or i.Sex='F'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Sex must be ''M'' or ''F'''
   		goto error
   		end
   	end
   	
/*check for uniqueness in SSN*/
if update(SSN)
   	begin
		declare @Country char(2), @SSN char(11)
		
		select @validcnt = count(*), @Country = c.DefaultCountry, @SSN = i.SSN
		from dbo.bPREH a (nolock)
		join inserted i	on a.SSN = upper(i.SSN) and a.PRCo = i.PRCo
		JOIN dbo.bHQCO c (NOLOCK) ON c.HQCo = i.PRCo	-- join to get Default Country
		group by c.DefaultCountry, i.SSN
				
		if @validcnt <> @numrows
			begin
			IF @Country <> 'AU' OR (@Country = 'AU' AND @SSN NOT IN ('333-333-333', '444-444-444', '111-111-111', '000-000-000'))
				BEGIN
				select @errmsg = '@validcnt = ' + cast(@validcnt as varchar(10)) + '@numrows = ' + cast(@numrows as varchar(10)) + 'SSN already exists for an employee in this company'
				goto error				
				END

			end	

   	end
   	
if update(Race)
   	begin
   	select @validcnt = count(*) from dbo.bPRRC c (nolock)
	join inserted i on c.PRCo = i.PRCo and c.Race=i.Race
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Race Code'
   		goto error
   		end
   	end
/* validate PR Group */
if update(PRGroup)
   	begin
   	select @validcnt = count(*) from dbo.bPRGR c (nolock)
	join inserted i on c.PRCo = i.PRCo and c.PRGroup=i.PRGroup
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid PR Group'
   		goto error
   		end
   	end
/* validate PR Department */
if update(PRDept)
   	begin
   	select @validcnt = count(*) from dbo.bPRDP c (nolock)
	join inserted i on c.PRCo = i.PRCo and c.PRDept=i.PRDept
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid PR Department'
   		goto error
   		end
   	end
/* validate PR Craft and Class */
if update(Craft) or update(Class)
   	begin
   	select @nullcnt = count(*) from inserted i where i.Craft is null
   	select @validcnt = count(*) from dbo.bPRCM c (nolock)
	join inserted i on c.PRCo = i.PRCo and c.Craft=i.Craft
   	if @nullcnt + @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Craft'
   		goto error
   		end
   	/* validate PR Class */
	select @validcnt = count(*) from inserted i where i.Craft is null and i.Class is not null
    if @validcnt <> 0
    	begin
        select @errmsg = 'Missing Craft'
        goto error
        end
	select @validcnt2 = count(*) from inserted i where i.Class is not null
    if @validcnt2<>0
       	begin
       	select @validcnt = count(*) from dbo.bPRCC c (nolock) join inserted i on c.PRCo = i.PRCo and c.Craft=i.Craft and c.Class=i.Class
       		where i.Class is not null
       	if @validcnt <> @validcnt2
       		begin
       		select @errmsg = 'Invalid Craft Class'
       		goto error
       		end
       	end
	end
/* validate PR Insurance */
if update(InsCode)
	begin
   	select @validcnt = count(*) from dbo.bHQIC c with (nolock) join inserted i on c.InsCode=i.InsCode
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Insurance Code'
   		goto error
   		end
   	end
/* validate Tax State */
if update(TaxState)
   	begin
   	select @validcnt = count(*) from inserted where TaxState is not null
    select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
		join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.TaxState
   	if @validcnt2 <> @validcnt
		begin
		select @errmsg = 'Invalid Tax State'
		goto error
		end
   	end
/* validate Unemp State */
if update(UnempState)
   	begin
    select @validcnt = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
		join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.UnempState
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Unemployment State'
   		goto error
   		end
   	end
/* validate Insurance State */
if update(InsState)
   	begin
    select @validcnt = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
		join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.InsState
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Insurance State'
   		goto error
   		end
   	end
/* validate Local Code*/
if update(LocalCode)
   	begin
   	select @nullcnt = count(*) from inserted i where i.LocalCode is null
	select @validcnt = count(*) from dbo.bPRLI c (nolock)
	join inserted i on c.PRCo = i.PRCo and c.LocalCode = i.LocalCode
   	if @nullcnt + @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Local Code'
   		goto error
   		end
   	end
/* validate Work Office Tax State */
if update(WOTaxState)
   	begin
   	select @validcnt = count(*) from inserted where WOTaxState is not null
    select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
		join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.WOTaxState
   	if isnull(@validcnt2,0) <> isnull(@validcnt,0)
		begin
		select @errmsg = 'Invalid Work Office Tax State'
		goto error
		end
   	end
/* validate Work Office Local Code*/
if update(WOLocalCode)
   	begin
   	select @nullcnt = count(*) from inserted i where i.WOLocalCode is null
	select @validcnt = count(*) from dbo.bPRLI c (nolock)
	join inserted i on c.PRCo = i.PRCo and c.LocalCode = i.WOLocalCode
   	if isnull(@nullcnt,0) + isnull(@validcnt,0) <> isnull(@numrows,0)
   		begin
   		select @errmsg = 'Invalid Work Office Local Code'
   		goto error
   		end
   	end  	
/* validate GLCo */
if update(GLCo)
   	begin
   	select @nullcnt = count(*) from inserted i where i.GLCo is null
   	select @validcnt = count(*) from dbo.bGLCO c (nolock)
	join inserted i on c.GLCo = i.GLCo
   	if @nullcnt + @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid GL Company'
   		goto error
   		end
   	end
/* validate JCCo */
if update(JCCo) or update(Job)
   	begin
   	select @validcnt2 = count(*) from inserted i where i.JCCo is not null
   	if @validcnt2<>0
   		begin
   		select @validcnt = count(*) from dbo.bJCCO c with (nolock)
		join inserted i on c.JCCo = i.JCCo
		where i.JCCo is not null
   		if @validcnt <> @validcnt2
   			begin
   			select @errmsg = 'Invalid JC Company'
   			goto error
   			end
   		end
   	select @validcnt2 = count(*) from inserted i where i.JCCo is not null and i.Job is not null
   	if @validcnt2<>0
   		begin
   		/* validate Job */
   		select @validcnt = count(*) from dbo.bJCJM c with (nolock)
		join inserted i on c.JCCo = i.JCCo and c.Job=i.Job
        where i.JCCo is not null and i.Job is not null
   		if @validcnt <> @validcnt2
   			begin
   			select @errmsg = 'Invalid Job'
   			goto error
   			end
   		end
   	end
/* validate Crew */
if update(Crew)
   	begin
   	select @nullcnt = count(*) from inserted i where i.Crew is null
	select @validcnt = count(*) from dbo.bPRCR c (nolock)
	join inserted i on c.PRCo = i.PRCo and c.Crew = i.Crew
   	if @nullcnt + @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Crew'
   		goto error
   		end
   	end
/* validate Earnings Code */
if update(EarnCode)
   	begin
   	select @validcnt = count(*) from dbo.bPREC c (nolock) 
	join inserted i on c.PRCo = i.PRCo and c.EarnCode = i.EarnCode
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Earnings Code'
   		goto error
   		end
   	end
/* validate Overtime Option*/
if update(OTOpt)
   	begin
   	select @validcnt = count(*) from inserted where OTOpt in ('N','D','W','C','J')
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Overtime Option must be ''N'', ''D'', ''W'', ''C'' or ''J'''
   		goto error
   		end
   	end
/* validate Overtime Schedule */
if update(OTSched)
   	begin
   	select @nullcnt = count(*) from inserted i where i.OTSched is null
	select @validcnt = count(*) from dbo.bPROT c (nolock)
	join inserted i on c.PRCo = i.PRCo and c.OTSched = i.OTSched
   	if @nullcnt + @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid OT Schedule'
   		goto error
   		end
   	end
/* validate Occupational Category*/
if update(OccupCat)
   	begin
   	select @nullcnt = count(*) from inserted i where i.OccupCat is null
	select @validcnt = count(*) from dbo.bPROP c (nolock)
	join inserted i on c.PRCo = i.PRCo and c.OccupCat = i.OccupCat
   	if @nullcnt + @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Occupational Category' 
   		goto error
   		end
   	end
/* validate Category Status*/
if update(CatStatus)
   	begin
   	select @nullcnt = count(*) from inserted i where i.CatStatus is null
	select @validcnt = count(*) from inserted where CatStatus in ('A','T','J','N')
	if @nullcnt + @validcnt <> @numrows
   		begin
   		--Issue 22166
   		select @errmsg = 'Category Status must be ''A'', ''J'', ''T'', or ''N'''
   		goto error
   		end
   	end
/* validate Direct Deposit Option*/
if update(DirDeposit) or update(RoutingId) or update(BankAcct) or update(AcctType)
   	begin
   	select @validcnt = count(*) from inserted where DirDeposit in ('N','P','A')
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Direct Deposit Option must be ''N'', ''P'', ''A'''
   		goto error
   		end
   	-- validate required info for Direct Deposits
   	if exists(select top 1 1 from inserted
   		where DirDeposit in ('P','A') and (RoutingId is null or BankAcct is null or AcctType is null))
   			begin
   			select @errmsg = 'Routing Transit#, Bank Acct, and Account Type are required with PreNote or Active Direct Deposits'
   			goto error
   			end
   	-- validate Direct Deposit Account Type
   	if exists(select top 1 1 from inserted where DirDeposit in ('P','A') and AcctType not in ('C','S'))
   		begin
   		select @errmsg = 'Direct Deposit Account Type must be ''C'' or ''S'''
   		goto error
   		end
   	end
   
if exists(select top 1 1 from inserted 
	where PayMethodDelivery in ('E','A') and Email is null)
	begin
	select @errmsg = 'EMail address is required when Method of Pay Stub Delivery is ''Email'''
	goto error
	end

-- validate Shift
select @validcnt = count(*) from inserted where Shift is null
select @validcnt2 = count(*) from inserted where Shift > 0 and Shift < 256
if @validcnt2 + @validcnt <> @numrows
   	begin
   	select @errmsg = 'Shift must be an integer between 1 and 255'
   	goto error
   	end
 
-- #28967 - PRGroup change cross updates HR and refreshes data level security
if update(PRGroup)
	begin
	-- update PRGroup on any HR Resource entries with matching PR Co# and Employee #s
 	update dbo.bHRRM
 	set PRGroup = i.PRGroup
 	from dbo.bHRRM h with (nolock)
 	join inserted i on h.PRCo = i.PRCo and h.PREmp = i.Employee 
	where i.PRGroup <> h.PRGroup

	-- check if Employee is a secure datatype
	if (select count(*) from dbo.DDDTShared (nolock) where Datatype = 'bEmployee' and Secure = 'Y') > 0
		begin
   		-- remove security entries for all users assigned to the old PRGroup
 		delete dbo.vDDDU 
 		from dbo.vDDDU u
		join deleted d on u.Qualifier = d.PRCo and u.Instance = convert(char(30), d.Employee)
 		where u.Datatype = 'bEmployee'
			and VPUserName in (select VPUserName from dbo.bPRGS g with (nolock)
								where g.PRCo = d.PRCo and g.PRGroup = d.PRGroup)
 
		-- add security entries for all users assigned to the new PRGroup
 		insert dbo.vDDDU (Datatype, Qualifier, Instance, VPUserName)
 		select 'bEmployee', i.PRCo, convert(char(30),i.Employee), s.VPUserName
 		from inserted i
 		join dbo.bPRGS s on i.PRCo = s.PRCo and i.PRGroup = s.PRGroup
			and not exists (select 1 from dbo.vDDDU u (nolock)
				where u.Qualifier = i.PRCo and u.Instance = convert(char(30),i.Employee)
				and u.Datatype = 'bEmployee' and u.VPUserName = s.VPUserName)
		end
	end



--6.x recode - Cross update remaining fields based on HRCO
	if exists(select 1 from bHRRM h with (nolock) join inserted i on h.PRCo = i.PRCo and h.PREmp = i.Employee)
	begin
		--Employee exists in HRRM. 

		--Update Name
		if (update(LastName) or update(FirstName) or update(MidName) or update(SortName) or update(BirthDate)
		or update(Race) or update(Sex) or update(Suffix))
		begin
			update dbo.bHRRM
			set LastName = i.LastName, FirstName = i.FirstName, MiddleName = i.MidName, 
			Suffix=i.Suffix, SortName = i.SortName, BirthDate = i.BirthDate, 
			Race = i.Race, Sex = i.Sex
			from inserted i
			join dbo.bHRRM h with (nolock) on i.PRCo = h.PRCo and i.Employee = h.PREmp
			join dbo.bHRCO o (nolock) on h.HRCo = o.HRCo and o.UpdateNameYN = 'Y'
			where h.LastName <> i.LastName or isnull(h.FirstName,'') <> isnull(i.FirstName,'') 
			or isnull(h.MiddleName,'') <> isnull(i.MidName,'') or isnull(h.Suffix,'') <> isnull(i.Suffix,'')
			or isnull(h.SortName,'') <> isnull(i.SortName,'') or isnull(h.BirthDate,'') <> isnull(i.BirthDate,'')
			or h.Race <> i.Race or h.Sex <> i.Sex
		end

		--Update Address
		if (update([Address]) or update(City) or update([State]) or update(Zip) or update(Phone) or update(Email) or
		update(Address2) or update(Country) or update(CellPhone))
		begin
			update dbo.bHRRM
			set Address = i.Address, City = i.City, State = i.State, Zip = i.Zip,
			Address2 = i.Address2, Phone = i.Phone, Email = i.Email, Country = i.Country,
			CellPhone = i.CellPhone
			from inserted i
			join dbo.bHRRM h with (nolock) on i.PRCo = h.PRCo and i.Employee = h.PREmp
			join dbo.bHRCO o (nolock) on h.HRCo = o.HRCo and o.UpdateAddressYN = 'Y'
			where isnull(h.Address,'') <> isnull(i.Address,'') or isnull(h.City,'') <> isnull(i.City,'') 
			or isnull(h.State,'') <> isnull(i.State,'') or isnull(h.Zip, '') <> isnull(i.Zip,'')
			or isnull(h.Address2, '') <> isnull(i.Address2, '') or isnull(h.Phone,'') <> isnull(i.Phone,'')
			or isnull(h.Email,'') <> isnull(i.Email,'') or isnull(h.Country,'') <> isnull(i.Country, '')
			or isnull(h.CellPhone,'') <> isnull(i.CellPhone,'')
		end

		--Update Hire Date
		if update(HireDate)
		begin
			update dbo.bHRRM
			set HireDate = i.HireDate
			from inserted i
			join dbo.bHRRM h with (nolock) on i.PRCo = h.PRCo and i.Employee = h.PREmp
			join dbo.bHRCO o (nolock) on h.HRCo = o.HRCo and o.UpdateHireDateYN = 'Y'
			where isnull(h.HireDate,'1/1/00') <> isnull(i.HireDate,'1/1/00') 
		end

		--Update TermDate
		if update (TermDate)
		begin
			declare @termreason varchar(10)

			update dbo.bHRRM
			set TermDate = i.TermDate, TermReason = (case isnull(i.TermDate,'') when '' then @termreason else h.TermReason end)
			from inserted i
			join dbo.bHRRM h with (nolock) on i.PRCo = h.PRCo and i.Employee = h.PREmp
			join dbo.bHRCO o (nolock) on h.HRCo = o.HRCo and o.UpdateHireDateYN = 'Y'
			where isnull(h.TermDate,'1/1/00') <> isnull(i.TermDate,'1/1/00')
		end

		--Update Active Flag
		if (update(ActiveYN))
		begin
			update dbo.bHRRM
			set ActiveYN = i.ActiveYN
			from inserted i
			join dbo.bHRRM h with (nolock) on i.PRCo = h.PRCo and i.Employee = h.PREmp
			join dbo.bHRCO o (nolock) on h.HRCo = o.HRCo and o.UpdateActiveYN = 'Y'
			where h.ActiveYN <> i.ActiveYN
		end
		
		--Update Timecard Defaults
		if (update(PRDept) or update(Craft) or update(Class) or update(InsCode) or update(TaxState)
			or update(UnempState) or update(InsState) or update(LocalCode) or update(EarnCode) or 
			update(Shift) or update(HDAmt) or update(F1Amt) or update(LCFStock) or update(LCPStock) or
			update(WOTaxState) or update(WOLocalCode))
		begin
			update dbo.bHRRM
			set PRDept = i.PRDept, StdCraft = i.Craft, StdClass = i.Class, StdInsCode = i.InsCode,
			StdTaxState = i.TaxState, StdUnempState = i.UnempState, StdInsState = i.InsState, 
			StdLocal = i.LocalCode, EarnCode = i.EarnCode, Shift = i.Shift, HDAmt = i.HDAmt,
			F1Amt = i.F1Amt, LCFStock = i.LCFStock, LCPStock = i.LCPStock,
			WOTaxState = i.WOTaxState, WOLocalCode = i.WOLocalCode
			from inserted i
			join dbo.bHRRM h with (nolock) on i.PRCo = h.PRCo and i.Employee = h.PREmp
			join dbo.bHRCO o (nolock) on h.HRCo = o.HRCo and o.UpdateTimecardYN = 'Y'
			where i.PRDept <> isnull(h.PRDept, '') or isnull(i.Craft, '') <> isnull(h.StdCraft,'') or
			isnull(i.Class, '') <> isnull(h.StdClass,'') or isnull(i.InsCode,'') <> isnull(h.StdInsCode, '') or
			isnull(i.TaxState, '') <> isnull(h.StdTaxState, '') or isnull(i.UnempState,'') <> isnull(h.StdUnempState, '') or
			isnull(i.InsState,'') <> isnull(h.StdInsState,'') or isnull(i.LocalCode, '') <> isnull(h.StdLocal, '') or
			isnull(i.EarnCode,'') <> isnull(h.EarnCode, '') or isnull(i.Shift,'') <> isnull(h.Shift, '')or
			isnull(i.HDAmt, -999) <> isnull(h.HDAmt, -999) or isnull(i.F1Amt, -999) <> isnull(h.F1Amt, -999) or
			isnull(i.LCFStock, -999) <> isnull(h.LCFStock, -999) or isnull(i.LCPStock, -999) <> isnull(h.LCPStock, -999) or
			isnull(i.WOTaxState, '') <> isnull(h.WOTaxState, '') or isnull(i.WOLocalCode, '') <> isnull(h.WOLocalCode, '')
		end

		--Update W4 Info (Not HRWI - that is handled in its triggers)
		if (update(NonResAlienYN))
		begin
			update dbo.bHRRM
			set NonResAlienYN = i.NonResAlienYN
			from inserted i
			join dbo.bHRRM h with (nolock) on i.PRCo = h.PRCo and i.Employee = h.PREmp
			join dbo.bHRCO o (nolock) on h.HRCo = o.HRCo and o.UpdateW4YN = 'Y'
			where h.NonResAlienYN <> i.NonResAlienYN
		end

		--Update Occup Cat
		if (update(OccupCat) or update(CatStatus) or update(OTOpt) or update(OTSched))
		begin
			update dbo.bHRRM
			set OccupCat = i.OccupCat, CatStatus = i.CatStatus, OTOpt = i.OTOpt, OTSched = i.OTSched
			from inserted i
			join dbo.bHRRM h with (nolock) on i.PRCo = h.PRCo and i.Employee = h.PREmp
			join dbo.bHRCO o (nolock) on h.HRCo = o.HRCo and o.UpdateOccupCatYN = 'Y'
			where isnull(h.OccupCat,'') <> isnull(i.OccupCat, '') or isnull(h.CatStatus,'') <> isnull(i.CatStatus, '') or
			isnull(h.OTOpt,'') <> isnull(i.OTOpt, '') or isnull(h.OTSched,'') <> isnull(i.OTSched, '')
		end

		--Update SSN
		if (update(SSN))
		begin
			update dbo.bHRRM
			set SSN = i.SSN
			from inserted i
			join dbo.bHRRM h with (nolock) on i.PRCo = h.PRCo and i.Employee = h.PREmp
			join dbo.bHRCO o (nolock) on h.HRCo = o.HRCo and o.UpdateSSNYN = 'Y'
			where i.SSN <> isnull(h.SSN,'')
		end

	end --cross updates

--Issue 124598 - If updating earnings code and UpdatePRAEYN = 'Y' then check to see if 
--earnings code exists in PRAE.  If so, update the Rate/Amount value in PRAE with 
--bPREH.SalaryAmt value.  Code assumes Salary earnings code has been set up properly
--and is not split between sequences or set up multiple times in bPRAE for an Employee
	if update(EarnCode) or update(SalaryAmt) or update(UpdatePRAEYN)
	begin
		update dbo.bPRAE
		set RateAmt = i.SalaryAmt
		from inserted i
		join bPRAE e with (nolock) on i.PRCo = e.PRCo and i.Employee = e.Employee
		and i.EarnCode = e.EarnCode
		where i.UpdatePRAEYN = 'Y' and i.SalaryAmt <> e.RateAmt
	end
   
/* Document exporting */
declare @group tinyint, @opencursor int, @rcode int, @stdxmlformat bYN, @userstoredrroc varchar(30),
	@hqco bCompany, @hqdxcursor int, @sql varchar(300), @exportdirectory varchar(256), @msg varchar(255)
   
if exists(select top 1 i.PRCo from inserted i 
			join dbo.bHQDX d with (nolock) on d.Co = i.PRCo and d.Package = 'Employees' 
				and d.TriggerName = 'Update' and d.Enable = 'Y')
	begin
    -- Execute Export document for each customer in Inserted
   	if @numrows = 1
		begin
   		-- if only one row inserted, no cursor is needed
   		select @hqco = i.PRCo, @employee = i.Employee
   		from inserted i
   		join dbo.bHQDX d with (nolock) on d.Co = i.PRCo and d.Package = 'Employees' 
			and d.TriggerName = 'Update' and d.Enable = 'Y'
   		if @@rowcount = 0 goto btexit
   		end
   	else
   		begin
   		-- use a cursor to process inserted rows
   		declare bPREH_cursor cursor for
   		select i.PRCo, i.Employee
   		from inserted i
   		join dbo.bHQDX d with (nolock) on d.Co = i.PRCo and d.Package = 'Employees'
			and d.TriggerName = 'Update' and d.Enable = 'Y'
   		
   		open bPREH_cursor
   		select @opencursor = 1
   		
   		-- get 1st row inserted
   		fetch next from bPREH_cursor into @hqco , @employee
   		if @@fetch_status <> 0 goto btexit
   		end
   		
	PREH_export:	-- Export Employee Document
		select @stdxmlformat=null, @userstoredrroc=null, @exportdirectory = null
   
 		select @stdxmlformat=StdXMLFormat, @userstoredrroc=UserStoredProc, @exportdirectory=ExportDirectory 
   		from dbo.bHQDX d with (nolock)
   		where d.Co = @hqco and d.Package = 'Employees' and d.TriggerName = 'Update' and d.Enable = 'Y'
    
   		-- 129574 - sp_makewebtask is deprecated so removing call to proc		
     IF ISNULL(@stdxmlformat, '') <> 'Y' 
        BEGIN
            IF ISNULL(@userstoredrroc, '') <> '' 
                BEGIN	
                    SELECT  @sql = 'declare @xrcode int '
                    SELECT  @group = PRGroup
                    FROM    inserted
                    WHERE   PRCo = @hqco
                            AND Employee = @employee
                    SELECT  @sql = @sql + 'exec @xrcode = ' + @userstoredrroc
                            + ' ' 
                    SELECT  @sql = @sql + CONVERT(varchar(300), @employee)
                            + ',' 
                    SELECT  @sql = @sql + CONVERT(varchar(300), @group) + ',' 
                    SELECT  @sql = @sql + CONVERT(varchar(300), @hqco) + ',' 
                    SELECT  @sql = @sql + CHAR(39) + ISNULL(@exportdirectory,
                                                            '') + CHAR(39)
                            + ',' 
                    SELECT  @sql = @sql + CHAR(39) + '*' + CHAR(39)
   
                    EXEC(@sql)
                END
        END
   		
		-- get next row
   		if @numrows > 1
   			begin
   		   	fetch next from bPREH_cursor into @group , @employee
   		    if @@fetch_status = 0 goto PREH_export
   			end
   		end

   btexit:   /* End Document exporting */
   
/* Audit updates */
if update(LastName)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'LastName', d.LastName, i.LastName, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.LastName <> d.LastName and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(FirstName)
	begin
    insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'FirstName', d.FirstName, i.FirstName, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
	where isnull(i.FirstName,'') <> isnull(d.FirstName,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(MidName)
	begin
    insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'MidName', d.MidName, i.MidName, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.MidName,'') <> isnull(d.MidName,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(SortName)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee), 
		i.PRCo, 'C', 'SortName', d.SortName, i.SortName, getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where i.SortName <> d.SortName and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(Address)
	begin
    insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'Address', d.Address, i.Address, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.Address,'') <> isnull(d.Address,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(City)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'City', d.City, i.City, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.City,'') <> isnull(d.City,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(State)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'State', d.State, i.State, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.State,'') <> isnull(d.State,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(Zip)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'Zip', d.Zip, i.Zip, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.Zip,'') <> isnull(d.Zip,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end

if update(Country)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'Country', d.Country, i.Country, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.Country,'') <> isnull(d.Country,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end

if update(Address2)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'Address2', d.Address2, i.Address2, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.Address2,'') <> isnull(d.Address2,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(Phone)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'Phone', d.Phone, i.Phone,	getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
	where isnull(i.Phone,'') <> isnull(d.Phone,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(SSN)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'SSN', d.SSN, i.SSN, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.SSN <> d.SSN and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(Race)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'Race', d.Race, i.Race, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
	where i.Race <> d.Race and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(Sex)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'Sex', d.Sex, i.Sex, getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
    where i.Sex <> d.Sex and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(BirthDate)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'BirthDate', convert(varchar,d.BirthDate,101), convert(varchar,i.BirthDate,101), getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
    where isnull(i.BirthDate,'') <> isnull(d.BirthDate,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(HireDate)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'HireDate', convert(varchar,d.HireDate,101), convert(varchar,i.HireDate,101), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
        join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
    where isnull(i.HireDate,'') <> isnull(d.HireDate,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(TermDate)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'TermDate', convert(varchar,d.TermDate,101), convert(varchar,i.TermDate,101), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
    where isnull(i.TermDate,'') <> isnull(d.TermDate,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(PRGroup)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'PRGroup', convert(varchar,d.PRGroup), convert(varchar,i.PRGroup),	getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where i.PRGroup <> d.PRGroup and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(PRDept)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'PRDept', d.PRDept, i.PRDept, getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where i.PRDept <> d.PRDept and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(Craft)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'Craft', d.Craft, i.Craft,	getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.Craft,'') <> isnull(d.Craft,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(Class)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'Class', d.Class, i.Class,	getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.Class,'') <> isnull(d.Class,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(InsCode)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','InsCode', d.InsCode, i.InsCode, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.InsCode <> d.InsCode and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(TaxState)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'TaxState', d.TaxState, i.TaxState, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.TaxState,'') <> isnull(d.TaxState,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(UnempState)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'UnempState', d.UnempState, i.UnempState, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.UnempState <> d.UnempState and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(InsState)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'InsState', d.InsState, i.InsState, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.InsState <> d.InsState and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(LocalCode)
	begin
    insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'LocalCode', d.LocalCode, i.LocalCode, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.LocalCode,'') <> isnull(d.LocalCode,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(WOTaxState)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'WOTaxState', d.WOTaxState, i.WOTaxState, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.WOTaxState,'') <> isnull(d.WOTaxState,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(WOLocalCode)
	begin
    insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'WOLocalCode', d.WOLocalCode, i.WOLocalCode, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.WOLocalCode,'') <> isnull(d.WOLocalCode,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(GLCo)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'GLCo', convert(varchar,d.GLCo), convert(varchar,i.GLCo), getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where isnull(i.GLCo,0) <> isnull(d.GLCo,0) and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(UseState)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'UseState', d.UseState, i.UseState, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.UseState <> d.UseState and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(UseUnempState)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'UseUnempState', d.UseUnempState, i.UseUnempState, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.UseUnempState <> d.UseUnempState and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(UseInsState)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'UseInsState', d.UseInsState, i.UseInsState, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.UseInsState <> d.UseInsState and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(UseLocal)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'UseLocal', d.UseLocal, i.UseLocal, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.UseLocal <> d.UseLocal and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end	
if update(UseIns)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar(10),i.Employee),
		i.PRCo, 'C', 'UseIns', d.UseIns, i.UseIns, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
	where i.UseIns <> d.UseIns and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(JCCo)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'JCCo', convert(varchar,d.JCCo), convert(varchar,i.JCCo), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
	where isnull(i.JCCo,0) <> isnull(d.JCCo,0) and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(Job)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'Job', d.Job, i.Job, getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where isnull(i.Job,'') <> isnull(d.Job,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(Crew)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'Crew', d.Crew, i.Crew, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
	join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
	where isnull(i.Crew,'') <> isnull(d.Crew,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(LastUpdated)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'LastUpdated', convert(varchar,d.LastUpdated,101), convert(varchar,i.LastUpdated,101), getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
	join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
   	where isnull(i.LastUpdated,'') <> isnull(d.LastUpdated,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(EarnCode)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'EarnCode', convert(varchar,d.EarnCode), convert(varchar,i.EarnCode), getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.EarnCode <> d.EarnCode and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(HrlyRate)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'HrlyRate', convert(varchar,d.HrlyRate), convert(varchar,i.HrlyRate), getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
	where i.HrlyRate <> d.HrlyRate and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(SalaryAmt)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'SalaryAmt', convert(varchar,d.SalaryAmt), convert(varchar,i.SalaryAmt), getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
	where i.SalaryAmt <> d.SalaryAmt and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(OTOpt)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','OTOpt', d.OTOpt, i.OTOpt, getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.OTOpt <> d.OTOpt and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(OTSched)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'OTSched', convert(varchar,d.OTSched), convert(varchar,i.OTSched),	getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.OTSched,0) <> isnull(d.OTSched,0) and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(JCFixedRate)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','JCFixedRate', convert(varchar,d.JCFixedRate), convert(varchar,i.JCFixedRate), getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where i.JCFixedRate <> d.JCFixedRate and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(EMFixedRate)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','EMFixedRate', convert(varchar,d.EMFixedRate), convert(varchar,i.EMFixedRate), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
	where i.EMFixedRate <> d.EMFixedRate and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
end
if update(YTDSUI)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','YTDSUI', convert(varchar,d.YTDSUI), convert(varchar,i.YTDSUI),	getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where i.YTDSUI <> d.YTDSUI and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(OccupCat)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'OccupCat', d.OccupCat, i.OccupCat, getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where isnull(i.OccupCat,'') <> isnull(d.OccupCat,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(CatStatus)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'CatStatus', d.CatStatus, i.CatStatus,	getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
	where isnull(i.CatStatus,'') <> isnull(d.CatStatus,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(DirDeposit)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'DirDeposit', d.DirDeposit, i.DirDeposit, getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
	where i.DirDeposit <> d.DirDeposit and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(RoutingId)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'RoutingId', d.RoutingId, i.RoutingId,	getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where isnull(i.RoutingId,'') <> isnull(d.RoutingId,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(BankAcct)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','BankAcct', d.BankAcct, i.BankAcct,	getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
	where isnull(i.BankAcct,'') <> isnull(d.BankAcct,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(AcctType)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'AcctType', d.AcctType, i.AcctType, getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where isnull(i.AcctType,'') <> isnull(d.AcctType,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(ActiveYN)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'ActiveYN', d.ActiveYN, i.ActiveYN, getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
   	where i.ActiveYN <> d.ActiveYN and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(PensionYN)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','PensionYN', d.PensionYN, i.PensionYN,	getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where i.PensionYN <> d.PensionYN and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(CertYN)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'CertYN', d.CertYN, i.CertYN, getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.CertYN <> d.CertYN and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(ChkSort)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'ChkSort', d.ChkSort, i.ChkSort, getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where isnull(i.ChkSort,'') <> isnull(d.ChkSort,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(DefaultPaySeq)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'DefaultPaySeq', d.DefaultPaySeq, i.DefaultPaySeq, getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where i.DefaultPaySeq <> d.DefaultPaySeq and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(DDPaySeq)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','DDPaySeq', convert(varchar,d.DDPaySeq), convert(varchar,i.DDPaySeq), getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where isnull(i.DDPaySeq,0) <> isnull(d.DDPaySeq,0) and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(Suffix)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'Suffix', d.Suffix, i.Suffix, getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where isnull(i.Suffix,'') <> isnull(d.Suffix,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(TradeSeq)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'TradeSeq', convert(varchar,d.TradeSeq), convert(varchar,i.TradeSeq), getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where isnull(i.TradeSeq,0) <> isnull(d.TradeSeq,0) and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(CSLimit)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'CSLimit', convert(varchar,d.CSLimit), convert(varchar,i.CSLimit),	getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where isnull(i.CSLimit,-1) <> isnull(d.CSLimit,-1) and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(CSGarnGroup)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'CSGarnGroup', convert(varchar,d.CSGarnGroup), convert(varchar,i.CSGarnGroup),	getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where isnull(i.CSGarnGroup,0) <> isnull(d.CSGarnGroup,0) and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(CSAllocMethod)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'CSAllocMethod', d.CSAllocMethod, i.CSAllocMethod,	getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where isnull(i.CSAllocMethod,'') <> isnull(d.CSAllocMethod,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(Shift)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'Shift', convert(varchar,d.Shift), convert(varchar,i.Shift), getdate(), SUSER_SNAME()
   	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where isnull(i.Shift,0) <> isnull(d.Shift,0) and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(NonResAlienYN)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C', 'NonResAlienYN', d.NonResAlienYN, i.NonResAlienYN, getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.NonResAlienYN <> d.NonResAlienYN and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(HDAmt)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','HDAmt', convert(varchar,d.HDAmt), convert(varchar,i.HDAmt),	getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where i.HDAmt <> d.HDAmt and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(F1Amt)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','F1Amt', convert(varchar,d.F1Amt), convert(varchar,i.F1Amt),	getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where i.F1Amt <> d.F1Amt and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(LCFStock)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','LCFStock', convert(varchar,d.LCFStock), convert(varchar,i.LCFStock),	getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where i.LCFStock <> d.LCFStock and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
if update(LCPStock)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','LCPStock', convert(varchar,d.LCPStock), convert(varchar,i.LCPStock),	getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where i.LCPStock <> d.LCPStock and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end
   
if update(PayMethodDelivery)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','PayMethodDelivery', convert(varchar,d.PayMethodDelivery), convert(varchar,i.PayMethodDelivery),	getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where i.PayMethodDelivery <> d.PayMethodDelivery and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end

-- Issue 124598
if update(UpdatePRAEYN)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','UpdatePRAEYN', convert(varchar,d.UpdatePRAEYN), convert(varchar,i.UpdatePRAEYN),	getdate(), SUSER_SNAME()
	from inserted i
    join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	where i.UpdatePRAEYN <> d.UpdatePRAEYN and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
	end

IF UPDATE(ArrearsActiveYN)
BEGIN
	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
		i.PRCo, 'C','ArrearsActiveYN', convert(varchar,d.ArrearsActiveYN), convert(varchar,i.ArrearsActiveYN),	getdate(), SUSER_SNAME()
	FROM inserted i
    JOIN deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    JOIN dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	WHERE i.ArrearsActiveYN <> d.ArrearsActiveYN and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
END

-- TFS-40964 -- RecentRehireDate -- 
IF UPDATE(RecentRehireDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
			i.PRCo, 'C', 'RecentRehireDate', convert(varchar,d.RecentRehireDate,101), convert(varchar,i.RecentRehireDate,101), getdate(), SUSER_SNAME()
    FROM inserted i
    JOIN deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    JOIN dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
    WHERE isnull(i.RecentRehireDate,'') <> isnull(d.RecentRehireDate,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
END

-- TFS-40964 -- RecentSeparationDate --
IF UPDATE(RecentSeparationDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
			i.PRCo, 'C', 'RecentSeparationDate', convert(varchar,d.RecentSeparationDate,101), convert(varchar,i.RecentSeparationDate,101), getdate(), SUSER_SNAME()
    FROM inserted i
    JOIN deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    JOIN dbo.bPRCO a with (nolock) on i.PRCo = a.PRCo
    WHERE isnull(i.RecentSeparationDate,'') <> isnull(d.RecentSeparationDate,'') and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
END

-- TFS-40964 -- SeparationRedundancyRetirement --
IF UPDATE(SeparationRedundancyRetirement)
BEGIN
	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bPREH', 'PR Co#: ' + convert(varchar,i.PRCo) + ' Empl#: ' + convert(varchar,i.Employee),
			i.PRCo, 'C','SeparationRedundancyRetirement', convert(varchar,d.SeparationRedundancyRetirement), convert(varchar,i.SeparationRedundancyRetirement),	getdate(), SUSER_SNAME()
	FROM inserted i
    JOIN deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee
    JOIN dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
   	WHERE i.SeparationRedundancyRetirement <> d.SeparationRedundancyRetirement and a.AuditEmployees = 'Y' and i.AuditYN = 'Y'
END

return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Employee Header!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPREH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPREH] ON [dbo].[bPREH] ([PRCo], [Employee]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPREHSortName] ON [dbo].[bPREH] ([SortName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREH].[UseState]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREH].[UseIns]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPREH].[HrlyRate]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPREH].[SalaryAmt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPREH].[JCFixedRate]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPREH].[EMFixedRate]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPREH].[YTDSUI]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREH].[ActiveYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREH].[PensionYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREH].[PostToAll]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREH].[CertYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREH].[AuditYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREH].[DefaultPaySeq]'
GO
