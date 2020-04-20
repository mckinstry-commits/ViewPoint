SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************
* Copyright © 2013 Viewpoint Construction Software. All rights reserved.
* Created: CWirtz	9/20/2010 Issue 123660
* Modified:  
* 	JE change 11/2/99 to add Local description to procedure
*   DH 10/26/2001 change to allow mult states/locals on 1 W2 and 2001 Requirements
*   DH 10/15/2003 Added join of PRWS in RecordSort 2 Section for State Copies - issue 20272
*	NF 09/30/04 Added PRWA.ItemID for Box 12 year code Issue 23612/23605
*   NF 10/10/04 Added With(nolock) to joins for Issue 25929
* 	NF 09/14/05 Add code for Misc 3 and 4 Desc and Amt Issue 26979
*   NF 9/27/06 Format Box12Code to Char (2) for all 4 Codes Issue 122599
* 	CWirtz	9/20/2010 Issue 123660 Allow printing of 2nd page W2 when Box 12 and Box 14
* 		contain more than 4 now-zero entries. Viewpoint limits their W2s to only 2 pages.
* 	
* 
******************************************************************/
     
		    CREATE           proc [dbo].[brptPRW2]

         (@PRCo bCompany, @TaxYear char(4), @BegEmp bEmployee =0, @EndEmp bEmployee=999999, @RptType char(1) = 'S',
         @BegEmpName varchar (15)=' ', @EndEmpName varchar(15)='zzzzzzzzzzzzzzz')

--Uncomment the following parameters for debug purposes
--         (@PRCo bCompany = 124
--		, @TaxYear char(4) = '2010'
--		, @BegEmp bEmployee =0
--		, @EndEmp bEmployee=999999
--		, @RptType char(1) = 'S'
--		, @BegEmpName varchar (15)=' '
--		, @EndEmpName varchar(15)='zzzzzzzzzzzzzzz')

         AS

         Create table #W2Data
          
         (PRCo tinyint null,
          TaxYear Char(4) null,
          Employee numeric(6) null,
          FederalWages    numeric(16,2) null,
          FederalTaxWH    numeric(16,2) null,
          SocSecWages     numeric(16,2) null,
          SocSecTaxWH     numeric(16,2) null,
          MedicareWages   numeric(16,2) null,
          MedicareTaxWH   numeric(16,2) null,
          SocSecTips      numeric(16,2) null,
          AdvanceEIC      numeric(16,2) null,
          DepCareBenefits numeric(16,2) null,
          NonQualified    numeric(16,2) null,
          FringeBenefits  numeric(16,2) null,
          AllocatedTips   numeric(16,2) null,
          Box12aCode	  char(2) null,
          Box12bCode      char(2) null,
          Box12cCode      char(2) null,
          Box12dCode      char(2) null,
          Box12eCode	  char(2) null,  --Second Page of W2 Box 12
          Box12fCode      char(2) null,  --Second Page of W2 Box 12
          Box12gCode      char(2) null,  --Second Page of W2 Box 12
          Box12hCode      char(2) null,  --Second Page of W2 Box 12

          Box12aAmount    numeric (16,2) null,
          Box12bAmount    numeric (16,2) null,
          Box12cAmount    numeric (16,2) null,
          Box12dAmount    numeric (16,2) null,
          Box12eAmount    numeric (16,2) null,  --Second Page of W2 Box 12
          Box12fAmount    numeric (16,2) null,  --Second Page of W2 Box 12
          Box12gAmount    numeric (16,2) null,  --Second Page of W2 Box 12
          Box12hAmount    numeric (16,2) null,  --Second Page of W2 Box 12

  		  Box12aItemID	char(2) null,
  		  Box12bItemID	char(2) null,
  		  Box12cItemID	char(2) null,
  		  Box12dItemID	char(2) null,
  		  Box12eItemID	char(2) null,  --Second Page of W2 Box 12
  		  Box12fItemID	char(2) null,  --Second Page of W2 Box 12
  		  Box12gItemID	char(2) null,  --Second Page of W2 Box 12
  		  Box12hItemID	char(2) null)  --Second Page of W2 Box 12



       
      
         Create Table #EmpState
     	(PRCo tinyint,
     	 TaxYear char(4),
     	 Employee int,
     	 RecordSort tinyint null, /*1=Federal records, 2=Federal(Page 2),3=State records, 4=State(Page 2), 5=Local records*/
         RecordType char (1), /*F=Federal , S=State, L=Local*/
     	 State1 char(4) null,
     	 State1TaxID varchar(20) null,
     	 State2 char(4)null,
     	 State2TaxID varchar(20) null,
     	 Local1 varchar(10) null,
     	 Local1TaxID varchar(20) null,
     	 Local2 varchar(10) null,
     	 Local2TaxID varchar(20) null,
     	 State1Wages numeric (16,2) null,
     	 State1Tax numeric (16,2) null,
     	 State2Wages numeric (16,2) null,
     	 State2Tax numeric (16,2) null,
     	 Local1Wages numeric (16,2) null,
     	 Local1Tax numeric (16,2) null,
     	 Local2Wages numeric (16,2) null,
     	 Local2Tax numeric (16,2) null,
     	 StateMisc1Amt numeric (16,2) null,
     	 StateMisc2Amt numeric (16,2) null,
	  	 StateMisc3Amt numeric (16,2) null,
  		 StateMisc4Amt numeric (16,2) null,
     	 StateMisc5Amt numeric (16,2) null,  -- State Page 2 of W2
     	 StateMisc6Amt numeric (16,2) null,  -- State Page 2 of W2
  		 StateMisc7Amt numeric (16,2) null,  -- State Page 2 of W2
  		 StateMisc8Amt numeric (16,2) null,  -- State Page 2 of W2
		 W2sGeneratedCount int null)
     
      create clustered index biEmpState on #EmpState(PRCo,TaxYear, Employee)   

