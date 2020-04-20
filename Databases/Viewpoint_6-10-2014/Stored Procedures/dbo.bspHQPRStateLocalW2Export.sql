SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************/
 CREATE   proc [dbo].[bspHQPRStateLocalW2Export]
/*******************************************************
* Created By:	GF 09/03/2003
* Modified By:	RM 02/13/04 = #23061, Add isnulls to all concatenated strings
*				GF 08/19/2004 - issue #24336 added item 43 (Health Savings Acct) 
*				EN 9/06/05 - issue 26938 added PRWS.Misc3Amt and PRWS.Misc4Amt to resultset returned
*				GF 01/24/2005 - issue #29771 changes to MMREF-1 specs items 44 and 45.
*				GF 07/31/2006 - issue #122028 changes to return columns for RW records.
*				GF 09/01/2006 - issue #121975 items 48 and 49 for roth 401(k) and 403(b) contributions.
*				GF 09/13/2007 - issue #125470 added ResLocalTaxID for Philadelphia local filing.
*				CHS 07/27/2011	- issue #143161 Wasn't reporting local codes when no there were no state entries
*				KK  06/25/2012  - B-08235/#145321 Expanded Tax Entity field from 5 to 10 chars
*				EN 10/31/2012 - D-05285/#146601 Removed code that retrieved PRWH Method (CoMethod) which was removed from PRWH   
*				CHS	12/04/2012	- D-04548 #145856 improved code from #143161
*				CHS	12/04/2012	- D-04548 #145856 improved code from #143161 Fixed breakage from earlier - TaxID, OptionCode1,OptionCode2, OtherStateData, StateControl.
*				CHS	01/10/2013	- D-06486 TK-20707 #147814 Fixed problem with the join had PREH.Employee and it should have been PRWL.Employee
*
* generates employee state local information. Called from W2 form, currently
* only MMREF format is supported. Order will be by employee then local code.
*
* There will be 2 record types: E=Employee, L=Local codes
*
*
* This is a very confusing stored procedure. Here is an attempt to explain what is was, what it is, and what it should be.
* 
*	This SP was originally written with the SP bspHQPRStateW2Export used as a template. Because of this, this SP originally 
*	collected one state record from PRWS and inserted it into the temp table #W2Data with a rectype of 'E'. This 'E' record 
*	was then associated with a PRWL record. Then a subsequent cursor loop collected and inserted any appropriate remianing 
*	PRWL records with a record type of 'L'.
*
*	Originally, the E record TaxEntity column (and others like it) would contain the value PRWS.TaxEntity. The L records would 
*	then hold the value PRWL.TaxEntity. This became a problem with the E records so the column ResTaxEntity was later added.
*	
*	In form code, in numerous places it checks to see if the record type is E reocrd and if so use ResTaxEntity. And like wise,  
*	if record type is an L record then use the value of TaxEntity.
*
*	It was found that this design was flawwed in that it required the existance of a PRWS record before it would collect the 
*	PRWL records. Some states do not have an income tax while at the same time, they will have local tax entities. So you can have
*	PRWL records when there are no PRWS records. So this SP was re-written to not use PRWS and to use PRWL for the initial E record
*	to be inserted. We had to keep the E and L records as there are many refences to them in from code.
*
*	So as a result, there is much duplication of the field TaxEntity (and others like it). TaxEntity, ResTaxEntity, and PRWL_TaxEntity
*	all hold the same value. If we were to remove the duplicate columns, we would need to fix the form code as well and then test
*	ALL of the local codes that we export.
*
*	Much of the code below could be replaced with one set based insertion of PRWL records into the temp table #W2Data. At the initial
*	insert they would all be set to a L record type. Then subsequent code would set the first row to be a record type of E. 
*	Also, all of the code that inserts values in the the 'ItemXXAmt' columns in the E record would have to be retained in order
*	to be compatible with existing form code.
*
*	Note: because values in the E and L records are now the same, any place they a referenced in form code could be replaced with
*	one reference. The only exception being the references to the 'ItemXXAmt' columns in the E record.
*
* Pass:
*	PR Company, Tax Year, and State
*
**************************************/
(@prco bCompany, 
 @taxyear char(4), 
 @state bState, 
 @localcodelist varchar(2000))

