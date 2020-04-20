SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************/
CREATE proc [dbo].[bspHQPRStateW2Export]
/*************************************************
* Created By:	GF	10/24/2000
* Modified By:	GF	09/20/2001	- Additional columns for MMREF changes effected June 2001
*				GF	12/08/2001	- Second W-2 filing for Ohio, for RITA agency MMREF format
*								 with local taxes city information. Added LocalCode description
*								 and Employee Local Code to output resultset.
*				GF	04/30/2002	- Rounding problem if number of employees exceeds 700. Will gain a penny.
*				RM	02/13/2004	- #23061, Add isnulls to all concatenated strings
*				GF	08/19/2004	- issue #24336 added item 43 (Health Savings Acct)
*				GF	02/10/2005	- issue #27069 added PRWS.Misc1Amt and PRWS.Misc2Amt to resultset returned.
*				EN	09/06/2005	- issue 26938 added PRWS.Misc3Amt and PRWS.Misc4Amt to resultset returned
*				GF	01/02/2005	- issue #29771 changes to MMREF-1 specs items 44 and 45.
*				GF	05/09/2006	- issue #119776 pull NJ private disability plan # from PRSI.DisabilityPlanId
*				GF	09/01/2006	- issue #121975 items 48 and 49 for roth 401(k) and 403(b) contributions.
*				GF	02/01/2007	- issue #123658 summarize IN county wages and tax into 'RE' record.
*				GF	10/27/2007	- issue #126005 changes for Marlyand, new header and employee columns
*				mh	01/28/2010	- issue #137520 changes for New Jersey Family Leave Act.
*				mh	03/11/2010	- issue #138375 - changes for OR filing.  Need to round State Tax Amounts.
*				LS	10/14/2010	- issue #141516 Remove OR State Tax rounding.
*				CHS 10/20/2010	- issue #141314 Misc box 14 for NJ
*				CHS 07/27/2011	- issue #143161 Wasn't reporting local codes when no there were no state entries
*				KK  06/25/2012  - B-08235/#145321 Expanded Tax Entity field from 5 to 10 chars
*				Dan So 07/24/2012 - D-02774 Comment out references to deleted table bPRWM
*				EN 10/31/2012 - D-05285/#146601 Removed code that retrieved PRWH Method (CoMethod) which was removed from PRWH  
*				CHS	12/04/2012	- D-04548 #145856 removed code from #143161
				CHS 01/31/2013	- #147931 added Item 55 output. 
*
* generates employee state W2 information for use in HQExport.
*
* There will be 2 record types: E=Employee, L=Local codes
*
*
* Pass:
*	PR Company, Tax Year, and State
*
**************************************/
(@prco bCompany, 
 @taxyear char(4), 
 @state bState)
 
as
set nocount on