Set NoCount On 
     
   --Page 2 of W2
 
         Create Table #EmpStatePage2
     	(PRCo tinyint,
     	 TaxYear char(4),
     	 Employee int,
     	 RecordSort tinyint null, /*1=Federal records, 2=Federal(Page 2),3=State records, 4=State(Page 2), 5=Local records*/
         RecordType char (1), /*F=Federal , F=Federal(Page 2), S=State, S=State(Page 2), L=Local*/
     	 State1 char(4) null,
     	 State1TaxID varchar(20) null,
     	 State2 char(4)null,
     	 State2TaxID varchar(20) null,
     	 Local1 varchar(10) null,
     	 Local1TaxID varchar(20) null,
     	 Local2 varchar(10) null,
     	 Local2TaxID varchar(20) null,
     	 State1Wages numeric (16,2) null,
     	 State1Tax numeric (16,2) null,
     	 State2Wages numeric (16,2) null,
     	 State2Tax numeric (16,2) null,
     	 Local1Wages numeric (16,2) null,
     	 Local1Tax numeric (16,2) null,
     	 Local2Wages numeric (16,2) null,
     	 Local2Tax numeric (16,2) null,
     	 StateMisc1Amt numeric (16,2) null,
     	 StateMisc2Amt numeric (16,2) null,
  		 StateMisc3Amt numeric (16,2) null,
  		 StateMisc4Amt numeric (16,2) null,
     	 StateMisc5Amt numeric (16,2) null,  -- State Page 2 of W2
     	 StateMisc6Amt numeric (16,2) null,  -- State Page 2 of W2
  		 StateMisc7Amt numeric (16,2) null,  -- State Page 2 of W2
  		 StateMisc8Amt numeric (16,2) null,  -- State Page 2 of W2
		 W2sGeneratedCount int null)
     
      create clustered index biEmpStatePage2 on #EmpStatePage2(PRCo,TaxYear, Employee)   
    --Page 2 of W2 END


create table #PRW2LocalState
       (PRCo tinyint, 
        TaxYear char(4), 
        Employee int,
   	State char(4) null,
     	StateTaxID varchar(20) null,
     	LocalTaxID varchar(20) null,
   	StateWages numeric (16,2) null,
     	StateTax numeric (16,2) null,
   	Misc1Amt numeric (16,2) null, 
   	Misc2Amt numeric (16,2) null,
  	Misc3Amt numeric (16,2) null,
  	Misc4Amt numeric (16,2) null, 
   	Misc5Amt numeric (16,2) null, -- State Page 2 of W2 
   	Misc6Amt numeric (16,2) null, -- State Page 2 of W2
  	Misc7Amt numeric (16,2) null, -- State Page 2 of W2
  	Misc8Amt numeric (16,2) null, -- State Page 2 of W2

   	LocalCode varchar(10) null,
     	LocalWages numeric (16,2) null,
     	LocalTax numeric (16,2) null)
   
create clustered index biPRW2LocalState  on #PRW2LocalState(PRCo,TaxYear, Employee, State)  


/* Table Box12Entries in table Box12Entries will be use to determine if a W2 second page is required.
More than 4 entries for box 12 will require a second page*/
CREATE TABLE #W2Box12Entries
       (PRCo tinyint, 
        TaxYear char(4), 
        Employee int,
   		Box12Entries int)

INSERT INTO #W2Box12Entries
SELECT  PRCo,TaxYear, Employee,max (CountItem) AS Box12Entries FROM brvPRW2Box12
GROUP BY  PRCo,TaxYear, Employee

/* Table PRW2EmployeeCounts will count the number of W2s per employee
by 1)Number Of W2s Per Employee (copies B,C,2)  2)Number Of Employee W2s Per Employee(copy C)
3)Number Of State W2s Per Employee (copy 2) 4)Number Of Local W2s Per Employee (copy 2 local only)*/
CREATE TABLE #W2EmployeeCounts
       (PRCo tinyint, 
        TaxYear char(4), 
        Employee int,
		NumberOfW2sPerEmployee int,
		NumberOfFedW2sPerEmployee int,
   		NumberOfEmpW2sPerEmployee int,
		NumberOfStateW2sPerEmployee int,
		NumberOfLocalW2sPerEmployee int
)

--Extract all possible state and local combinations.  Remember A state may only have local taxes(ie no entry in table PRWS).  
--However, the local table PRWL does carry the state value.
insert into #PRW2LocalState