as
set nocount on

declare @opencursor int, 
		@opencursor2 int, 
		@employee bEmployee, 
		@item tinyint, 
		@colname varchar(20),
		@sql varchar(1000), 
		@amount numeric(16,2), 
		@amount1 numeric(16,2), 
		@localcode varchar(10), 
		@taxtype char(1), 
		@taxentity char(10), --B-08235/#145321
		@taxid varchar(20), 
		@ssn varchar(9), 
		@validcnt int, 
		@localdesc bDesc

select @opencursor = 0, @opencursor2 = 0
  
  -- W2Data temp table: E=Employee, L=Local
  Create table #W2Data
  (RecordType		char(1) null,
   PRCo				tinyint null,
   TaxYear			Char(4) null,
   -- PRWE columns
   Employee			numeric(6) null,
   SSN             	varchar(9) null,
   FirstName       	varchar(30) null,
   MidName         	varchar(15) null,
   LastName        	varchar(30) null,
   Suffix          	varchar(4)  null,
   LocAddress      	varchar(22) null,
   DelAddress      	varchar(40) null,
   City            	varchar(22) null,
   State          	varchar(2)  null,
   Zip	            varchar	(5) null,
   ZipExt      		varchar	(4) null,
   TaxState    		char(2) null,
   Statutory	    tinyint	null,
   Deceased    		tinyint	null,
   PensionPlan	    tinyint	null,
   LegalRep        	tinyint null,
   DeferredComp		tinyint	null,
   CivilStatus     	varchar(1) null,
   SpouseSSN       	varchar(9) null,
   Misc1Amt        	numeric(16,2) null,
   Misc2Amt        	numeric(16,2) null,
   Misc3Amt        	numeric(16,2) null, --#26938
   Misc4Amt        	numeric(16,2) null, --#26938
   SUIWages        	numeric(16,2) null,
   SUITaxableWages 	numeric(16,2) null,
   WeeksWorked     	numeric(16,2) null,
   SickPay         	char(1) null,
   -- PREH columns
   HireDate        	smalldatetime null,
   TermDate        	smalldatetime null,
   EmplLocalCode	 	varchar(10)   null,
   -- PRWH columns
   EIN             	char(9) null,
   PIN             	varchar(17) null,
   Resub           	tinyint null,
   ResubTLCN       	varchar(6) null,
   CoName          	varchar(57) null,
   CoLocAddress    	varchar(22) null,
   CoDelAddress    	varchar(40) null,
   CoCity          	varchar(22) null,
   CoState         	varchar(2) null,
   CoZip           	varchar(5) null,
   CoZipExt        	varchar(4) null,
   CoContact       	varchar(27) null,
   CoPhone         	varchar(15) null,
   CoPhoneExt      	varchar(5) null,
   CoEmail         	varchar(40) null,
   CoFax           	varchar(10) null,
   CoSickPay       	char(1) null,
   CoDisabilityID  	varchar(20) null,
   -- PRSI columns
   StateId         	varchar(2) null,
   -- PRWS columns
   STTaxID         	varchar(20) null,
   TaxEntity       	char(10) null,--B-08235/#145321
   TaxType         	char(1) null,
   OptionCode1     	varchar(75) null,
   OptionCode2     	varchar(75) null,
   OtherStateData  	varchar(10) null,
   StateControl    	varchar(7)  null,
   StateWages      	numeric(16,2) null,
   StateTax        	numeric(16,2) null,
   Misc1AmtState	numeric(16,2) null,
   Misc2AmtState	numeric(16,2) null,
   Misc3AmtState	numeric(16,2) null, --#26938
   Misc4AmtState	numeric(16,2) null, --#26938
   -- PRWA columns
   Item1Amt        	numeric(16,2) null,
   Item2Amt        	numeric(16,2) null,
   Item3Amt        	numeric(16,2) null,
   Item4Amt        	numeric(16,2) null,
   Item5Amt        	numeric(16,2) null,
   Item6Amt        	numeric(16,2) null,
   Item7Amt        	numeric(16,2) null,
   Item8Amt        	numeric(16,2) null,
   Item9Amt        	numeric(16,2) null,
   Item10Amt       	numeric(16,2) null,
   Item11Amt       	numeric(16,2) null,
   Item12Amt       	numeric(16,2) null,
   Item13Amt       	numeric(16,2) null,
   Item14Amt       	numeric(16,2) null,
   Item15Amt       	numeric(16,2) null,
   Item16Amt       	numeric(16,2) null,
   Item17Amt       	numeric(16,2) null,
   Item18Amt       	numeric(16,2) null,
   Item19Amt       	numeric(16,2) null,
   Item20Amt       	numeric(16,2) null,
   Item21Amt       	numeric(16,2) null,
   Item22Amt       	numeric(16,2) null,
   Item23Amt       	numeric(16,2) null,
   Item24Amt       	numeric(16,2) null,
   Item25Amt       	numeric(16,2) null,
   Item26Amt       	numeric(16,2) null,
   Item27Amt       	numeric(16,2) null,
   Item28Amt       	numeric(16,2) null,
   Item29Amt       	numeric(16,2) null,
   Item30Amt       	numeric(16,2) null,
   Item31Amt       	numeric(16,2) null,
   Item32Amt       	numeric(16,2) null,
   Item33Amt       	numeric(16,2) null,
   Item37Amt       	numeric(16,2) null,
   Item38Amt       	numeric(16,2) null,
   Item42Amt       	numeric(16,2) null,
   Item43Amt		numeric(16,2) null,
   Item44Amt		numeric(16,2) null,
   Item45Amt		numeric(16,2) null,
   Item46Amt		numeric(16,2) null,
   Item47Amt		numeric(16,2) null,
   Item48Amt		numeric(16,2) null,
   Item49Amt		numeric(16,2) null,
   -- Employee Misc columns
   DeferCompCont   	numeric(16,2) null,
   ResLocalCode    	varchar(10) null,
   ResLocalTaxID	varchar(20) null,
   ResTaxType      	char(1) null,
   ResTaxEntity    	char(10) null,--B-08235/#145321
   ResLocalWages   	numeric(16,2) null,
   ResLocalTax     	numeric(16,2) null,
   TtlLocalWages   	numeric(16,2) null,
   TtlLocalTax     	numeric(16,2) null,
   -- (L) type columns (Local)
   PRWL_LocalCode  	varchar(10) null,
   PRWL_TaxID      	varchar(20) null,
   PRWL_TaxType    	char(1) null,
   PRWL_TaxEntity  	char(10) null,--B-08235/#145321
   PRWL_Wages      	numeric(16,2) null,
   PRWL_Tax        	numeric(16,2) null,
   ResLocalDesc	 	varchar(30) null
   )
  

