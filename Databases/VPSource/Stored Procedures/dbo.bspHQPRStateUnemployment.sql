SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
CREATE    proc [dbo].[bspHQPRStateUnemployment]
/**********************************************
* Created By:  GF 11/05/99
* Modified By: GF 01/18/2000
*              GF 09/12/2000 additional columns for NY
*              GF 01/11/2001 additional columns for MMREF-1 mag format
*              GF 08/20/2001 - added plant, branch, Loc1Amt, Loc2Amt, Loc3Amt to result set
*				GF 04/03/2002 - added suffix to output parameters.
*				GF 04/30/2002 - Rounding problem if more than 700 employees. Need to convert numbers to decimal(16,2)
*				GF 04/30/2002 - Added PREH.Sex to output columns for maine(ME)
*				GF 05/01/2002 - Added PREH.HrlyRate and PREH.SalaryAmt to output columns for Vermont(VT)
*				GF 02/21/2003 - for LA need to round SUIWages to nearest dollar
*				GF 07/23/2003 - issue #21934 - added employee zip extension to resultset
*				gf 10/23/2003 - issue #22807 - only employees with SUI wages greater than zero.
*				GF 04/12/2004 - issue #24321 - need to get zip ext part for employee from bPREH
*				GF 01/21/2005 - issue #26901 - for NY last quarter (12) show employees w/SUI Wages = zero
*				GF 03/15/2005 - issue #27361 - for 'MN' use gross wages, not SUI wages
*				GF 07/14/2005 - issue #29280 - for 'MN' put back using SUI wages.
*				GF 05/09/2006 - issue #120994 - additional PRUE columns to return for 'NM'. PRUE.DLCode1Amt, PRUE.DLCode2Amt
*				GF 10/31/2006 - issue #122925 - one more column for 'NM', PRUH.Penalty2
*				GF 01/12/2006 - issue #123547 - missing MidName and LastName column headings for 'MN'.
*				GF 05/07/2007 - issue #124487 - for 'ME' allow for SUIWages = 0.
*				GF 08/07/2007 - issue #125056 added PREH.OccupCat to select. Needed for AK.
*				GF 08/17/2007 - issue #124197 - special select for 'Florida' to return out of state wages. NOT USED YET
*				MH 09/11/2007 - Added EMail for Florida.
*				MH 11/06/2007 - issue #126041 - for 'KS' allow for SUIWages = 0.
*				MH 09/09/2008 - issue #128713 - Add NACIS codes for WY
*				mh 01/21/2009 - issue #131924 - Include CA as state that includes employees with zero SUI wages
*				mh 04/15/2010 - issue #139086 - Include StateTaxable Wages
*				mh 05/17/2010 - Issue #139559 - For MA include employees that have State Income Tax but no SUI wages.
*				mh 06/16/2010 - Issue #139331 include Out of State numbers for an employee.  
*				CHS 06/24/2010	-issue # 138315
*				CHS	01/24/2011 - issue2 #142618
*				mh 02/28/2011 - Issue #141934 - Error with YTD Out of State Wages 
*				CHS 04/27/2011	- 143632 - B-04221 added OutOfStateTaxableWages y/n for OH
*				CHS	06/28/2012	- D-04362 - 145362 added LimitYTDOutofStateEligWages for FL
*				CHS	07/10/2012	-	D-04361 - 145219 added FTE for VT
*				CHS	01/15/2013	-	D-05991 TK-20765 147161 added 'OutOfStateWagesState' for NM.
*
*  If a problem arises regarding GrossWages being 0 see potental problem comment bspPRUnemplWageInit
*
***********************************/
(@prco bCompany, @state bState, @quarter bDate)
as
set nocount on

declare @firstofyear bMonth, @year varchar(4)
 
set @year = convert(varchar(4),year(convert(smalldatetime,@quarter)))
set @firstofyear = '01/01/' + @year