declare @opencursor tinyint, 
		@employee bEmployee, 
		@item tinyint, 
		@colname varchar(20),
		@sql varchar(1000), 
		@amount numeric(16,2), 
		@amount1 numeric(16,2),
		@reslocalcode varchar(10), 
		@restaxtype char(1), 
		@restaxentity char(10),--B-08235/#145321
		@localcode varchar(10), 
		@taxid varchar(20), 
		@ssn varchar(9), 
		@validcnt int,
		@ohio_rita bYN, 
		@reslocaldesc bDesc, 
		@exemptions tinyint, 
		@w2count int,
		@excode bEDLCode
  
  select @opencursor = 0, @ohio_rita = 'N'
  
  -- -- -- if state is 'XA' then the state is OH, filing second W-2 for RITA agency
  -- -- -- differs from the W-2 filing for the state of Ohio.
  if @state = 'XA'
   	begin
   	select @ohio_rita = 'Y', @state = 'OH'
   	end
  
  -- W2Data temp table: E=Employee, L=Local
  Create table #W2Data
   (RecordType          char(1) null,
        PRCo            tinyint null,
        TaxYear         Char(4) null,
        -- PRWE columns
        Employee        numeric(6) null,
        SSN             varchar(9) null,
        FirstName       varchar(30) null,
        MidName         varchar(15) null,
        LastName        varchar(30) null,
        Suffix          varchar(4)  null,
        LocAddress      varchar(22) null,
        DelAddress      varchar(40) null,
        City            varchar(22) null,
        State          	varchar(2)  null,
        Zip	            varchar	(5) null,
        ZipExt      	varchar	(4) null,
        TaxState    	char(2) null,
        Statutory	    tinyint	null,
        Deceased    	tinyint	null,
        PensionPlan	    tinyint	null,
        LegalRep        tinyint null,
        DeferredComp	tinyint	null,
        CivilStatus     varchar(1) null,
        SpouseSSN       varchar(9) null,
        Misc1Amt        numeric(16,2) null,
        Misc2Amt        numeric(16,2) null,
        Misc3Amt        numeric(16,2) null, --#26938
        Misc4Amt        numeric(16,2) null, --#26938
        SUIWages        numeric(16,2) null,
        SUITaxableWages numeric(16,2) null,
        WeeksWorked     numeric(16,2) null,
        SickPay         char(1) null,
        -- PREH columns
        HireDate        smalldatetime null,
        TermDate        smalldatetime null,
  	  	EmplLocalCode	varchar(10)   null,
		-- MD Columns
		NoOfW2s			integer null,
		Exemptions		tinyint	null,
        -- PRWH columns
        EIN             char(9) null,
        PIN             varchar(17) null,
        Resub           tinyint null,
        ResubTLCN       varchar(6) null,
        CoName          varchar(57) null,
        CoLocAddress    varchar(22) null,
        CoDelAddress    varchar(40) null,
        CoCity          varchar(22) null,
        CoState         varchar(2) null,
        CoZip           varchar(5) null,
        CoZipExt        varchar(4) null,
        CoContact       varchar(27) null,
        CoPhone         varchar(15) null,
        CoPhoneExt      varchar(5) null,
        CoEmail         varchar(40) null,
        CoFax           varchar(10) null,
        CoSickPay       char(1) null,
		RepTitle		varchar(30) null,
		TaxWithheldAmt	numeric(16,2) null,
		W2TaxAmt		numeric(16,2) null,
		TaxCredits		numeric(16,2) null,
		TotalTaxDue		numeric(16,2) null,
		BalanceDue		numeric(16,2) null,
		Overpay			numeric(16,2) null,
		OverpayCredit	numeric(16,2) null,
		OverpayRefund	numeric(16,2) null,
		GrossPayroll	numeric(16,2) null,
		StatePickup		numeric(16,2) null,
        -- PRSI columns
        CoDisabilityID  varchar(20) null,
        StateId         varchar(2) null,
        -- PRWS columns
        STTaxID         varchar(20) null,
        TaxEntity       char(10) null,--B-08235/#145321
        TaxType         char(1) null,
        OptionCode1     varchar(75) null,
        OptionCode2     varchar(75) null,
        OtherStateData  varchar(10) null,
        StateControl    varchar(7)  null,
        StateWages      numeric(16,2) null,
        StateTax        numeric(16,2) null,
  	  	Misc1AmtState	numeric(16,2) null,
  	 	Misc2AmtState	numeric(16,2) null,
  	  	Misc3AmtState	numeric(16,2) null, --#26938
  	  	Misc4AmtState	numeric(16,2) null, --#26938
  	  	
  	  	--137520 Add fields to temp table for NJ FMLA
  	  	Misc1Desc varchar(20) null,
  	  	Misc2Desc varchar(20) null,
  	  	Misc3Desc varchar(20) null,
  	  	Misc4Desc varchar(20) null,
  	  	--end 137520 
  	  	
  	  	
        -- PRWA columns
        Item1Amt        numeric(16,2) null,
        Item2Amt        numeric(16,2) null,
        Item3Amt        numeric(16,2) null,
        Item4Amt        numeric(16,2) null,
        Item5Amt        numeric(16,2) null,
        Item6Amt        numeric(16,2) null,
        Item7Amt        numeric(16,2) null,
        Item8Amt        numeric(16,2) null,
        Item9Amt        numeric(16,2) null,
        Item10Amt       numeric(16,2) null,
        Item11Amt       numeric(16,2) null,
        Item12Amt       numeric(16,2) null,
        Item13Amt       numeric(16,2) null,
        Item14Amt       numeric(16,2) null,
        Item15Amt       numeric(16,2) null,
        Item16Amt       numeric(16,2) null,
        Item17Amt       numeric(16,2) null,
        Item18Amt       numeric(16,2) null,
        Item19Amt       numeric(16,2) null,
        Item20Amt       numeric(16,2) null,
        Item21Amt       numeric(16,2) null,
        Item22Amt       numeric(16,2) null,
        Item23Amt       numeric(16,2) null,
        Item24Amt       numeric(16,2) null,
        Item25Amt       numeric(16,2) null,
        Item26Amt       numeric(16,2) null,
        Item27Amt       numeric(16,2) null,
        Item28Amt       numeric(16,2) null,
        Item29Amt       numeric(16,2) null,
        Item30Amt       numeric(16,2) null,
        Item31Amt       numeric(16,2) null,
        Item32Amt       numeric(16,2) null,
        Item33Amt       numeric(16,2) null,
        Item37Amt       numeric(16,2) null,
        Item38Amt       numeric(16,2) null,
        Item42Amt       numeric(16,2) null,
		Item43Amt		numeric(16,2) null,
		Item44Amt		numeric(16,2) null,
		Item45Amt		numeric(16,2) null,
		Item46Amt		numeric(16,2) null,
		Item47Amt		numeric(16,2) null,
		Item48Amt		numeric(16,2) null,
		Item49Amt		numeric(16,2) null,
		Item50Amt		numeric(16,2) null,
		Item51Amt		numeric(16,2) null,		
		Item52Amt		numeric(16,2) null,
		Item53Amt		numeric(16,2) null,
		Item54Amt		numeric(16,2) null,						
		Item55Amt		numeric(16,2) null,
		Item56Amt		numeric(16,2) null,	

        -- Employee Misc columns
        DeferCompCont   numeric(16,2) null,
        ResLocalCode    varchar(10) null,
        ResTaxType      char(1) null,
        ResTaxEntity    char(10) null,--B-08235/#145321
        ResLocalWages   numeric(16,2) null,
        ResLocalTax     numeric(16,2) null,
        TtlLocalWages   numeric(16,2) null,
        TtlLocalTax     numeric(16,2) null,
        -- (L) type columns (Local)
        PRWL_LocalCode  varchar(10) null,
        PRWL_TaxID      varchar(20) null,
        PRWL_TaxType    char(1) null,
        PRWL_TaxEntity  char(10) null,--B-08235/#145321
        PRWL_Wages      numeric(16,2) null,
        PRWL_Tax        numeric(16,2) null,
   		ResLocalDesc	varchar(30) null
  )
  
  insert into #W2Data
    (RecordType, PRCo, TaxYear, Employee, SSN, FirstName, MidName, LastName, Suffix, LocAddress,
     DelAddress, City, State, Zip, ZipExt, TaxState, Statutory, Deceased, PensionPlan, LegalRep,
     DeferredComp, CivilStatus, SpouseSSN, Misc1Amt, Misc2Amt, Misc3Amt, Misc4Amt, SUIWages, SUITaxableWages, --#26938
     WeeksWorked, SickPay, HireDate, TermDate, EmplLocalCode, EIN, PIN, Resub, ResubTLCN, CoName, CoLocAddress,
     CoDelAddress, CoCity, CoState, CoZip, CoZipExt, CoContact, CoPhone, CoPhoneExt, CoEmail,
     CoFax, CoSickPay, CoDisabilityID, StateId, STTaxID, TaxEntity, TaxType, OptionCode1,
     OptionCode2, OtherStateData, StateControl, StateWages, StateTax, Misc1AmtState, Misc2AmtState,
	 Misc3AmtState, Misc4AmtState, RepTitle, TaxWithheldAmt, W2TaxAmt, TaxCredits,
	 TotalTaxDue, BalanceDue, Overpay, OverpayCredit, OverpayRefund, GrossPayroll,
	 StatePickup, NoOfW2s, Exemptions)
	 -- D-02774 --
	 --, Misc1Desc, Misc2Desc, Misc3Desc, Misc4Desc)
  
  --137520 Add PRWM.Misc 1-4 Desc to select.  Add PRWM to join to pull the descriptions.
  Select 'E',PRWE.PRCo, PRWE.TaxYear, PRWE.Employee, PRWE.SSN, PRWE.FirstName, PRWE.MidName,
        PRWE.LastName, PRWE.Suffix, PRWE.LocAddress, PRWE.DelAddress, PRWE.City, PRWE.State,
        PRWE.Zip, PRWE.ZipExt, PRWS.State, PRWE.Statutory, PRWE.Deceased, PRWE.PensionPlan,
        PRWE.LegalRep, PRWE.DeferredComp, PRWE.CivilStatus, PRWE.SpouseSSN, PRWE.Misc1Amt,
        PRWE.Misc2Amt, PRWE.Misc3Amt, PRWE.Misc4Amt, PRWE.SUIWages, PRWE.SUITaxableWages, PRWE.WeeksWorked, PRWE.ThirdPartySickPay, --#26938
        PREH.HireDate, PREH.TermDate, PREH.LocalCode, PRWH.EIN, PRWH.PIN, PRWH.Resub, PRWH.ResubTLCN, PRWH.CoName,
        PRWH.LocAddress, PRWH.DelAddress, PRWH.City, PRWH.State, PRWH.Zip, PRWH.ZipExt,
        PRWH.Contact, PRWH.Phone, PRWH.PhoneExt, PRWH.EMail, PRWH.Fax, PRWH.SickPayFlag,
        PRSI.DisabilityPlanId, PRSI.StateId, PRWS.TaxID, PRWS.TaxEntity, PRWS.TaxType,
        PRWS.OptionCode1, PRWS.OptionCode2,PRWS.OtherStateData, PRWS.StateControl, PRWS.Wages, PRWS.Tax,
  	  	PRWS.Misc1Amt, PRWS.Misc2Amt, PRWS.Misc3Amt, PRWS.Misc4Amt, PRWH.RepTitle,
		PRWH.TaxWithheldAmt, PRWH.W2TaxAmt, PRWH.TaxCredits, PRWH.TotalTaxDue,
		PRWH.BalanceDue, PRWH.Overpay, PRWH.OverpayCredit, PRWH.OverpayRefund,
		PRWH.GrossPayroll, PRWH.StatePickup, 0, 0
		-- D-02774 --
		--, PRWM.Misc1Desc, PRWM.Misc2Desc, PRWM.Misc3Desc, PRWM.Misc4Desc
  
  FROM PRWS JOIN PRWE ON PRWS.PRCo=PRWE.PRCo and PRWS.TaxYear=PRWE.TaxYear and PRWS.Employee=PRWE.Employee
  LEFT JOIN PRSI ON PRWS.PRCo=PRSI.PRCo and PRWS.State=PRSI.State
  LEFT JOIN PRWH ON PRWS.PRCo=PRWH.PRCo and PRWS.TaxYear=PRWH.TaxYear
  LEFT JOIN PREH ON PRWS.PRCo=PREH.PRCo and PRWS.Employee=PREH.Employee
  -- D-02774 --
  -- LEFT JOIN PRWM on PRWS.PRCo=PRWM.PRCo and PRWS.TaxYear=PRWM.TaxYear and PRWS.State = PRWM.State
  where PRWS.PRCo=@prco and PRWS.TaxYear=@taxyear and PRWS.State=@state