Select PRCo=isnull(PRWS.PRCo,PRWL.PRCo), TaxYear=isnull(PRWS.TaxYear,PRWL.TaxYear), Employee=isnull(PRWS.Employee,PRWL.Employee),
       State=isnull(PRWS.State,PRWL.State) ,StateTaxID=PRWS.TaxID, LocalTaxID=PRWL.TaxID,
       StateWages=PRWS.Wages,
       StateTax=PRWS.Tax,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,  --State Misc1Amt 
       PRWL.LocalCode,
       LocalWages=PRWL.Wages,
       LocalTax=PRWL.Tax
 From PRWS with(nolock)
      Full Outer Join PRWL with(nolock) 
         on PRWL.PRCo=PRWS.PRCo and PRWL.TaxYear=PRWS.TaxYear 
            and PRWL.Employee=PRWS.Employee and PRWL.State=PRWS.State 


     WHERE isnull(PRWS.PRCo,PRWL.PRCo)=@PRCo and isnull(PRWS.TaxYear,PRWL.TaxYear)=@TaxYear 
           and isnull(PRWS.Employee, PRWL.Employee)>=@BegEmp and isnull(PRWS.Employee, PRWL.Employee)<=@EndEmp
           and isnull(PRWL.PRCo,PRWS.PRCo)=@PRCo and isnull(PRWL.TaxYear,PRWS.TaxYear)=@TaxYear 
           and isnull(PRWL.Employee,PRWS.Employee)>=@BegEmp and isnull(PRWL.Employee,PRWS.Employee)<=@EndEmp
               
/* Update local state table with state box 14 information */
UPDATE dbo.#PRW2LocalState 
	SET  Misc1Amt = e.Amount1
		,Misc2Amt = e.Amount2
		,Misc3Amt = e.Amount3
		,Misc4Amt = e.Amount4
		,Misc5Amt = e.Amount5
		,Misc6Amt = e.Amount6
		,Misc7Amt = e.Amount7
		,Misc8Amt = e.Amount8
FROM #PRW2LocalState d LEFT OUTER JOIN brvPRW2Box14StateEntries e
		  ON d.PRCo=e.PRCo and d.TaxYear=e.TaxYear 
            and d.Employee=e.Employee and d.State=e.State 
        

         /*******************************/
         /*  insert Employee level details */
         /******************************/