---- for 'ME' and 'KS' and 'MA' include employees with zero SUI wages #124487/126041/139559
if @state = 'ME' or @state = 'KS' or @state = 'CA' or @state = 'MA'
	begin
   	Select a.EIN, a.CoName, a.Address, a.City, a.CoState, a.Zip, a.ZipExt, a.Contact, a.Phone,
   	        a.PhoneExt, a.TransId, a.C3, a.SuffixCode, a.TotalRemit, a.CreateDate, a.Computer,
   	        a.EstabId, a.StateId, a.UnempID, a.TaxType, a.TaxEntity, a.ControlId, a.UnitId,
   	        a.OtherEIN, a.TaxRate, a.PrevUnderPay, a.Interest, a.Penalty, a.OverPay, a.AssesRate1,
   	        a.AssesAmt1, a.AssessRate2, a.AssessAmt2, a.TotalDue, a.AllocAmt, a.County, a.OutCounty,
   	        a.DocControl, a.MultiCounty, a.MultiLocation, a.MultiIndicator, a.ElectFundTrans,
   	        b.PRCo, b.State, b.Quarter, b.Employee, b.SSN, b.FirstName,
 			'MidName'=replace(b.MidName,'.',''), 'LastName'=replace(b.LastName,char(39),''), b.Suffix,
   	        'GrossWages'=convert(decimal(16,2),b.GrossWages), 
   	 	   'SUIWages'=case when @state='LA' then convert(decimal(16,2),ROUND(b.SUIWages,0)) else convert(decimal(16,2),b.SUIWages) end,
   	 	   'ExcessWages'=convert(decimal(16,2),b.ExcessWages), 'EligWages'=convert(decimal(16,2),b.EligWages),
   	 	   'DisWages'=convert(decimal(16,2),b.DisWages), 'TipWages'=convert(decimal(16,2),b.TipWages),
   	 	   --139331 
   	 	    'OutofStateGrossWages' = convert(decimal(16,2),isnull(p1.OutofStateGrossWages,0)), 
   	 	    'OutofStateSUIWages' = convert(decimal(16,2), isnull(p1.OutofStateSUIWages,0)), 
   	 	    'OutofStateExcessWages' = convert(decimal(16,2), isnull(p1.OutofStateExcessWages,0)), 
   	 	    'OutofStateEligWages' = convert(decimal(16,2), isnull(p1.OutofStateEligWages,0)),
   	 	    
   	 	    'YTDOutofStateGrossWages' = convert(decimal(16,2),isnull(p2.YTDOutofStateGrossWages,0)),
   	 	    'YTDOutOfStateSUIWages' = convert(decimal(16,2),isnull(p2.YTDOutofStateGrossWages,0)),
   	 	    'YTDOutOfStateExcessWages'= convert(decimal(16,2),isnull(p2.YTDOutofStateExcessWages,0)),
   	 	    'YTDOutofStateEligWages' = convert(decimal(16,2), isnull(p2.YTDOutofStateEligWages,0)),
			--End 139331
			
			--138315
			'YTDStateGrossWages' = convert(decimal(16,2),isnull(p3.YTDStateGrossWages,0)),
			'YTDStateSUIWages' = convert(decimal(16,2),isnull(p3.YTDStateSUIWages,0)),
			'YTDStateExcessWages'= convert(decimal(16,2),isnull(p3.YTDStateExcessWages,0)),
			'YTDStateEligWages' = convert(decimal(16,2), isnull(p3.YTDStateEligWages,0)),
			--End 138315
		
   	        b.WksWorked, b.HrsWorked, 'StateTaxableWages'=convert(decimal(16,2),b.StateTaxableWages), 'StateTax'=convert(decimal(16,2),b.StateTax), b.Seasonal, b.HealthCode1, b.HealthCode2,
   	        b.ProbCode, b.Officer, b.WagePlan, b.Mth1, b.Mth2, b.Mth3, b.EmplDate, b.SepDate,
   	        a.FilingType, b.SUIWageType, 'AnnualGrossWage'=convert(decimal(16,2),b.AnnualGrossWage),
   	 	   'AnnualStateTax'=convert(decimal(16,2),b.AnnualStateTax), a.LocAddress,
   	       'ReportUnit'=isnull(b.ReportUnit,'0000'), b.Industry, a.Plant, a.Branch, b.Loc1Amt, b.Loc2Amt, b.Loc3Amt,
   	        b.OfficerCode, 'EmplLocAddress'= bPREH.Address2, 'EmplAddress' = bPREH.Address,
   	        'EmplCity' = bPREH.City, 'EmplState' = bPREH.State, 'EmplZip' = bPREH.Zip, 
   	 		'EmplZipExt'= case when substring(bPREH.Zip,6,1) = '-' then substring(bPREH.Zip,7,4) else null end, 	-- -- 'EmplZipExt' = bPREH.Zip,
			bPREH.InsCode, bPREH.Sex, bPREH.HrlyRate, bPREH.SalaryAmt, b.DLCode1Amt, b.DLCode2Amt,
			a.Penalty2, bPREH.OccupCat, a.EMail, b.NAICS, s.TaxID as [StateTaxID]
			
   	from bPRUH a with (nolock)
   	LEFT JOIN bPRUE b with (nolock) ON a.PRCo = b.PRCo and a.State = b.State and a.Quarter = b.Quarter
   	LEFT JOIN bPREH with (nolock) ON bPREH.PRCo=b.PRCo and bPREH.Employee=b.Employee
   	LEFT JOIN bPRSI s with (nolock) ON s.PRCo = a.PRCo and s.State = a.State
   	--139331 include Out of State numbers for an employee.
   	Left Join (
   		select b.PRCo, b.Employee, b.Quarter, sum(b.GrossWages) 'OutofStateGrossWages', 
   		sum(case when @state='LA' then convert(decimal(16,2),ROUND(b.SUIWages,0)) else convert(decimal(16,2),b.SUIWages) end) 'OutofStateSUIWages',
   		sum(b.ExcessWages) 'OutofStateExcessWages', sum(b.EligWages) 'OutofStateEligWages'
   		from bPRUE b 
   		where b.PRCo = @prco and b.Quarter = @quarter and b.State <> @state
   		group by b.PRCo, b.Employee, b.Quarter) as p1
   		on bPREH.PRCo = p1.PRCo and bPREH.Employee = p1.Employee 

   	Left Join (
		----get year to date   	
		select b.PRCo, b.Employee, sum(b.GrossWages) 'YTDOutofStateGrossWages', 
		sum(case when @state='LA' then convert(decimal(16,2),ROUND(b.SUIWages,0)) else convert(decimal(16,2),b.SUIWages) end) 'YTDOutofStateSUIWages',
		sum(b.ExcessWages) 'YTDOutofStateExcessWages', sum(b.EligWages) 'YTDOutofStateEligWages'
		from bPRUE b
		where b.PRCo = @prco and (b.Quarter >= @firstofyear and b.Quarter <= @quarter) and b.State <> @state
		group by b.PRCo, b.Employee) as p2
		on bPREH.PRCo = p2.PRCo and bPREH.Employee = p2.Employee    			   		
   	--end 139331
   	
	--138315   	
      Left Join (
        ----get year to date   
        select b.PRCo, b.Employee, sum(b.GrossWages) 'YTDStateGrossWages', 
        sum(case when @state='LA' then convert(decimal(16,2),ROUND(b.SUIWages,0)) else convert(decimal(16,2),b.SUIWages) end) 'YTDStateSUIWages',
        sum(b.ExcessWages) 'YTDStateExcessWages', sum(b.EligWages) 'YTDStateEligWages'
        from bPRUE b
        where b.PRCo = @prco and (b.Quarter >= @firstofyear and b.Quarter <= @quarter) and b.State = @state
        group by b.PRCo, b.Employee) as p3
        on bPREH.PRCo = p3.PRCo and bPREH.Employee = p3.Employee  
	--End 138315
   	
   	where b.PRCo = @prco and b.State = @state and b.Quarter >= @quarter and b.Quarter <= @quarter
   	ORDER BY b.PRCo, b.State, b.Quarter, b.Employee
   	
   	
   	select TaxID as [StateTaxIDNumber]
   	from bPRSI s with (nolock)
   	where s.PRCo = @prco and s.State = @state;
   	
   	
	goto bspexit
   	end