-- get NoOfW2s for Maryland
update #W2Data set NoOfW2s= (select count(*) from #W2Data where TaxYear=@taxyear)
where #W2Data.RecordType='E' and #W2Data.TaxYear=@taxyear

-- declare cursor on PRWE W2 employees
declare bcW2DATA cursor for select Employee, SSN
from #W2Data where RecordType='E'


    -- open cursor
    open bcW2DATA
    select @opencursor = 1
   
    -- loop through all rows in cursor
    W2DATA_LOOP:
    fetch next from bcW2DATA into @employee, @ssn
   
    if (@@fetch_status <> 0) goto W2DATA_END
   
   -- accumulate standart amounts from PRWA
   select @item = 1
   while @item < 56
        begin
        if @item < 34 or @item = 37 or @item = 38 or @item = 42 or @item=43 or @item=44 or @item=45 or @item=48 or @item=49 or @item=55
           begin
           -- get amount from PRWA
           select @amount = 0
           select @amount = isnull(sum(PRWA.Amount),0) from PRWA
           where PRWA.PRCo=@prco and PRWA.TaxYear=@taxyear and PRWA.Employee=@employee and PRWA.Item=@item
           -- update #W2Data
           select @colname = 'Item' + convert(varchar(2),@item) + 'Amt'
           select @sql = 'update #W2Data set ' + isnull(@colname,'') + ' = ' + isnull(convert(varchar(20),@amount),'')
           select @sql = @sql + ' where #W2Data.RecordType = ' + char(39) + 'E' + char(39)
           select @sql = @sql + ' and #W2Data.PRCo = ' + isnull(convert(varchar(3),@prco),'')
           select @sql = @sql + ' and #W2Data.TaxYear = ' + char(39) + isnull(@taxyear,'') + char(39)
           select @sql = @sql + ' and #W2Data.Employee = ' + isnull(convert(varchar(10),@employee),'')
           exec (@sql)
           end
   
        select @item=@item + 1
        end
   
    -- accumulate DeferCompCont from PRWA - Item 10,11,12,14
    select @amount = 0
    select @amount = isnull(sum(PRWA.Amount),0) from PRWA
    where PRWA.PRCo=@prco and PRWA.TaxYear=@taxyear and PRWA.Employee=@employee
    and (PRWA.Item=10 OR PRWA.Item=11 OR PRWA.Item=12 or PRWA.Item=14)
    -- update #W2Data
    update #W2Data set DeferCompCont=@amount
    where #W2Data.RecordType='E' and #W2Data.PRCo=@prco and #W2Data.TaxYear=@taxyear
    and #W2Data.Employee=@employee
   
    -- accumulate local wages and tax from PRWL
    select @amount = 0, @amount1 = 0
    select @amount = isnull(sum(PRWL.Wages),0), @amount1 = isnull(sum(PRWL.Tax),0)
    from PRWL where PRWL.PRCo=@prco and PRWL.TaxYear=@taxyear and PRWL.Employee=@employee
    and PRWL.State=@state
    -- update #W2Data
    update #W2Data set TtlLocalWages=@amount, TtlLocalTax=@amount1
    where #W2Data.RecordType='E' and #W2Data.PRCo=@prco and #W2Data.TaxYear=@taxyear
    and #W2Data.Employee=@employee

	-- get exemptions
	select @exemptions = 0, @excode = null
	--- - get state code from PRSI
	select @excode = TaxDedn
	from PRSI where PRCo=@prco and State='MD'
	if @excode is not null
		begin
		select @exemptions = sum(isnull(PRED.RegExempts,0) + isnull(PRED.AddExempts,0))
		from PRED where PRCo=@prco and Employee=@employee and DLCode=@excode
		-- update #W2Data
		update #W2Data set Exemptions=@exemptions
		where #W2Data.RecordType='E' and #W2Data.PRCo=@prco and #W2Data.TaxYear=@taxyear
		and #W2Data.Employee=@employee
		end
    -- get resident local code information. This is getting rather ugly.
    -- three ways of doing this currently: one for Ohio, one for Indiana, and one for all other states
    -- For Ohio, only school district local codes are considered valid.
    -- For Indiana, only county local codes are considered valid.
    if @state <> 'OH' and @state <> 'IN'
        begin
        select @reslocalcode=null, @restaxtype=null, @restaxentity=null, @amount=0, @amount1=0
        select @reslocalcode=LocalCode from PREH where PRCo=@prco and Employee=@employee
        if @reslocalcode is not null
            begin
            -- get data from PRWL
            select @restaxtype=TaxType, @restaxentity=TaxEntity, @amount=Wages, @amount1=Tax
            from PRWL where PRWL.PRCo=@prco and PRWL.TaxYear=@taxyear and PRWL.Employee=@employee
            and PRWL.State=@state and PRWL.LocalCode=@reslocalcode
            if @@rowcount <> 0
                begin
                -- update #W2Data
                update #W2Data
                set ResLocalCode=@reslocalcode, ResTaxEntity=@restaxentity, ResTaxType=@restaxtype,
                    ResLocalWages=@amount, ResLocalTax=@amount1
                where #W2Data.RecordType='E' and #W2Data.PRCo=@prco and #W2Data.TaxYear=@taxyear
                and #W2Data.Employee=@employee
                end
            end
        end
   
    if @state = 'OH' and @ohio_rita = 'N'
        begin
   
        select @reslocalcode=null, @restaxtype=null, @restaxentity=null, @amount=0, @amount1=0
        select @reslocalcode=min(LocalCode) from PRWL
        where PRCo=@prco and TaxYear=@taxyear and Employee=@employee and State=@state and TaxType='E'
        if @reslocalcode is not null
            begin
            -- get data from PRWL
            select @restaxtype=TaxType, @restaxentity=TaxEntity, @amount=Wages, @amount1=Tax
            from PRWL where PRWL.PRCo=@prco and PRWL.TaxYear=@taxyear and PRWL.Employee=@employee
            and PRWL.State=@state and PRWL.LocalCode=@reslocalcode
            if @@rowcount <> 0
                begin
                -- update #W2Data
                update #W2Data
                set ResLocalCode=@reslocalcode, ResTaxEntity=@restaxentity, ResTaxType=@restaxtype,
                    ResLocalWages=@amount, ResLocalTax=@amount1
                where #W2Data.RecordType='E' and #W2Data.PRCo=@prco and #W2Data.TaxYear=@taxyear
                and #W2Data.Employee=@employee
                end
            end
        end
   
    if @state = 'OH' and @ohio_rita = 'Y'
        begin
        select @reslocalcode=null, @restaxtype=null, @restaxentity=null, @amount=0, @amount1=0
        select @reslocalcode=min(LocalCode) from PRWL
        where PRCo=@prco and TaxYear=@taxyear and Employee=@employee and State=@state and TaxType='C'
        if @reslocalcode is not null
            begin
            -- get data from PRWL
            select @restaxtype=TaxType, @restaxentity=TaxEntity, @amount=Wages, @amount1=Tax
            from PRWL where PRWL.PRCo=@prco and PRWL.TaxYear=@taxyear and PRWL.Employee=@employee
            and PRWL.State=@state and PRWL.LocalCode=@reslocalcode
            if @@rowcount <> 0
                begin
   			 select @reslocaldesc=Description from PRLI where PRCo=@prco and LocalCode=@reslocalcode
   			 if @@rowcount = 0 select @reslocaldesc=null
                -- update #W2Data
                update #W2Data
                set ResLocalCode=@reslocalcode, ResTaxEntity=@restaxentity, ResTaxType=@restaxtype,
                    ResLocalWages=@amount, ResLocalTax=@amount1, ResLocalDesc=@reslocaldesc
                where #W2Data.RecordType='E' and #W2Data.PRCo=@prco and #W2Data.TaxYear=@taxyear
                and #W2Data.Employee=@employee
                end
            end
        end
   
 	--#141314
    if @state = 'NJ'
        begin

		declare @Desc1 bDesc, @Desc2 bDesc, @Desc3 bDesc, @Desc4 bDesc;

		with MiscBox14_CTE
		as
		(select [1] AS MiscDesc1, [2] AS MiscDesc2, [3] AS MiscDesc3, [4] AS MiscDesc4
		from (select h.Description, row_number() over (partition by d.PRCo, d.TaxYear, d.State, d.Employee order by d.LineNumber) as LineNumber
			  from dbo.bPRW2MiscDetail d
			  join dbo.bPRW2MiscHeader h on h.PRCo = d.PRCo and h.TaxYear = d.TaxYear and h.State = d.State and h.LineNumber = d.LineNumber
			  where d.PRCo = @prco and d.TaxYear = @taxyear and d.State = @state and d.Employee = @employee)As T1
		Pivot
		(
		Max(Description)
		for LineNumber in ([1], [2], [3], [4])
		) as T2)
		select @Desc1 = MiscDesc1, @Desc2 = MiscDesc2, @Desc3 = MiscDesc3, @Desc4 = MiscDesc4 from MiscBox14_CTE;


		declare @Amt1 bDollar, @Amt2 bDollar, @Amt3 bDollar, @Amt4 bDollar;

		with MiscBox14_CTE
		as
		(select [1] AS Misc1, [2] AS Misc2, [3] AS Misc3, [4] AS Misc4
		from (select d.Amount, row_number() over (partition by d.PRCo, d.TaxYear, d.State, d.Employee order by d.LineNumber) as LineNumber
			  from dbo.bPRW2MiscDetail d
			  join dbo.bPRW2MiscHeader h on h.PRCo = d.PRCo and h.TaxYear = d.TaxYear and h.State = d.State and h.LineNumber = d.LineNumber
			  where d.PRCo = @prco and d.TaxYear = @taxyear and d.State = @state and d.Employee = @employee)As T1
		Pivot
		(
		Max(Amount)
		for LineNumber in ([1], [2], [3], [4])
		) as T2)
		
		select @Amt1 = Misc1, @Amt2 = Misc2, @Amt3 = Misc3, @Amt4 = Misc4 from MiscBox14_CTE;


		update #W2Data 
		set 
			Misc1AmtState = @Amt1, Misc2AmtState = @Amt2,  Misc3AmtState = @Amt3, Misc4AmtState = @Amt4, 
			Misc1Desc = @Desc1, Misc2Desc = @Desc2, Misc3Desc = @Desc3, Misc4Desc = @Desc4
		
        where #W2Data.RecordType='E' and #W2Data.PRCo=@prco and #W2Data.TaxYear=@taxyear
		and #W2Data.Employee=@employee
		
        end   
           
    if @state = 'IN'
        begin
        select @reslocalcode=null, @restaxtype=null, @restaxentity=null, @amount=0, @amount1=0
		--- change to get summary of local wages
		select @reslocalcode=l.LocalCode, @restaxtype=l.TaxType, @restaxentity=l.TaxEntity
		from PRWL l where l.PRCo=@prco and l.TaxYear=@taxyear and l.Employee=@employee
		and l.State=@state and l.TaxType='D' 
		and l.Wages = (select max(Wages) from PRWL w where l.PRCo=w.PRCo and l.State=w.State
				and l.Employee=Employee and l.TaxYear=w.TaxYear and w.TaxType=l.TaxType)
		---- now sum wages and tax
		select @amount=sum(Wages), @amount1=sum(Tax)
		from PRWL where PRCo=@prco and TaxYear=@taxyear and Employee=@employee and State=@state and TaxType='D'
		---- update #W2Data
		update #W2Data set ResLocalCode=@reslocalcode, ResTaxEntity=@restaxentity,
						   ResTaxType=@restaxtype, ResLocalWages=@amount, ResLocalTax=@amount1
		where #W2Data.RecordType='E' and #W2Data.PRCo=@prco and #W2Data.TaxYear=@taxyear
		and #W2Data.Employee=@employee
		end