insert into #W2Data (RecordType, PRCo, TaxYear, Employee, SSN, FirstName, MidName, LastName, Suffix, 
	LocAddress, DelAddress, City, State, Zip, ZipExt, TaxState, Statutory, Deceased, PensionPlan, 
	LegalRep, DeferredComp, CivilStatus, SpouseSSN, Misc1Amt, Misc2Amt, Misc3Amt, Misc4Amt, SUIWages, SUITaxableWages, --#26938
	WeeksWorked, SickPay, HireDate, TermDate, EmplLocalCode, EIN, PIN, Resub, ResubTLCN, CoName, 
	CoLocAddress, CoDelAddress, CoCity, CoState, CoZip, CoZipExt, CoContact, CoPhone, CoPhoneExt, 
	CoEmail, CoFax, CoSickPay, CoDisabilityID, StateId, STTaxID, TaxEntity, TaxType, 
	OptionCode1, OptionCode2, OtherStateData, StateControl, StateWages, StateTax,  Misc1AmtState, Misc2AmtState, Misc3AmtState, Misc4AmtState)

Select 'E',PRWE.PRCo, PRWE.TaxYear,  PRWE.Employee, PRWE.SSN, PRWE.FirstName, PRWE.MidName, PRWE.LastName, 
	PRWE.Suffix, PRWE.LocAddress, PRWE.DelAddress, PRWE.City, PRWE.State, PRWE.Zip, PRWE.ZipExt, 
	PRWL.State, PRWE.Statutory, PRWE.Deceased, PRWE.PensionPlan, PRWE.LegalRep, PRWE.DeferredComp, 
	PRWE.CivilStatus, PRWE.SpouseSSN, PRWE.Misc1Amt, PRWE.Misc2Amt, PRWE.Misc3Amt, PRWE.Misc4Amt, PRWE.SUIWages, PRWE.SUITaxableWages, --#26938
	PRWE.WeeksWorked, PRWE.ThirdPartySickPay, PREH.HireDate, PREH.TermDate, PREH.LocalCode, PRWH.EIN, PRWH.PIN, 
	PRWH.Resub, PRWH.ResubTLCN, PRWH.CoName, PRWH.LocAddress, PRWH.DelAddress, PRWH.City, PRWH.State, PRWH.Zip, 
	PRWH.ZipExt, PRWH.Contact, PRWH.Phone, PRWH.PhoneExt, PRWH.EMail, PRWH.Fax, PRWH.SickPayFlag,
	null, PRSI.StateId, PRWS.TaxID, PRWL.TaxEntity, PRWL.TaxType, PRWS.OptionCode1, 
	PRWS.OptionCode2, PRWS.OtherStateData, PRWS.StateControl, 0, 0,
	0, 0, 0, 0