INSERT into #W2Data
         (PRCo, TaxYear, Employee, FederalWages, FederalTaxWH, SocSecWages, SocSecTaxWH, MedicareWages,
          MedicareTaxWH, SocSecTips, AdvanceEIC, DepCareBenefits,
          NonQualified,  FringeBenefits, AllocatedTips, 
          Box12aCode, Box12aAmount, Box12aItemID, Box12bCode, Box12bAmount, Box12bItemID,
          Box12cCode, Box12cAmount, Box12cItemID, Box12dCode, Box12dAmount, Box12dItemID,
          Box12eCode, Box12eAmount, Box12eItemID, Box12fCode, Box12fAmount, Box12fItemID,  --Second Page of W2 Box 12
          Box12gCode, Box12gAmount, Box12gItemID, Box12hCode, Box12hAmount, Box12hItemID)  --Second Page of W2 Box 12

         
      
         Select PRWA.PRCo, PRWA.TaxYear, PRWA.Employee, 
          FederalWages= sum(case PRWA.Item when 1 then PRWA.Amount else 0 end),
          FederalTaxWH= sum(case PRWA.Item when 2 then PRWA.Amount else 0 end),
          SocSecWages= sum(case PRWA.Item when 3 then PRWA.Amount else 0 end),
          SocSecTaxWH= sum(case PRWA.Item when 4 then PRWA.Amount else 0 end),
          MedicareWages=sum(case PRWA.Item when 5 then PRWA.Amount else 0 end),
          MedicareTaxWH=sum(case PRWA.Item when 6 then PRWA.Amount else 0 end),
          SocSecTips=sum(case PRWA.Item when 7 then PRWA.Amount else 0 end),
          AdvanceEIC=sum(case PRWA.Item when 8 then PRWA.Amount else 0 end),
          DepCareBenefits=sum(case PRWA.Item when 9 then PRWA.Amount else 0 end),
          NonQualified=sum(case when PRWA.Item = 16 or PRWA.Item = 17 then PRWA.Amount else 0 end),
          FringeBenefits=sum(case PRWA.Item when 18 then PRWA.Amount else 0 end),
          AllocatedTips=sum(case PRWA.Item when 20 then PRWA.Amount else 0 end),
      
		Box12aCode=max(case when b12.CountItem=1 then b12.W2Code end),
          Box12aAmount=max(case when b12.CountItem=1 then b12.Amount end),
          Box12aItemID=max(case when b12.CountItem=1 then b12.ItemID end),
		Box12bCode=max(case when b12.CountItem=2 then b12.W2Code end),
          Box12bAmount=max(case when b12.CountItem=2 then b12.Amount end),
  		  Box12bItemID=max(case when b12.CountItem=2 then b12.ItemID end),
		Box12cCode=max(case when b12.CountItem=3 then b12.W2Code end),
          Box12cAmount=max(case when b12.CountItem=3 then b12.Amount end),
  	      Box12cItemID=max(case when b12.CountItem=3 then b12.ItemID end),
		Box12dCode=max(case when b12.CountItem=4 then b12.W2Code end),
          Box12dAmount=max(case when b12.CountItem=4 then b12.Amount end),
          Box12dItemID=max(case when b12.CountItem=4 then b12.ItemID end),

		Box12eCode=max(case when b12.CountItem=5 then b12.W2Code end),		  --Second Page of W2 Box 12
          Box12eAmount=max(case when b12.CountItem=5 then b12.Amount end),	  --Second Page of W2 Box 12
          Box12eItemID=max(case when b12.CountItem=5 then b12.ItemID end),	  --Second Page of W2 Box 12
		Box12fCode=max(case when b12.CountItem=6 then b12.W2Code end),		  --Second Page of W2 Box 12
          Box12fAmount=max(case when b12.CountItem=6 then b12.Amount end),	  --Second Page of W2 Box 12
          Box12fItemID=max(case when b12.CountItem=6 then b12.ItemID end),	  --Second Page of W2 Box 12
		Box12gCode=max(case when b12.CountItem=7 then b12.W2Code end),		  --Second Page of W2 Box 12
          Box12gAmount=max(case when b12.CountItem=7 then b12.Amount end),	  --Second Page of W2 Box 12
          Box12gItemID=max(case when b12.CountItem=7 then b12.ItemID end),	  --Second Page of W2 Box 12
		Box12hCode=max(case when b12.CountItem=8 then b12.W2Code end),		  --Second Page of W2 Box 12
          Box12hAmount=max(case when b12.CountItem=8 then b12.Amount end),	  --Second Page of W2 Box 12
          Box12hItemID=max(case when b12.CountItem=8 then b12.ItemID end)	  --Second Page of W2 Box 12


           
         FROM  PRWA with(nolock)
         Join PREH with(nolock) on PREH.PRCo=PRWA.PRCo and PREH.Employee=PRWA.Employee
         Left Outer JOIN brvPRW2Box12 b12 with(nolock) 
			ON PRWA.PRCo=b12.PRCo and PRWA.TaxYear=b12.TaxYear and PRWA.Employee=b12.Employee and PRWA.Item=b12.Item
                                                       and b12.Seq=PRWA.Seq
         Where PRWA.PRCo=@PRCo and PRWA.TaxYear=@TaxYear and PRWA.Employee>=@BegEmp and PRWA.Employee<=@EndEmp
               and PREH.SortName >= @BegEmpName and PREH.SortName <= @EndEmpName
      
         Group by PRWA.PRCo, PRWA.TaxYear, PRWA.Employee
         
 /***********
      Insert every other employee/state/local record. This will insert the correct number of records needed for W2 Copies B and C  (RecordSort 1)
      For the PR Co and Tax Year, get the max employee state/local record (table B) that is less than or equal to
      the state+local from table A.  The having clause then further restricts the recordset to every other record
     ************/
        
     insert into #EmpState
     select a.PRCo, TaxYear, a.Employee, 1, 'F', a.State, StateTaxID, NULL, NULL, a.LocalCode, LocalTaxID, NULL, NULL, 
            StateWages, StateTax, 0, 0, LocalWages, LocalTax, 0, 0
		, Misc1Amt, Misc2Amt, Misc3Amt, Misc4Amt 
		, Misc5Amt, Misc6Amt, Misc7Amt, Misc8Amt 
		,NULL
     From #PRW2LocalState a
     Join PREH with(nolock) on PREH.PRCo=a.PRCo and PREH.Employee=a.Employee
     Where a.PRCo=@PRCo and a.TaxYear=@TaxYear and a.Employee >= @BegEmp and a.Employee <= @EndEmp
       and PREH.SortName >= @BegEmpName and PREH.SortName <= @EndEmpName and
          a.State+isnull(a.LocalCode,' ') = (select max(b.State+isnull(b.LocalCode,' ')) From #PRW2LocalState b
            					where a.PRCo=b.PRCo and a.TaxYear=b.TaxYear and a.Employee=b.Employee
            					and b.State+isnull(b.LocalCode,' ')<=a.State+isnull(a.LocalCode,' ')
            					and b.PRCo=@PRCo and b.TaxYear=@TaxYear having count(*)%2=1)
     