-- --         select @reslocalcode=min(LocalCode) from PRWL
-- --         where PRCo=@prco and TaxYear=@taxyear and Employee=@employee and State=@state and TaxType='D'
-- --         if @reslocalcode is not null
-- --             begin
-- --             -- get data from PRWL
-- --           select @restaxtype=TaxType, @restaxentity=TaxEntity, @amount=Wages, @amount1=Tax
-- --             from PRWL where PRWL.PRCo=@prco and PRWL.TaxYear=@taxyear and PRWL.Employee=@employee
-- --             and PRWL.State=@state and PRWL.LocalCode=@reslocalcode
-- --             if @@rowcount <> 0
-- --                 begin
-- --           -- update #W2Data
-- --                 update #W2Data
-- --                 set ResLocalCode=@reslocalcode, ResTaxEntity=@restaxentity, ResTaxType=@restaxtype,
-- --                     ResLocalWages=@amount, ResLocalTax=@amount1
-- --                 where #W2Data.RecordType='E' and #W2Data.PRCo=@prco and #W2Data.TaxYear=@taxyear
-- --                 and #W2Data.Employee=@employee
-- --                 end
-- --             end
-- --         end
   
    -- get type (L) records from PRWL and insert into #W2Data
    -- do not insert a (L) record if already in (E)mployee record as the reslocalcode
    -- if state is Ohio and not RITA filing, only TaxType = 'E' are valid
    -- if state is Ohio and a RITA filing, only TaxType = 'C' are valid
    -- if state is Indiana, only TaxType = 'D' are valid
    select @localcode = min(LocalCode) from PRWL where PRCo=@prco and TaxYear=@taxyear
    and Employee=@employee and State=@state
    while @localcode is not null
    begin
        select @taxid=TaxID, @restaxtype=TaxType, @restaxentity=TaxEntity, @amount=Wages, @amount1=Tax
        from PRWL where PRCo=@prco and TaxYear=@taxyear and Employee=@employee and State=@state
        and LocalCode=@localcode
        if @@rowcount <> 0
            begin
   		 select @reslocaldesc=Description from PRLI where PRCo=@prco and LocalCode=@localcode
   		 if @@rowcount = 0 select @reslocaldesc=null
            -- check if already in #W2Data (E) record type as reslocalcode
            select @validcnt=count(*) from #W2Data
            where RecordType='E' and PRCo=@prco and TaxYear=@taxyear and Employee=@employee
            and ResLocalCode=@localcode
            if @validcnt = 0
                begin
                if @state <> 'OH' and @state <> 'IN'
                    begin
                    -- insert record type (L) in #W2Data
                    insert into #W2Data (RecordType, PRCo, TaxYear, Employee, SSN, TaxState,
                        PRWL_LocalCode, PRWL_TaxID, PRWL_TaxType, PRWL_TaxEntity, PRWL_Wages, PRWL_Tax)
                    select 'L', @prco, @taxyear, @employee, @ssn, @state, @localcode, @taxid, @restaxtype,
                        @restaxentity, @amount, @amount1
                    end
   
                if @state = 'OH' and @ohio_rita = 'N' and @restaxtype = 'E'
                    begin
                    -- insert record type (L) in #W2Data
                    insert into #W2Data (RecordType, PRCo, TaxYear, Employee, SSN, TaxState,
                        PRWL_LocalCode, PRWL_TaxID, PRWL_TaxType, PRWL_TaxEntity, PRWL_Wages, PRWL_Tax)
                    select 'L', @prco, @taxyear, @employee, @ssn, @state, @localcode, @taxid, @restaxtype,
                        @restaxentity, @amount, @amount1
                    end
   
   			 if @state = 'OH' and @ohio_rita = 'Y' and @restaxtype = 'C'
                    begin
                    -- insert record type (L) in #W2Data
                    insert into #W2Data (RecordType, PRCo, TaxYear, Employee, SSN, TaxState,
                        PRWL_LocalCode, PRWL_TaxID, PRWL_TaxType, PRWL_TaxEntity, PRWL_Wages, PRWL_Tax, ResLocalDesc)
                    select 'L', @prco, @taxyear, @employee, @ssn, @state, @localcode, @taxid, @restaxtype,
                        @restaxentity, @amount, @amount1, @reslocaldesc
                    end
   