---- for 'MN' use gross wages, not SUI wages - #29280 'MN' back to using SUI
if @state = 'MN'
   	begin
   	Select a.EIN, a.CoName, a.Address, a.City, a.CoState, a.Zip, a.ZipExt, a.Contact, a.Phone,
   	        a.PhoneExt, a.TransId, a.C3, a.SuffixCode, a.TotalRemit, a.CreateDate, a.Computer,
   	        a.EstabId, a.StateId, a.UnempID, a.TaxType, a.TaxEntity, a.ControlId, a.UnitId,
   	        a.OtherEIN, a.TaxRate, a.PrevUnderPay, a.Interest, a.Penalty, a.OverPay, a.AssesRate1,
   	        a.AssesAmt1, a.AssessRate2, a.AssessAmt2, a.TotalDue, a.AllocAmt, a.County, a.OutCounty,
   	        a.DocControl, a.MultiCounty, a.MultiLocation, a.MultiIndicator, a.ElectFundTrans,
   	        b.PRCo, b.State, b.Quarter, b.Employee, b.SSN, b.FirstName,
 			'MidName'=replace(b.MidName,'.',''), 'LastName'=replace(b.LastName,char(39),''), b.Suffix,
   	        'GrossWages'=convert(decimal(16,2),b.GrossWages), 
   	 	   'SUIWages'=case when @state='LA' then convert(decimal(16,2),ROUND(b.SUIWages,0)) else convert(decimal(16,2),b.SUIWages) end,
   	 	   'ExcessWages'=convert(decimal(16,2),b.ExcessWages), 'EligWages'=convert(decimal(16,2),b.EligWages),
   	 	   'DisWages'=convert(decimal(16,2),b.DisWages), 'TipWages'=convert(decimal(16,2),b.TipWages),
   	 	   --139331 
   	 	    'OutofStateGrossWages' = convert(decimal(16,2),isnull(p1.OutofStateGrossWages,0)), 
   	 	    'OutofStateSUIWages' = convert(decimal(16,2), isnull(p1.OutofStateSUIWages,0)), 
   	 	    'OutofStateExcessWages' = convert(decimal(16,2), isnull(p1.OutofStateExcessWages,0)), 
   	 	    'OutofStateEligWages' = convert(decimal(16,2), isnull(p1.OutofStateEligWages,0)),
   	 	    
   	 	    'YTDOutofStateGrossWages' = convert(decimal(16,2),isnull(p2.YTDOutofStateGrossWages,0)),
   	 	    'YTDOutOfStateSUIWages' = convert(decimal(16,2),isnull(p2.YTDOutofStateGrossWages,0)),
   	 	    'YTDOutOfStateExcessWages'= convert(decimal(16,2),isnull(p2.YTDOutofStateExcessWages,0)),
   	 	    'YTDOutofStateEligWages' = convert(decimal(16,2), isnull(p2.YTDOutofStateEligWages,0)),
			--End 139331
						
			--138315
			'YTDStateGrossWages' = convert(decimal(16,2),isnull(p3.YTDStateGrossWages,0)),
			'YTDStateSUIWages' = convert(decimal(16,2),isnull(p3.YTDStateSUIWages,0)),
			'YTDStateExcessWages'= convert(decimal(16,2),isnull(p3.YTDStateExcessWages,0)),
			'YTDStateEligWages' = convert(decimal(16,2), isnull(p3.YTDStateEligWages,0)),
			--End 138315
			
   	        b.WksWorked, b.HrsWorked, 'StateTaxableWages'=convert(decimal(16,2),b.StateTaxableWages), 'StateTax'=convert(decimal(16,2),b.StateTax), b.Seasonal, b.HealthCode1, b.HealthCode2,
   	        b.ProbCode, b.Officer, b.WagePlan, b.Mth1, b.Mth2, b.Mth3, b.EmplDate, b.SepDate,
   	        a.FilingType, b.SUIWageType, 'AnnualGrossWage'=convert(decimal(16,2),b.AnnualGrossWage),
   	 	   'AnnualStateTax'=convert(decimal(16,2),b.AnnualStateTax), a.LocAddress,
   	       'ReportUnit'=isnull(b.ReportUnit,'0000'), b.Industry, a.Plant, a.Branch, b.Loc1Amt, b.Loc2Amt, b.Loc3Amt,
   	        b.OfficerCode, 'EmplLocAddress'= bPREH.Address2, 'EmplAddress' = bPREH.Address,
   	        'EmplCity' = bPREH.City, 'EmplState' = bPREH.State, 'EmplZip' = bPREH.Zip, 
   	 		'EmplZipExt'= case when substring(bPREH.Zip,6,1) = '-' then substring(bPREH.Zip,7,4) else null end, 	-- -- 'EmplZipExt' = bPREH.Zip,
			bPREH.InsCode, bPREH.Sex, bPREH.HrlyRate, bPREH.SalaryAmt, b.DLCode1Amt, b.DLCode2Amt,
			a.Penalty2, bPREH.OccupCat, a.EMail, b.NAICS
   	from bPRUH a with (nolock)
   	LEFT JOIN bPRUE b with (nolock) ON a.PRCo = b.PRCo and a.State = b.State and a.Quarter = b.Quarter
   	LEFT JOIN bPREH with (nolock) ON bPREH.PRCo=b.PRCo and bPREH.Employee=b.Employee
   	--139331 include Out of State numbers for an employee.
   	Left Join (
   		select b.PRCo, b.Employee, b.Quarter, sum(b.GrossWages) 'OutofStateGrossWages', 
   		sum(case when @state='LA' then convert(decimal(16,2),ROUND(b.SUIWages,0)) else convert(decimal(16,2),b.SUIWages) end) 'OutofStateSUIWages',
   		sum(b.ExcessWages) 'OutofStateExcessWages', sum(b.EligWages) 'OutofStateEligWages'
   		from bPRUE b
   		where b.PRCo = @prco and b.Quarter = @quarter and b.State <> @state
   		group by b.PRCo, b.Employee, b.Quarter) as p1
   		on bPREH.PRCo = p1.PRCo and bPREH.Employee = p1.Employee 

   	Left Join (
		----get year to date   	
		select b.PRCo, b.Employee, sum(b.GrossWages) 'YTDOutofStateGrossWages', 
		sum(case when @state='LA' then convert(decimal(16,2),ROUND(b.SUIWages,0)) else convert(decimal(16,2),b.SUIWages) end) 'YTDOutofStateSUIWages',
		sum(b.ExcessWages) 'YTDOutofStateExcessWages', sum(b.EligWages) 'YTDOutofStateEligWages'
		from bPRUE b
		where b.PRCo = @prco and (b.Quarter >= @firstofyear and b.Quarter <= @quarter) and b.State <> @state
		group by b.PRCo, b.Employee) as p2
		on bPREH.PRCo = p2.PRCo and bPREH.Employee = p2.Employee    		
   	--end 139331
   	
	--138315   	
      Left Join (
	----get year to date   
        select b.PRCo, b.Employee, sum(b.GrossWages) 'YTDStateGrossWages', 
        sum(case when @state='LA' then convert(decimal(16,2),ROUND(b.SUIWages,0)) else convert(decimal(16,2),b.SUIWages) end) 'YTDStateSUIWages',
        sum(b.ExcessWages) 'YTDStateExcessWages', sum(b.EligWages) 'YTDStateEligWages'
        from bPRUE b
        where b.PRCo = @prco and (b.Quarter >= @firstofyear and b.Quarter <= @quarter) and b.State = @state
        group by b.PRCo, b.Employee) as p3
        on bPREH.PRCo = p3.PRCo and bPREH.Employee = p3.Employee  
	--End 138315
	
   	where b.PRCo = @prco and b.State = @state and b.Quarter >= @quarter and b.Quarter <= @quarter
	and b.SUIWages > 0
   	ORDER BY b.PRCo, b.State, b.Quarter, b.Employee
   	end
