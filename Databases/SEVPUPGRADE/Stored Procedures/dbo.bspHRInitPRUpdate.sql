SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                 procedure [dbo].[bspHRInitPRUpdate]
/****************************************************************
* CREATED BY: kb 8/31/99
* MODIFIED By : kb 11/2/99 Issue #5359
*               ae 5/18/00 Issue #6283  -was updating HRWI with PR_Empl instead of HRRef!
*               mh 6/14/00 Issue #7107
*               mh 11/14/00 Issue #9868
*			   mh 5/16/01 Issue #13440 - Not inserting EarnCode into HRRM.  Added to insert stmt.
*               CMW 03/12/02 Issue # 16382 - Changed default on PREH.CertYN from 'N' to 'Y'.
*				SR 07/29/02 issue 18003-added Suffix to update between PREH and HRRM vs vs
*				mh 4/16/03 issue 18914
*				mh 5/6/03 issue 21212
*				mh 7/24/03 issue 18913
*				mh 08/15/03 - #17851.  Get GLCo from PRCO and use it in insert into PREH	
*				mh 9/29/04 - #25519. If security is on, bHRRef or PRGroup, user should
*				still be able to insert.  They will not be able to view or modify.  Need to use
*				the tables instead of the views.  We are getting runtime errors when using the
*				views and security is on.  If the HRRef has already been used by another Resource
*				it will not be visible in the view due to security and the program code will attempt to
*				insert a duplicate record as opposed to developing a new HRRef number.  Also got
*				rid of the pseudo-cursors in favor of local fast_forward cursors.
*				mh 1/25/05 Issue #26896
*				mh 10/02/07 Issue #125641
*				mh 8/7/2008 Issue  #129198.  Added HDAmt, F1Amt, LCFStock, LCPStock to HRRM/PREH inserts.  Added
*											MiscAmt2 to HRWI insert.
*				EN 10/14/2009 #133605 only copy dedns to HRWI, not liabs such as AUS superannuation liab
*				TJL 03/08/10 - #135490, Add new fields for Work Office Tax State and Work Office Local Code 
*				CHS TK-18912 D-05982 allow duplication of 333-333-333, 444-444-444, 111-111-111, and 000-000-000 for Ausatralia
*				CHS	01/02/2013	- D-05992 TK-20456 145358 fix the omission of Cell Phone
*
* USAGE:
* Called by the HR Init PR form update HR to PR or vice versa based on flag
* set in HRHP record
*
* INPUT:
*   @hrco      	PR Company
*
* OUTPUT:
*   @errmsg		Error message
*
* RETURN:
*   0			Sucess
*   1			Failure
********************************************************/
           (@hrco bCompany, @errmsg varchar(200) output)
   	as
    
   	set nocount on
    
   	declare @rcode int, @msg bDesc, @status char(1), @hrref bHRRef, @ssn char(11),
   	@employee bEmployee, @prco bCompany, @sortname bSortName,@w4complete bYN,
   	@glco bCompany, @openhrcurs tinyint, @openprcurs tinyint, @defaultcountry char(2)
    
   	select @rcode = 0, @openhrcurs = 0, @openprcurs = 0
   	
   	if @hrco is null
   	begin
   		select @errmsg = 'Missing HR Company', @rcode = 1
   		goto bspexit
   	end
   
   	if not exists(select 1 from dbo.bHRCO where HRCo = @hrco)
   	begin
   		select @errmsg = 'Invalid HR Company', @rcode = 1
   		goto bspexit
   	end
   
    SELECT @defaultcountry = DefaultCountry FROM dbo.HQCO WHERE HQCo = @hrco
      	
   --HR to PR
   	declare curs_HRRef cursor local fast_forward for
   	select p.HRRef, p.Employee, p.PRCo, h.SortName, h.SSN, h.W4CompleteYN, c.GLCo
   	from dbo.bHRHP p join dbo.bHRRM h on p.HRCo = h.HRCo and p.HRRef = h.HRRef
   	join dbo.bPRCO c on p.PRCo = c.PRCo
   	where p.HRCo = @hrco and p.Status = '0' order by p.HRRef
    
   	open curs_HRRef
   
   	select @openhrcurs = 1
   	
   	fetch next from curs_HRRef into @hrref, @employee, @prco, @sortname, @ssn, @w4complete, @glco
   
   	while @@fetch_status = 0
   	begin
   		--Set PREmp to HRRef if PREmp was not specified in HRRM
   		if @employee is null
   			select @employee = @hrref
   
   		--Check to see if PREmp has already been used.  If so set Employee to the max Employee + 1
   		if exists (select 1 from dbo.bPREH with (nolock) where PRCo = @prco and Employee = @hrref) 
   			select @employee = isnull(max(Employee),0) + 1 from dbo.bPREH with (nolock) where PRCo = @prco
    
   		/* do a final validation before inserting*/
   		exec @rcode = bspHRValdateBeforeUpdate @hrco , 'H' , @prco , @employee,
   		@hrref , @errmsg  output
   		
   		if @rcode <> 0
   		begin
   			select @errmsg = @errmsg + ' must be corrected before update can occur.',@rcode = 1
   			goto bspexit
   		end
    
		--Issue #135490 - add WOTaxState, WOLocalCode, UseUnempState, UseInsState
   		IF (@defaultcountry = 'AU') AND (@ssn IN ('333-333-333', '444-444-444', '111-111-111', '000-000-000')) OR
			(not exists(select 1 from dbo.bPREH with (nolock) where PRCo = @prco and SSN = @ssn) and not exists(select 1 from dbo.bPREH where PRCo = @prco and SortName = @sortname))
   		begin
   			begin transaction
   			INSERT dbo.bPREH (
				PRCo, Employee,LastName,FirstName,MidName,
				SortName,Address,City,State,Zip,
				Address2,Phone,CellPhone,SSN,Race,Sex,
				BirthDate,HireDate,TermDate,PRGroup,PRDept,
				Craft,Class,InsCode,TaxState,UnempState,
				InsState,LocalCode,GLCo,UseState,UseLocal,
				UseIns,JCCo,Job,Crew,LastUpdated,
				EarnCode,HrlyRate,SalaryAmt,OTOpt,OTSched,
				JCFixedRate,EMFixedRate,YTDSUI,OccupCat,CatStatus,
				DirDeposit,RoutingId,BankAcct,AcctType,ActiveYN,
				PensionYN,PostToAll,CertYN,ChkSort,AuditYN, 
				Suffix,Email,Shift, Country, HDAmt, F1Amt, LCFStock, LCPStock,
				WOTaxState, WOLocalCode, UseUnempState, UseInsState)
   			SELECT 
				@prco, @employee, LastName, FirstName, MiddleName,
				SortName,Address,City,State,Zip,
				Address2,Phone,CellPhone,SSN,Race,Sex,
				BirthDate,HireDate,TermDate,PRGroup,PRDept,
				StdCraft,StdClass,StdInsCode,StdTaxState,StdUnempState,
				StdInsState,StdLocal, @glco, 'N', 'N',
				'N', null, null, null, null,
				EarnCode,0,0, OTOpt, OTSched,
				0,0,0,OccupCat,CatStatus,
				'N', null, null, null, ActiveYN,
				'N','N','Y',null,'Y', 
				Suffix,Email,Shift, Country, HDAmt, F1Amt, LCFStock, LCPStock ,
				WOTaxState, WOLocalCode, 'N', 'N' 
   			FROM dbo.bHRRM WITH (nolock) 
   			WHERE HRCo = @hrco and HRRef = @hrref
   
   			if @@rowcount = 1
   			begin
   				update dbo.bHRRM set ExistsInPR='Y', PREmp = @employee
   				where HRCo = @hrco and HRRef = @hrref
   
   				delete from dbo.bHRHP where HRCo = @hrco and HRRef = @hrref and UpdateOpt='H'
   
   			end
   			else
   			begin
   				select @errmsg = 'Error inserting into the PR Employee Master, data in
   				HR may have changed after record was set to be ready for HRRef# '
   				+ convert(varchar(10),@hrref), @rcode = 1
   				rollback transaction
   				goto bspexit
   			end
    
   			if @w4complete ='Y' and exists(select 1 from dbo.bHRWI where HRCo = @hrco and
   			HRRef = @hrref)
   			begin
   				exec @rcode = bspHRPRUpdateW4 @hrco, @prco, @hrref, @employee, @msg 
   				if @rcode = 0
   					commit transaction
   				else
   				begin
   					select @errmsg = 'Unable to insert W4 information for Employee ' + convert(varchar(5), @employee) 
   					if @msg is not null
   						select @errmsg = @errmsg + ' ' + @msg
   					rollback transaction
   					goto bspexit
   				end
   			end
   			else
   				--no W4 info.  PREH insert was successful, commit the transaction.
   				commit transaction
   		end
   
   		fetch next from curs_HRRef into @hrref, @employee, @prco, @sortname, @ssn, @w4complete, @glco	
   	end
   
   --going from PR to HR 
   
   		declare curs_Employees cursor local fast_forward for
   			select h.Employee, p.SSN, p.SortName, h.PRCo 
   			from dbo.bHRHP h join dbo.bPREH p on h.PRCo = p.PRCo and h.Employee = p.Employee
   			where h.HRCo = @hrco /*and h.PRCo = @prco*/
                 and h.UpdateOpt = 'P' and h.Status = '0'
   
   		open curs_Employees
   
   		select @openprcurs = 1
   
   		fetch next from curs_Employees into @employee, @ssn, @sortname, @prco
   
   		while @@fetch_status = 0
   		begin
   			--Set HRRef to PR Employee number
   			select @hrref = @employee
   
   			--Check to see if this HRRef has already been used.  If so set HRRef to the max HRRef + 1
   			if exists(select 1 from dbo.bHRRM with (nolock) where HRCo = @hrco and HRRef = @hrref)
   				select @hrref= isnull(max(HRRef),0)+1 from dbo.bHRRM with (nolock) where HRCo = @hrco --issue #5359
   
                 /* do a final validation before inserting - things could have change from when
   				HRHP was populated.*/
   			exec @rcode = bspHRValdateBeforeUpdate @hrco, 'P', @prco, @employee, @hrref, @errmsg output
    
   			if @rcode <> 0
   			begin
   				select @errmsg = @errmsg + ' must be corrected before update can occur.',@rcode = 1
   			  	goto bspexit
   			end
   			  	 
				IF (@defaultcountry = 'AU' AND @ssn IN ('333-333-333', '444-444-444', '111-111-111', '000-000-000')) OR
					(not exists(select 1 from dbo.bHRRM with (nolock) where HRCo = @hrco and SSN = @ssn) and not exists(select 1 from dbo.bHRRM with (nolock) where HRCo = @hrco and SortName = @sortname))
				begin
					begin transaction 
					INSERT dbo.bHRRM (
						HRCo, HRRef, PRCo, PREmp, LastName, FirstName, MiddleName, SortName,
						Address, City, State, Zip, Address2, Phone, CellPhone, SSN, Race, Sex, BirthDate, HireDate,
						TermDate, PRGroup, PRDept, StdCraft, StdClass, StdInsCode, StdTaxState,
						StdUnempState, StdInsState, StdLocal, ActiveYN, ExistsInPR, NoContactEmplYN,
						DriveCoVehiclesYN,PhysicalYN, HandicapYN,RelativesYN,PassPort,
						NoRehireYN,W4CompleteYN, EarnCode, Suffix, OccupCat,CatStatus,Email,OTOpt,OTSched,Shift,
						HDAmt, F1Amt, LCFStock, LCPStock, WOTaxState, WOLocalCode)
					SELECT 
						@hrco, @hrref, PRCo, Employee,LastName,FirstName,MidName,SortName,
						Address,City,State,Zip,Address2,Phone,CellPhone,SSN,Race,Sex,BirthDate,HireDate,
						TermDate,PRGroup,PRDept,Craft,Class,InsCode,TaxState,
						UnempState,InsState,LocalCode,ActiveYN,'Y','N',
						'N','N','N','N','N','N',
						'Y', EarnCode, Suffix, OccupCat,CatStatus, Email,OTOpt,OTSched,Shift, HDAmt, F1Amt, LCFStock, LCPStock,
						WOTaxState, WOLocalCode
					FROM dbo.bPREH WITH (NOLOCK) 
					WHERE PRCo = @prco and
					Employee = @employee
				
					
					if @@rowcount = 1 --Insert successful
					begin
   						delete from dbo.bHRHP where HRCo = @hrco and Employee = @employee and PRCo = @prco and UpdateOpt='P'
   	 				end
   					else
   					begin
   						select @errmsg = 'Error inserting HRRef ' + convert(varchar(5), @hrref) + ', Employee ' + convert(varchar(5), @employee), @rcode = 1
   						rollback transaction
   						goto bspexit
   					end
   
   					if not exists (select 1 from dbo.bHRWI with (nolock) where HRCo = @prco and HRRef = @employee)
   					begin
   						insert dbo.bHRWI (HRCo, HRRef, DednCode, FileStatus, RegExemp,AddionalExemp,OverrideMiscAmtYN,
						MiscAmt1,MiscFactor, AddonType, AddonRateAmt, MiscAmt2)
   						select @hrco, @hrref, d.DLCode, d.FileStatus, d.RegExempts, d.AddExempts, d.OverMiscAmt, 
						isnull(d.MiscAmt,0), d.MiscFactor, d.AddonType, d.AddonRateAmt, isnull(d.MiscAmt2, 0)
   						from dbo.bPRED d with (nolock) join dbo.bPRDL l with (nolock) on
   						d.PRCo = l.PRCo and d.DLCode = l.DLCode
   						where d.PRCo = @prco and d.Employee = @employee and l.Method = 'R' and l.DLType = 'D' --#133605 added Type check
   
   						if @@error <> 0	
   						begin
   							select @errmsg = 'Error inserting Filing information for HRRef ' + convert(varchar(5), @hrref) + ', Employee ' + convert(varchar(5), @employee), @rcode = 1
   							rollback transaction
   							goto bspexit
   						end
   					end
   
   					commit transaction
   				end -- //
   					
   				fetch next from curs_Employees into @employee, @ssn, @sortname, @prco
   
                 end
   
       bspexit:
   
   	if @openhrcurs = 1
   	begin
   		close curs_HRRef
   		deallocate curs_HRRef
   	end
   
   	if @openprcurs = 1
   	begin
   		close curs_Employees
   		deallocate curs_Employees
   	end
   
      	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspHRInitPRUpdate] TO [public]
GO