-- --                 if @state = 'IN' and @restaxtype = 'D'
-- --                     begin
-- --                     -- insert record type (L) in #W2Data
-- --                     insert into #W2Data (RecordType, PRCo, TaxYear, Employee, SSN, TaxState,
-- --                         PRWL_LocalCode, PRWL_TaxID, PRWL_TaxType, PRWL_TaxEntity, PRWL_Wages, PRWL_Tax)
-- --                     select 'L', @prco, @taxyear, @employee, @ssn, @state, @localcode, @taxid, @restaxtype,
-- --                         @restaxentity, @amount, @amount1
-- --                     end
                end
            end
   
    -- next local code
    select @localcode = min(LocalCode) from PRWL where PRCo=@prco and TaxYear=@taxyear
    and Employee=@employee and State=@state and LocalCode>@localcode
    end
   
    goto W2DATA_LOOP
   
    W2DATA_END: -- no more cursor rows
        if @opencursor = 1
            begin
            close bcW2DATA
            deallocate bcW2DATA
            end


---- select the results
if @state <> 'MD'
	begin
	--137520 Add Misc1-4Desc to returned recordset.
	--issue #138375 Added 'OR' into case statement for State tax to round to whole dollar.
	--issue #141516 Remove 'OR' case statement for State tax rounding.
	select a.RecordType, a.PRCo, a.TaxYear, a.Employee, a.SSN, a.FirstName, a.MidName, a.LastName,
			a.Suffix, a.LocAddress, a.DelAddress, a.City, a.State, a.Zip, a.ZipExt, a.TaxState,
			a.Statutory, a.Deceased, a.PensionPlan, a.LegalRep, a.DeferredComp, a.CivilStatus,
			a.SpouseSSN, a.Misc1Amt, a.Misc2Amt, a.Misc3Amt, a.Misc4Amt, 'SUIWages'=convert(decimal(16,2),a.SUIWages), --#26938
   		  'SUITaxableWages'=convert(decimal(16,2),a.SUITaxableWages), a.WeeksWorked,
			a.SickPay, a.HireDate, a.TermDate, a.EmplLocalCode,
			a.EIN, a.PIN, a.Resub, a.ResubTLCN, a.CoName, a.CoLocAddress, a.CoDelAddress, a.CoCity,
			a.CoState, a.CoZip, a.CoZipExt, a.CoContact, a.CoPhone, a.CoPhoneExt, a.CoEmail, a.CoFax,
			a.CoSickPay, a.CoDisabilityID, a.StateId, a.STTaxID, a.TaxEntity, a.TaxType,
			a.OptionCode1, a.OptionCode2,
			a.OtherStateData, a.StateControl, 'StateWages'=convert(decimal(16,2),a.StateWages),
   		  --'StateTax'=case @state when 'OR' then round(convert(decimal(16,2),a.StateTax),0) else convert(decimal(16,2),a.StateTax) end, --#141516
   		  'StateTax'=convert(decimal(16,2),a.StateTax),
   		    a.Misc1AmtState, a.Misc2AmtState, a.Misc3AmtState, a.Misc4AmtState,
			a.RepTitle, a.TaxWithheldAmt, a.W2TaxAmt, a.TaxCredits, a.TotalTaxDue, a.BalanceDue,
			a.Overpay, a.OverpayCredit, a.OverpayRefund, a.GrossPayroll, a.StatePickup,
  		  a.Item1Amt, a.Item2Amt,
			a.Item3Amt, a.Item4Amt, a.Item5Amt, a.Item6Amt, a.Item7Amt, a.Item8Amt, a.Item9Amt,
			a.Item10Amt, a.Item11Amt, a.Item12Amt, a.Item13Amt, a.Item14Amt, a.Item15Amt, a.Item16Amt,
			a.Item17Amt, a.Item18Amt, 'Item19Amt'=convert(decimal(16,2),a.Item19Amt), a.Item20Amt, a.Item21Amt, a.Item22Amt, a.Item23Amt,
			a.Item24Amt, a.Item25Amt, a.Item26Amt, a.Item27Amt, a.Item28Amt, a.Item29Amt, a.Item30Amt,
			a.Item31Amt, a.Item32Amt, a.Item33Amt, a.Item37Amt, a.Item38Amt, a.Item42Amt, a.Item43Amt,
   		   a.Item44Amt, a.Item45Amt, a.Item48Amt, a.Item49Amt, a.Item50Amt, a.Item51Amt, a.Item52Amt, 
   		   a.Item53Amt, a.Item54Amt, a.Item55Amt, a.Item56Amt, a.DeferCompCont,
			a.ResLocalCode, a.ResTaxType, a.ResTaxEntity, 'ResLocalWages'=convert(decimal(16,2),a.ResLocalWages),
   		  'ResLocalTax'=convert(decimal(16,2),a.ResLocalTax), 'TtlLocalWages'=convert(decimal(16,2),a.TtlLocalWages),
			'TtlLocalTax'=convert(decimal(16,2),a.TtlLocalTax), a.PRWL_LocalCode, a.PRWL_TaxID, a.PRWL_TaxType,
   		  a.PRWL_TaxEntity, a.PRWL_Wages, a.PRWL_Tax, a.ResLocalDesc, a.Exemptions, a.NoOfW2s,
			a.Misc1Desc,
			a.Misc2Desc,
			a.Misc3Desc,
			a.Misc4Desc

	from #W2Data a
	ORDER BY a.PRCo, a.TaxYear, a.Employee, a.RecordType
	end