--Check if there are employees receiving only a federal w2 and create it if required.
--i.e. there are not any state or local wages associated with this employee.
INSERT INTO #EmpState
     SELECT a.PRCo, a.TaxYear, a.Employee, 1, 'F'
			, b.State, StateTaxID, NULL, NULL, b.LocalCode, b.LocalTaxID, NULL, NULL
            , b.StateWages, b.StateTax, 0, 0, b.LocalWages, b.LocalTax, 0, 0
			, b.Misc1Amt, b.Misc2Amt, b.Misc3Amt, b.Misc4Amt 
			, b.Misc5Amt, b.Misc6Amt, b.Misc7Amt, b.Misc8Amt 
		    ,NULL
	FROM  #W2Data a LEFT OUTER JOIN #PRW2LocalState b
		ON a.PRCo = b.PRCo AND a.TaxYear = b.TaxYear AND a.Employee = b.Employee
	WHERE b.PRCo is null

     /**********
      Update second state and local that will print on the employee Fed and Copy C W2's.  
      For the PR Co Tax Year, and employee, update state2 and local2 with the mininum state+local
      greater than each employee's state+local
     ********/
     
     update #EmpState Set State2=s.State, State2TaxID=StateTaxID, Local2=s.LocalCode, Local2TaxID=LocalTaxID, State2Wages=s.StateWages, Local2Wages=s.LocalWages, 
                          State2Tax=StateTax, Local2Tax=LocalTax
			, StateMisc1Amt=s.Misc1Amt, StateMisc2Amt=s.Misc2Amt, StateMisc3Amt=s.Misc3Amt, StateMisc4Amt=s.Misc4Amt
			, StateMisc5Amt=s.Misc5Amt, StateMisc6Amt=s.Misc6Amt, StateMisc7Amt=s.Misc7Amt, StateMisc8Amt=s.Misc8Amt  
          from #EmpState, #PRW2LocalState s where #EmpState.PRCo=s.PRCo and #EmpState.TaxYear=s.TaxYear and #EmpState.Employee=s.Employee
               and s.State+isnull(s.LocalCode,' ')=(select min(a.State+isnull(a.LocalCode,' ')) From #PRW2LocalState a
               					where a.PRCo=s.PRCo and a.TaxYear=s.TaxYear and a.Employee=s.Employee
     						and a.State+isnull(a.LocalCode,' ')>#EmpState.State1+isnull(#EmpState.Local1,' ')) 
     


----@@@@@@@@@@@@@@@@@ Page 2 START  --FEDERAL W2 Not duplicate entry
     insert into #EmpStatePage2
    select 
     	a.PRCo, a.TaxYear, a.Employee, 2, max(a.RecordType)

, max(a.State1), max(a.State1TaxID), max(a.State2)
		,max(a.State2TaxID), max(a.Local1), max(a.Local1TaxID), max(a.Local2), max(a.Local2TaxID), max(a.State1Wages), max(a.State1Tax)
		,max(a.State2Wages), max(a.State2Tax), max(a.Local1Wages), max(a.Local1Tax), max(a.Local2Wages), max(a.Local2Tax)
		,max(a.StateMisc1Amt), max(a.StateMisc2Amt), max(a.StateMisc3Amt), max(a.StateMisc4Amt)
		,max(a.StateMisc5Amt), max(a.StateMisc6Amt), max(a.StateMisc7Amt), max(a.StateMisc8Amt)
		,max(a.W2sGeneratedCount)
from      #EmpState  a 
LEFT OUTER JOIN #W2Box12Entries c
	ON a.PRCo = c.PRCo AND a.TaxYear = c.TaxYear AND a.Employee = c.Employee AND a.RecordType='F'
LEFT OUTER JOIN brvPRW2Box14FederalEntries d
	ON a.PRCo = d.PRCo AND a.TaxYear = d.TaxYear AND a.Employee = d.Employee AND a.RecordType='F'
WHERE c.Box12Entries > 4 OR d.FederalEntries >4
GROUP BY a.PRCo, a.TaxYear, a.Employee

--@@@@@@@@@@@@@@@@@ Page 2 END  --FEDERAL W2 Not duplicate entry


     /*********
      Insert records needed for each state/local W2.  RecordSort=3.  Insert local info also; needed to print locals on state copies
     **********/
     
     insert into #EmpState
     select a.PRCo, a.TaxYear, a.Employee, 3, 'S', a.State, a.StateTaxID, NULL, NULL, a.LocalCode, a.LocalTaxID, NULL, NULL, a.StateWages, a.StateTax, 0, 0, a.LocalWages, a.LocalTax, 0, 0, 
     a.Misc1Amt, a.Misc2Amt, a.Misc3Amt, a.Misc4Amt  --Wrong Fields
    ,a.Misc5Amt, a.Misc6Amt, a.Misc7Amt, a.Misc8Amt  --Wrong Fields
	,NULL
     From #PRW2LocalState a
     Join PREH with(nolock) on PREH.PRCo=a.PRCo and PREH.Employee=a.Employee
     Join PRWS with(nolock) on PRWS.PRCo=a.PRCo and PRWS.TaxYear=a.TaxYear and PRWS.Employee=a.Employee and PRWS.State=a.State 
                  --and (PRWS.Wages<>0 or PRWS.Tax<>0)
     Where 
       a.PRCo=@PRCo and a.TaxYear=@TaxYear and a.Employee >= @BegEmp and a.Employee <= @EndEmp
      and PREH.SortName >= @BegEmpName and PREH.SortName <= @EndEmpName
      and isnull(a.LocalCode,' ') = (select max(isnull(b.LocalCode,' ')) From #PRW2LocalState b
            					where a.PRCo=b.PRCo and a.TaxYear=b.TaxYear and a.Employee=b.Employee and a.State=b.State 
            					and isnull(b.LocalCode,' ')<=isnull(a.LocalCode,' ')
            					and b.PRCo=@PRCo and b.TaxYear=@TaxYear having count(*)%2=1)
     
     /*****
      Update Local 2 info on State Records (RecordSort =3)
     ******/
     
     update #EmpState Set Local2=s.LocalCode, Local2TaxID=LocalTaxID, Local2Wages=s.LocalWages, 
                          Local2Tax=LocalTax
, StateMisc1Amt=s.Misc1Amt, StateMisc2Amt=s.Misc2Amt, StateMisc3Amt=s.Misc3Amt, StateMisc4Amt=s.Misc4Amt
, StateMisc5Amt=s.Misc5Amt, StateMisc6Amt=s.Misc6Amt, StateMisc7Amt=s.Misc7Amt, StateMisc8Amt=s.Misc8Amt

          from #EmpState, #PRW2LocalState s where #EmpState.PRCo=s.PRCo and #EmpState.TaxYear=s.TaxYear and #EmpState.Employee=s.Employee
     					 and #EmpState.State1=s.State and #EmpState.RecordSort=3
               and isnull(s.LocalCode,' ')=(select min(isnull(a.LocalCode,' ')) From #PRW2LocalState a
               					where a.PRCo=s.PRCo and a.TaxYear=s.TaxYear and a.Employee=s.Employee and a.State=s.State
     						and isnull(a.LocalCode,' ')>isnull(#EmpState.Local1,' ')) 
     

----@@@@@@@@@@@@@@@@@ Page 2 START  --STATE W2
     insert into #EmpStatePage2
    select 
     	a.PRCo, a.TaxYear, a.Employee, 4, 'S', a.State1, a.State1TaxID, a.State2
		,a.State2TaxID, a.Local1, a.Local1TaxID, a.Local2, a.Local2TaxID, a.State1Wages, a.State1Tax
		,a.State2Wages, a.State2Tax, a.Local1Wages, a.Local1Tax, a.Local2Wages, a.Local2Tax
		,a.StateMisc1Amt, a.StateMisc2Amt, a.StateMisc3Amt, a.StateMisc4Amt
		,a.StateMisc5Amt, a.StateMisc6Amt, a.StateMisc7Amt, a.StateMisc8Amt
		,a.W2sGeneratedCount
from      #EmpState  a 
LEFT OUTER JOIN brvPRW2Box14StateEntries b
	ON a.PRCo = b.PRCo AND a.TaxYear = b.TaxYear AND a.State1 = b.State AND a.Employee = b.Employee AND a.RecordType='S'
LEFT OUTER JOIN #W2Box12Entries c
	ON a.PRCo = c.PRCo AND a.TaxYear = c.TaxYear AND a.Employee = c.Employee AND a.RecordType='S'
WHERE b.StateEntries > 4 OR c.Box12Entries > 4 --Maximun number of box 12 & 14 entries per page is four.


--@@@@@@@@@@@@@@@@@ Page 2 END  --STATE W2


     /**********
      Insert records for each local code.  RecordSort=5.  Insert state info also; needed to print states on local copies
     **********/
     
     insert into #EmpState 
     (PRCo, TaxYear, Employee, RecordSort, RecordType, State1, State1TaxID, Local1, Local1TaxID, State1Wages, State1Tax, Local1Wages, Local1Tax
	, StateMisc1Amt, StateMisc2Amt, StateMisc3Amt, StateMisc4Amt, StateMisc5Amt, StateMisc6Amt, StateMisc7Amt, StateMisc8Amt
	,W2sGeneratedCount)
     select a.PRCo, TaxYear, a.Employee, 5, 'L', a.State, StateTaxID, a.LocalCode, LocalTaxID, StateWages, StateTax, LocalWages, LocalTax
	, Misc1Amt, Misc2Amt,Misc3Amt, Misc4Amt, Misc5Amt, Misc6Amt,Misc7Amt, Misc8Amt
	,NULL
     From #PRW2LocalState a
     Join PREH with(nolock) on PREH.PRCo=a.PRCo and PREH.Employee=a.Employee
     Where a.PRCo=@PRCo and TaxYear=@TaxYear and a.Employee >= @BegEmp and a.Employee <= @EndEmp 
           and PREH.SortName >= @BegEmpName and PREH.SortName <= @EndEmpName
     

----@@@@@@@@@@@@@@@@@ Page 2 START  --Local W2
     insert into #EmpStatePage2
    select 
     	a.PRCo, a.TaxYear, a.Employee, 6, 'L', a.State1, a.State1TaxID, a.State2
		,a.State2TaxID, a.Local1, a.Local1TaxID, a.Local2, a.Local2TaxID, a.State1Wages, a.State1Tax
		,a.State2Wages, a.State2Tax, a.Local1Wages, a.Local1Tax, a.Local2Wages, a.Local2Tax
		,a.StateMisc1Amt, a.StateMisc2Amt, a.StateMisc3Amt, a.StateMisc4Amt
		,a.StateMisc5Amt, a.StateMisc6Amt, a.StateMisc7Amt, a.StateMisc8Amt
		,a.W2sGeneratedCount  
from      #EmpState  a 
LEFT OUTER JOIN brvPRW2Box14StateEntries b
	ON a.PRCo = b.PRCo AND a.TaxYear = b.TaxYear AND a.State1 = b.State AND a.Employee = b.Employee AND a.RecordType='L'
LEFT OUTER JOIN #W2Box12Entries c
	ON a.PRCo = c.PRCo AND a.TaxYear = c.TaxYear AND a.Employee = c.Employee AND a.RecordType='L'
WHERE b.StateEntries > 4 OR c.Box12Entries > 4 --Maximun number of box 12 & 14 entries per page is four.


--@@@@@@@@@@@@@@@@@ Page 2 END  --Local W2


--Insert all page 2s(Both federal, state and local) data into final table.
--NOTE: A 2 page employee W2 is based off the federal W2 infomation so it does not need a specific entry.
INSERT INTO #EmpState
	SELECT 
     	a.PRCo, a.TaxYear, a.Employee, a.RecordSort, a.RecordType, a.State1, a.State1TaxID, a.State2
		,a.State2TaxID, a.Local1, a.Local1TaxID, a.Local2, a.Local2TaxID, a.State1Wages, a.State1Tax
		,a.State2Wages, a.State2Tax, a.Local1Wages, a.Local1Tax, a.Local2Wages, a.Local2Tax
		,a.StateMisc1Amt, a.StateMisc2Amt, a.StateMisc3Amt, a.StateMisc4Amt
		,a.StateMisc5Amt, a.StateMisc6Amt, a.StateMisc7Amt, a.StateMisc8Amt
		,a.W2sGeneratedCount 
	FROM #EmpStatePage2 a


/*Calculate the number of W2s generated for each record in the #EmpState table  */
UPDATE dbo.#EmpState  SET  W2sGeneratedCount= 2 Where RecordSort = 1;
UPDATE dbo.#EmpState  SET  W2sGeneratedCount= 2 Where RecordSort = 2;
UPDATE dbo.#EmpState  SET  W2sGeneratedCount= 1 Where RecordSort = 3;
UPDATE dbo.#EmpState  SET  W2sGeneratedCount= 1 Where RecordSort = 4;

UPDATE dbo.#EmpState  SET  W2sGeneratedCount= 0 Where RecordSort = 5 AND (Local1 IS NULL);
UPDATE dbo.#EmpState  SET  W2sGeneratedCount= 1 Where RecordSort = 5 AND (Local1 IS NOT NULL);

UPDATE dbo.#EmpState  SET  W2sGeneratedCount= 0 Where RecordSort = 6 AND (Local1 IS NULL);
UPDATE dbo.#EmpState  SET  W2sGeneratedCount= 1 Where RecordSort = 6 AND (Local1 IS NOT NULL);


-- Number of W2 Calculations
INSERT INTO #W2EmployeeCounts
SELECT  PRCo,TaxYear, Employee,SUM (W2sGeneratedCount) AS NumberOfW2sPerEmployee 
,NumberOfFedW2sPerEmployee=ISNULL( SUM (CASE WHEN RecordSort IN (1,2) THEN W2sGeneratedCount END)/2,0)
,NumberOfEmpW2sPerEmployee=ISNULL( SUM (CASE WHEN RecordSort IN (1,2) THEN W2sGeneratedCount END)/2,0)
,NumberOfStateW2sPerEmployee = ISNULL( SUM (case when RecordSort IN (3,4) THEN W2sGeneratedCount END),0)
,NumberOfLocalW2sPerEmployee = ISNULL( SUM (CASE WHEN RecordSort IN (5,6) THEN W2sGeneratedCount END),0)
 FROM #EmpState
GROUP BY  PRCo,TaxYear, Employee


     Set NoCount Off
         /****************************/
         /*  select the results */
         /***************************/
         select
         a.PRCo, a.TaxYear, a.Employee, RecordSort=isnull(s.RecordSort,1), s.RecordType,
         	PRWE.SSN, PRWE.FirstName, PRWE.MidName, PRWE.LastName, PRWE.Suffix,
          PRWE.LocAddress, PRWE.DelAddress, PRWE.City, PRWE.State, PRWE.Zip,
          PRWE.ZipExt, PRWE.TaxState, /*PRWE.STTaxID,*/ PRWE.Statutory, PRWE.PensionPlan, PRWE.ThirdPartySickPay,
          PRWE.LegalRep, PRWE.CivilStatus, PRWE.SpouseSSN,
          a.FederalWages,
          a.FederalTaxWH,
          a.SocSecWages,
          a.SocSecTaxWH,
          a.MedicareWages,
     
          a.MedicareTaxWH,
          a.SocSecTips,
          a.AdvanceEIC,
          a.DepCareBenefits,
          a.NonQualified,
          a.FringeBenefits,
          a.AllocatedTips,
          s.State1,
          s.State1TaxID,
          s.State2,
          s.State2TaxID,
          s.Local1,
   
          s.Local1TaxID,
          s.Local2,
          s.Local2TaxID,
          s.State1Wages,
          s.State2Wages,
          s.Local1Wages,
          s.Local2Wages,
          s.State1Tax,
          s.State2Tax,
          s.Local1Tax,
          s.Local2Tax,
 
          a.Box12aCode,
          a.Box12bCode,
          a.Box12cCode,
          a.Box12dCode,
          a.Box12eCode,  --Second Page of W2 Box 12
          a.Box12fCode,  --Second Page of W2 Box 12
          a.Box12gCode,  --Second Page of W2 Box 12
          a.Box12hCode,  --Second Page of W2 Box 12

          a.Box12aAmount,
          a.Box12bAmount,
          a.Box12cAmount,
          a.Box12dAmount,
          a.Box12eAmount,  --Second Page of W2 Box 12
          a.Box12fAmount,  --Second Page of W2 Box 12
          a.Box12gAmount,  --Second Page of W2 Box 12
          a.Box12hAmount,  --Second Page of W2 Box 12

  		  a.Box12aItemID,
          a.Box12bItemID,
          a.Box12cItemID,
          a.Box12dItemID,
  		  a.Box12eItemID,  --Second Page of W2 Box 12
          a.Box12fItemID,  --Second Page of W2 Box 12
          a.Box12gItemID,  --Second Page of W2 Box 12
          a.Box12hItemID,  --Second Page of W2 Box 12
 
          FedMisc1Amt=f1.Amount1,
          FedMisc2Amt=f1.Amount2,
  		  FedMisc3Amt=f1.Amount3,
  		  FedMisc4Amt=f1.Amount4,
          FedMisc5Amt=f1.Amount5,  --Second Page of W2 Box 12
          FedMisc6Amt=f1.Amount6,  --Second Page of W2 Box 12
  		  FedMisc7Amt=f1.Amount7,  --Second Page of W2 Box 12
  		  FedMisc8Amt=f1.Amount8,  --Second Page of W2 Box 12

          PRCo=@PRCo,
          TaxYear=@TaxYear,
          RptType=@RptType,
          EREIN=PRWH.EIN,
          ERName=PRWH.CoName,
          ERLocAddress=PRWH.LocAddress,
          ERDelAddress=PRWH.DelAddress,
          ERCity=PRWH.City,
          ERState=PRWH.State,
          ERZip=PRWH.Zip,
          ERBox14Desc1=f1.Desc1,
          ERBox14Desc2=f1.Desc2,
          ERBox14Desc3=f1.Desc3,
  		  ERBox14Desc4=f1.Desc4,
          ERBox14Desc5=f1.Desc5,  --Page 2
          ERBox14Desc6=f1.Desc6,  --Page 2
          ERBox14Desc7=f1.Desc7,  --Page 2
  		  ERBox14Desc8=f1.Desc8,  --Page 2

          State1Box14Desc1=s1.Desc1,
          State1Box14Desc2=s1.Desc2,
  		  State1Box14Desc3=s1.Desc3,
  		  State1Box14Desc4=s1.Desc4,
          State1Box14Desc5=s1.Desc5,  --Page 2
          State1Box14Desc6=s1.Desc6,  --Page 2
  		  State1Box14Desc7=s1.Desc7,  --Page 2
  		  State1Box14Desc8=s1.Desc8,  --Page 2


          State2Box14Desc1=s2.Desc1,
          State2Box14Desc2=s2.Desc2,
  		  State2Box14Desc3=s2.Desc3,
  		  State2Box14Desc4=s2.Desc4,
          State2Box14Desc5=s2.Desc5,  --Page 2
          State2Box14Desc6=s2.Desc6,  --Page 2
  		  State2Box14Desc7=s2.Desc7,  --Page 2
  		  State2Box14Desc8=s2.Desc8,  --Page 2


          s.StateMisc1Amt,
          s.StateMisc2Amt,
  		  s.StateMisc3Amt,
  		  s.StateMisc4Amt,
          s.StateMisc5Amt,  --Page 2
          s.StateMisc6Amt,  --Page 2
  		  s.StateMisc7Amt,  --Page 2
  		  s.StateMisc8Amt,  --Page 2

          HomeState=PRWE.TaxState,
          StateLocalSort=s.State1+isnull(s.Local1,' '),
          Local1Desc=isnull(PRLI1.Description,s.Local1),

          Local2Desc=isnull(PRLI2.Description,s.Local2),
		  Box12Entries = isnull(b12.Box12Entries,0),
		  Box14FederalEntries = isnull(f1.FederalEntries,0),
		  State1Box14StateEntries = isnull(s1.StateEntries,0),
		  State2Box14StateEntries = isnull(s2.StateEntries,0)
   		,W2sGeneratedCount
		,NumberOfW2sPerEmployee 
		,NumberOfFedW2sPerEmployee
		,NumberOfEmpW2sPerEmployee
		,NumberOfStateW2sPerEmployee
		,NumberOfLocalW2sPerEmployee
           from #W2Data a
           Left Outer Join #EmpState s on s.PRCo=a.PRCo and s.TaxYear=a.TaxYear and s.Employee=a.Employee
           Left Outer Join brvPRW2Box14StateEntries s1 with(nolock) on s1.PRCo=s.PRCo and s1.TaxYear=s.TaxYear and s1.State=s.State1 and s1.Employee=s.Employee
           Left Outer Join brvPRW2Box14StateEntries s2 with(nolock) on s2.PRCo=s.PRCo and s2.TaxYear=s.TaxYear and s2.State=s.State2 and s2.Employee=s.Employee
           Join PRWH with(nolock) on PRWH.PRCo=a.PRCo and PRWH.TaxYear=a.TaxYear
           Join PRWE with(nolock) on PRWE.PRCo=a.PRCo and PRWE.TaxYear=a.TaxYear and PRWE.Employee=a.Employee
           LEFT OUTER JOIN brvPRW2Box14FederalEntries f1 with(nolock) on f1.PRCo=a.PRCo and f1.TaxYear=a.TaxYear and f1.Employee=a.Employee
           Join PREH with(nolock) on PREH.PRCo=a.PRCo and PREH.Employee=a.Employee
           Left Outer Join PRLI PRLI1 with(nolock) on PRLI1.PRCo=s.PRCo and PRLI1.LocalCode=s.Local1
           Left Outer Join PRLI PRLI2 with(nolock) on PRLI2.PRCo=s.PRCo and PRLI2.LocalCode=s.Local2
		   LEFT OUTER JOIN #W2Box12Entries b12 ON s.PRCo=b12.PRCo AND s.TaxYear=b12.TaxYear AND s.Employee=b12.Employee
		   LEFT OUTER JOIN #W2EmployeeCounts t	ON s.PRCo=t.PRCo AND s.TaxYear=t.TaxYear AND s.Employee=t.Employee
      order by a.PRCo, a.TaxYear, a.Employee


GO
GRANT EXECUTE ON  [dbo].[brptPRW2] TO [public]
GO