else
   	begin
   	Select a.EIN, a.CoName, a.Address, a.City, a.CoState, a.Zip, a.ZipExt, a.Contact, a.Phone,
   	        a.PhoneExt, a.TransId, a.C3, a.SuffixCode, a.TotalRemit, a.CreateDate, a.Computer,
   	        a.EstabId, a.StateId, a.UnempID, a.TaxType, a.TaxEntity, a.ControlId, a.UnitId,
   	        a.OtherEIN, a.TaxRate, a.PrevUnderPay, a.Interest, a.Penalty, a.OverPay, a.AssesRate1,
   	        a.AssesAmt1, a.AssessRate2, a.AssessAmt2, a.TotalDue, a.AllocAmt, a.County, a.OutCounty,
   	        a.DocControl, a.MultiCounty, a.MultiLocation, a.MultiIndicator, a.ElectFundTrans,
   	        b.PRCo, b.State, b.Quarter, b.Employee, b.SSN, b.FirstName, 'MidName'=replace(b.MidName,'.',''), 'LastName'=replace(b.LastName,char(39),''), b.Suffix,
   	        'GrossWages'=convert(decimal(16,2),b.GrossWages), 
   	 	   'SUIWages'=case when @state='LA' then convert(decimal(16,2),ROUND(b.SUIWages,0)) else convert(decimal(16,2),b.SUIWages) end,
   	 	   'ExcessWages'=convert(decimal(16,2),b.ExcessWages), 'EligWages'=convert(decimal(16,2),b.EligWages),
   	 	   'DisWages'=convert(decimal(16,2),b.DisWages), 'TipWages'=convert(decimal(16,2),b.TipWages), 
   	 	   
   	 	   'OutOfStateWagesState' = StateOutOfStateWages,
   	 	   --139331 
   	 	    'OutofStateGrossWages' = convert(decimal(16,2),isnull(p1.OutofStateGrossWages,0)), 
   	 	    'OutofStateSUIWages' = convert(decimal(16,2), isnull(p1.OutofStateSUIWages,0)), 
   	 	    'OutofStateExcessWages' = convert(decimal(16,2), isnull(p1.OutofStateExcessWages,0)), 
   	 	    'OutofStateEligWages' = convert(decimal(16,2), isnull(p1.OutofStateEligWages,0)),
   	 	    
   	 	    'YTDOutofStateGrossWages' = convert(decimal(16,2),isnull(p2.YTDOutofStateGrossWages,0)),
   	 	    'YTDOutOfStateSUIWages' = convert(decimal(16,2),isnull(p2.YTDOutofStateGrossWages,0)),
   	 	    'YTDOutOfStateExcessWages'= convert(decimal(16,2),isnull(p2.YTDOutofStateExcessWages,0)),
   	 	    'YTDOutofStateEligWages' = convert(decimal(16,2), isnull(p2.YTDOutofStateEligWages,0)),
			--End 139331	
						
			--138315
			'YTDStateGrossWages' = convert(decimal(16,2),isnull(p3.YTDStateGrossWages,0)),
			'YTDStateSUIWages' = convert(decimal(16,2),isnull(p3.YTDStateSUIWages,0)),
			'YTDStateExcessWages'= convert(decimal(16,2),isnull(p3.YTDStateExcessWages,0)),
			'YTDStateEligWages' = convert(decimal(16,2), isnull(p3.YTDStateEligWages,0)),
			--End 138315
					
   	        b.WksWorked, b.HrsWorked, 'StateTaxableWages'=convert(decimal(16,2),b.StateTaxableWages), 'StateTax'=convert(decimal(16,2),b.StateTax), b.Seasonal, b.HealthCode1, b.HealthCode2,
   	        b.ProbCode, b.Officer, b.WagePlan, b.Mth1, b.Mth2, b.Mth3, b.EmplDate, b.SepDate,
   	        a.FilingType, b.SUIWageType, 'AnnualGrossWage'=convert(decimal(16,2),b.AnnualGrossWage),
   	 	   'AnnualStateTax'=convert(decimal(16,2),b.AnnualStateTax), a.LocAddress,
   	        b.ReportUnit, b.Industry, a.Plant, a.Branch, b.Loc1Amt, b.Loc2Amt, b.Loc3Amt,
   	        b.OfficerCode, 'EmplLocAddress'= bPREH.Address2, 'EmplAddress' = bPREH.Address,
   	        'EmplCity' = bPREH.City, 'EmplState' = bPREH.State, 'EmplZip' = bPREH.Zip, 
   	 		'EmplZipExt'= case when substring(bPREH.Zip,6,1) = '-' then substring(bPREH.Zip,7,4) else null end, 	-- -- 'EmplZipExt' = bPREH.Zip,
			bPREH.InsCode, bPREH.Sex, bPREH.HrlyRate, bPREH.SalaryAmt, b.DLCode1Amt, b.DLCode2Amt,
			a.Penalty2, bPREH.OccupCat, a.EMail, b.NAICS,
			--143632 - B-04221 added OutOfStateTaxableWages y/n for OH
			'OutOfStateTaxableWages' = case when (b.SUIWages > 0 and p1.OutofStateSUIWages > 0) then 'Y' else 'N' end,
			'LimitYTDOutofStateEligWages' = 
								CASE -- D-04362 for FL
									WHEN convert(decimal(16,2), isnull(p2.YTDOutofStateEligWages,0)) > isnull(l.LimitAmt, 0) 
									THEN isnull(l.LimitAmt, 0)
									ELSE convert(decimal(16,2), isnull(p2.YTDOutofStateEligWages,0))
								END,
			a.FTECount, a.FTEAmtDue
			
   	from bPRUH a with (nolock)
   	LEFT JOIN bPRUE b with (nolock) ON a.PRCo = b.PRCo and a.State = b.State and a.Quarter = b.Quarter
   	LEFT JOIN bPREH with (nolock) ON bPREH.PRCo=b.PRCo and bPREH.Employee=b.Employee
   	LEFT JOIN bPRSI i with (nolock) ON i.PRCo = a.PRCo and i.State = a.State			 -- D-04362 for FL
   	LEFT JOIN bPRDL l with (nolock) ON l.PRCo = a.PRCo and i.SUTALiab = l.DLCode		 -- D-04362 for FL
   	--139331 include Out of State numbers for an employee.
   	Left Join (
   		select b.PRCo, b.Employee, b.Quarter, sum(b.GrossWages) 'OutofStateGrossWages', 
   		sum(case when @state='LA' then convert(decimal(16,2),ROUND(b.SUIWages,0)) else convert(decimal(16,2),b.SUIWages) end) 'OutofStateSUIWages',
   		sum(b.ExcessWages) 'OutofStateExcessWages', sum(b.EligWages) 'OutofStateEligWages',
   		'StateOutOfStateWages' = min(b.State)
   		from bPRUE b
   		where b.PRCo = @prco and b.Quarter = @quarter and b.State <> @state
   		group by b.PRCo, b.Employee, b.Quarter) as p1
   		on bPREH.PRCo = p1.PRCo and bPREH.Employee = p1.Employee 

   	Left Join (
		----get year to date   	
		select b.PRCo, b.Employee, sum(b.GrossWages) 'YTDOutofStateGrossWages', 
		sum(case when @state='LA' then convert(decimal(16,2),ROUND(b.SUIWages,0)) else convert(decimal(16,2),b.SUIWages) end) 'YTDOutofStateSUIWages',
		sum(b.ExcessWages) 'YTDOutofStateExcessWages', sum(b.EligWages) 'YTDOutofStateEligWages'
		from bPRUE b
		where b.PRCo = @prco and (b.Quarter >= @firstofyear and b.Quarter <= @quarter) and b.State <> @state
		group by b.PRCo, b.Employee) as p2
		on bPREH.PRCo = p2.PRCo and bPREH.Employee = p2.Employee    		
   	--end 139331

	--138315   	
      Left Join (
        ----get year to date   
        select b.PRCo, b.Employee, sum(b.GrossWages) 'YTDStateGrossWages', 
        sum(case when @state='LA' then convert(decimal(16,2),ROUND(b.SUIWages,0)) else convert(decimal(16,2),b.SUIWages) end) 'YTDStateSUIWages',
        sum(b.ExcessWages) 'YTDStateExcessWages', sum(b.EligWages) 'YTDStateEligWages'
        from bPRUE b
        where b.PRCo = @prco and (b.Quarter >= @firstofyear and b.Quarter <= @quarter) and b.State = @state
        group by b.PRCo, b.Employee) as p3
        on bPREH.PRCo = p3.PRCo and bPREH.Employee = p3.Employee  
	--End 138315
	   	
   	where b.PRCo = @prco and b.State = @state and b.Quarter >= @quarter and b.Quarter <= @quarter
   	-- -- -- issue #26901
   	and ((b.State <> 'NY' and b.SUIWages > 0)
   	or (b.State = 'NY' and month(@quarter) <> 12 and b.SUIWages > 0)
   	or (b.State = 'NY' and month(@quarter) = 12 and b.SUIWages >= 0))
   	ORDER BY b.PRCo, b.State, b.Quarter, b.Employee
   	end



bspexit:

GO
GRANT EXECUTE ON  [dbo].[bspHQPRStateUnemployment] TO [public]
GO