FROM PRWL with (nolock) 
	JOIN PRWE with (nolock) ON PRWL.PRCo=PRWE.PRCo and PRWL.TaxYear=PRWE.TaxYear and PRWL.Employee=PRWE.Employee
	LEFT JOIN PRSI with (nolock) ON PRWL.PRCo=PRSI.PRCo and PRWL.State=PRSI.State
	LEFT JOIN PRWH with (nolock) ON PRWL.PRCo=PRWH.PRCo and PRWL.TaxYear=PRWH.TaxYear
	LEFT JOIN PREH with (nolock) ON PRWL.PRCo=PREH.PRCo and PRWL.Employee=PREH.Employee
	LEFT JOIN PRWS with (nolock) ON PRWL.PRCo=PRWS.PRCo and PRWL.TaxYear=PRWS.TaxYear and PRWL.Employee=PRWS.Employee and PRWL.State=PRWS.State	
WHERE PRWL.PRCo=@prco 
	AND PRWL.TaxYear=@taxyear 
	AND PRWL.State=@state  
	AND PRWL.LocalCode =
	  (
	  SELECT MIN(PRWL2.LocalCode)
	  FROM PRWL PRWL2
	  WHERE PRWL.PRCo = PRWL2.PRCo
	  AND PRWL.TaxYear = PRWL2.TaxYear
	  AND PRWL.State = PRWL2.State
	  AND PRWL.Employee = PRWL2.Employee
	  )	
						
 
  -- declare cursor on PRWE W2 employees
  declare bcW2DATA cursor LOCAL FAST_FORWARD
  for select Employee, SSN
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
  while @item < 50
       begin
       if @item < 34 or @item = 37 or @item = 38 or @item = 42 or @item = 43 or @item=44 or @item=45 or @item=48 or @item=49
          begin
          -- get amount from PRWA
          select @amount = 0
          select @amount = isnull(sum(PRWA.Amount),0) from PRWA with (nolock)
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
  select @amount = isnull(sum(PRWA.Amount),0) from PRWA with (nolock)
  where PRWA.PRCo=@prco and PRWA.TaxYear=@taxyear and PRWA.Employee=@employee
  and (PRWA.Item=10 OR PRWA.Item=11 OR PRWA.Item=12 or PRWA.Item=14)
  -- update #W2Data
  update #W2Data set DeferCompCont=@amount
  where #W2Data.RecordType='E' and #W2Data.PRCo=@prco and #W2Data.TaxYear=@taxyear
  and #W2Data.Employee=@employee
  
  -- accumulate local wages and tax from PRWL
  select @amount = 0, @amount1 = 0
  select @amount = isnull(sum(PRWL.Wages),0), @amount1 = isnull(sum(PRWL.Tax),0)
  from PRWL with (nolock) where PRWL.PRCo=@prco and PRWL.TaxYear=@taxyear and PRWL.Employee=@employee
  and PRWL.State=@state
  -- update #W2Data
  update #W2Data set TtlLocalWages=@amount, TtlLocalTax=@amount1
  where #W2Data.RecordType='E' and #W2Data.PRCo=@prco and #W2Data.TaxYear=@taxyear
  and #W2Data.Employee=@employee
  
  
  
  -- need to use min(LocalCode) from PRWL that has been selected for export (i.e. localcodes)
  -- when one found, put local code data into record 'E' - employee resident columns
  select @localcode=null, @taxtype=null, @taxentity=null, @amount=0, @amount1=0
  -- declare cursor on PRWL for employee
  declare bcPRWL cursor LOCAL FAST_FORWARD
  for select LocalCode, TaxID, TaxType, TaxEntity, Wages, Tax
  from PRWL where PRCo=@prco and TaxYear=@taxyear and Employee=@employee and State=@state
  
  -- open cursor
  open bcPRWL
  set @opencursor2 = 1
  
  -- loop through all rows in cursor
  PRWL_LOOP:
  fetch next from bcPRWL into @localcode, @taxid, @taxtype, @taxentity, @amount, @amount1
  
  if (@@fetch_status <> 0) goto PRWL_END
  
  -- check if local code is in list, if not found go to next
  if charindex(';' + rtrim(@localcode) + ';', @localcodelist) = 0
  	goto PRWL_LOOP
  
  -- get local code description
  select @localdesc=Description from PRLI with (nolock) where PRCo=@prco and LocalCode=@localcode
  if @@rowcount = 0 select @localdesc=null
  
  -- check if local code info already in #W2Data (E) record type as reslocalcode
  if exists(select 1 from #W2Data where RecordType='E' and PRCo=@prco and TaxYear=@taxyear 
  				and Employee=@employee and isnull(ResLocalCode,'') = '')
  	begin
  	update #W2Data set ResLocalCode = @localcode, ResLocalTaxID = @taxid, ResTaxType = @taxtype,
						ResTaxEntity = @taxentity, ResLocalWages = @amount, ResLocalTax = @amount1,
						ResLocalDesc = @localdesc
  	where #W2Data.RecordType='E' and #W2Data.PRCo=@prco and #W2Data.TaxYear=@taxyear and #W2Data.Employee=@employee
  	end
  else
  	begin
  	-- insert record type (L) in #W2Data
  	insert into #W2Data (RecordType, PRCo, TaxYear, Employee, SSN, FirstName, MidName, LastName, Suffix, 
  		LocAddress, DelAddress, City, State, Zip, ZipExt, TaxState, Statutory, Deceased, PensionPlan, 
  		LegalRep, DeferredComp, CivilStatus, SpouseSSN, Misc1Amt, Misc2Amt, Misc3Amt, Misc4Amt, SUIWages, SUITaxableWages, --#26938
  		WeeksWorked, SickPay, HireDate, TermDate, EmplLocalCode, EIN, PIN, Resub, ResubTLCN, CoName, 
  		CoLocAddress, CoDelAddress, CoCity, CoState, CoZip, CoZipExt, CoContact, CoPhone, CoPhoneExt, 
  		CoEmail, CoFax, CoSickPay, CoDisabilityID, StateId, STTaxID, TaxEntity, TaxType, 
  		OptionCode1, OptionCode2, OtherStateData, StateControl, StateWages, StateTax,
  		PRWL_LocalCode, PRWL_TaxID, PRWL_TaxType, PRWL_TaxEntity, PRWL_Wages, PRWL_Tax, ResLocalDesc)
  
  	select 'L', @prco, @taxyear, @employee, a.SSN, a.FirstName, a.MidName, a.LastName, a.Suffix,
  		a.LocAddress, a.DelAddress, a.City, a.State, a.Zip, a.ZipExt, @state, a.Statutory, a.Deceased, 
  		a.PensionPlan, a.LegalRep, a.DeferredComp, a.CivilStatus, a.SpouseSSN, a.Misc1Amt, a.Misc2Amt, a.Misc3Amt, a.Misc4Amt, --#26938
  		a.SUIWages, a.SUITaxableWages, a.WeeksWorked, a.SickPay, a.HireDate, a.TermDate, a.EmplLocalCode, 
  		a.EIN, a.PIN, a.Resub, a.ResubTLCN, a.CoName, a.CoLocAddress, a.CoDelAddress, a.CoCity, a.CoState, 
  		a.CoZip, a.CoZipExt, a.CoContact, a.CoPhone, a.CoPhoneExt, a.CoEmail, a.CoFax, a.CoSickPay, 
  		null, a.StateId, a.STTaxID, a.TaxEntity, a.TaxType, a.OptionCode1, a.OptionCode2, 
  		a.OtherStateData, a.StateControl, a.StateWages, a.StateTax,
  		@localcode, @taxid, @taxtype, @taxentity, @amount, @amount1, @localdesc
  	from #W2Data a where a.RecordType='E' and a.PRCo=@prco and a.TaxYear=@taxyear and a.Employee=@employee
  
  	end
  
  
  goto PRWL_LOOP
  
  
  PRWL_END: -- end of local codes for employee
  if @opencursor2 = 1
  	begin
  	close bcPRWL
  	deallocate bcPRWL
  	set @opencursor2 = 0
  	end
  
  -- goto next employee record
  goto W2DATA_LOOP
  
  
  W2DATA_END: -- no more cursor rows
  	if @opencursor = 1
  		begin
  		close bcW2DATA
  		deallocate bcW2DATA
  		set @opencursor = 0
  		end
  
  
  -- cleanup - need to remove 'E' records with no local codes
  delete from #W2Data where isnull(ResLocalCode,'') = ''
  and not exists(select 1 from #W2Data a where a.RecordType='L' and a.PRCo=#W2Data.PRCo 
  					and a.TaxYear=#W2Data.TaxYear and a.Employee=#W2Data.Employee)
  
  
  -- select the results
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
  	 'StateTax'=convert(decimal(16,2),a.StateTax), a.Misc1AmtState, a.Misc2AmtState, a.Misc3AmtState, a.Misc4AmtState,
	   a.Item1Amt, a.Item2Amt, a.Item3Amt, a.Item4Amt, a.Item5Amt, a.Item6Amt, a.Item7Amt, a.Item8Amt, a.Item9Amt,
       a.Item10Amt, a.Item11Amt, a.Item12Amt, a.Item13Amt, a.Item14Amt, a.Item15Amt, a.Item16Amt,
       a.Item17Amt, a.Item18Amt, 'Item19Amt'=convert(decimal(16,2),a.Item19Amt), a.Item20Amt, a.Item21Amt, a.Item22Amt, a.Item23Amt,
       a.Item24Amt, a.Item25Amt, a.Item26Amt, a.Item27Amt, a.Item28Amt, a.Item29Amt, a.Item30Amt,
  	a.Item31Amt, a.Item32Amt, a.Item33Amt, a.Item37Amt, a.Item38Amt, a.Item42Amt, a.Item43Amt,
 	a.Item44Amt, a.Item45Amt, a.Item48Amt, a.Item49Amt, a.DeferCompCont,
  	a.ResLocalCode, a.ResLocalTaxID, a.ResTaxType, a.ResTaxEntity, 'ResLocalWages'=convert(decimal(16,2),a.ResLocalWages),
  	 'ResLocalTax'=convert(decimal(16,2),a.ResLocalTax), 'TtlLocalWages'=convert(decimal(16,2),a.TtlLocalWages),
  	'TtlLocalTax'=convert(decimal(16,2),a.TtlLocalTax), a.PRWL_LocalCode, a.PRWL_TaxID, a.PRWL_TaxType,
  	a.PRWL_TaxEntity, a.PRWL_Wages, a.PRWL_Tax, a.ResLocalDesc
  
  from #W2Data a
  ORDER BY a.PRCo, a.TaxYear, a.Employee, a.RecordType, a.PRWL_TaxEntity, a.PRWL_LocalCode

GO
GRANT EXECUTE ON  [dbo].[bspHQPRStateLocalW2Export] TO [public]
GO