else
	begin
	select a.RecordType, a.PRCo, a.TaxYear, a.Employee, a.SSN, a.FirstName, a.MidName, a.LastName,
			a.Suffix, a.LocAddress, a.DelAddress, a.City, a.State, a.Zip, a.ZipExt, a.TaxState,
			a.Statutory, a.Deceased, a.PensionPlan, a.LegalRep, a.DeferredComp, a.CivilStatus,
			a.SpouseSSN, a.Misc1Amt, a.Misc2Amt, a.Misc3Amt, a.Misc4Amt, 'SUIWages'=convert(decimal(16,2),a.SUIWages), --#26938
   		  'SUITaxableWages'=convert(decimal(16,2),a.SUITaxableWages), a.WeeksWorked,
			a.SickPay, a.HireDate, a.TermDate, a.EmplLocalCode,
			a.EIN, a.PIN, a.Resub, a.ResubTLCN, a.CoName, a.CoLocAddress, a.CoDelAddress, a.CoCity,
			a.CoState, a.CoZip, a.CoZipExt, a.CoContact, a.CoPhone, a.CoPhoneExt, a.CoEmail, a.CoFax,
			a.CoSickPay, a.CoDisabilityID, a.StateId, a.STTaxID, a.TaxEntity, a.TaxType,
			a.OptionCode1, a.OptionCode2,
			a.OtherStateData, a.StateControl, 'StateWages'=convert(decimal(16,2),a.StateWages),
   		  'StateTax'= convert(decimal(16,2),a.StateTax), a.Misc1AmtState, a.Misc2AmtState, a.Misc3AmtState, a.Misc4AmtState,
			a.RepTitle, a.TaxWithheldAmt, a.W2TaxAmt, a.TaxCredits, a.TotalTaxDue, a.BalanceDue,
			a.Overpay, a.OverpayCredit, a.OverpayRefund, a.GrossPayroll, a.StatePickup,
  		  a.Item1Amt, a.Item2Amt,
			a.Item3Amt, a.Item4Amt, a.Item5Amt, a.Item6Amt, a.Item7Amt, a.Item8Amt, a.Item9Amt,
			a.Item10Amt, a.Item11Amt, a.Item12Amt, a.Item13Amt, a.Item14Amt, a.Item15Amt, a.Item16Amt,
			a.Item17Amt, a.Item18Amt, 'Item19Amt'=convert(decimal(16,2),a.Item19Amt), a.Item20Amt, a.Item21Amt, a.Item22Amt, a.Item23Amt,
			a.Item24Amt, a.Item25Amt, a.Item26Amt, a.Item27Amt, a.Item28Amt, a.Item29Amt, a.Item30Amt,
			a.Item31Amt, a.Item32Amt, a.Item33Amt, a.Item37Amt, a.Item38Amt, a.Item42Amt, a.Item43Amt,
   		   a.Item44Amt, a.Item45Amt, a.Item48Amt, a.Item49Amt, a.Item50Amt, a.Item51Amt, a.Item52Amt, 
   		   a.Item53Amt, a.Item54Amt, a.Item55Amt, a.Item56Amt, a.DeferCompCont,
			a.ResLocalCode, a.ResTaxType, a.ResTaxEntity, 'ResLocalWages'=convert(decimal(16,2),a.ResLocalWages),
   		  'ResLocalTax'=convert(decimal(16,2),a.ResLocalTax), 'TtlLocalWages'=convert(decimal(16,2),a.TtlLocalWages),
			'TtlLocalTax'=convert(decimal(16,2),a.TtlLocalTax), a.PRWL_LocalCode, a.PRWL_TaxID, a.PRWL_TaxType,
   		  a.PRWL_TaxEntity, a.PRWL_Wages, a.PRWL_Tax, a.ResLocalDesc, a.Exemptions, a.NoOfW2s

	from #W2Data a
	where a.RecordType <> 'L'
	ORDER BY a.PRCo, a.TaxYear, a.Employee, a.RecordType
	end

GO
GRANT EXECUTE ON  [dbo].[bspHQPRStateW2Export] TO [public]
GO
