SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspPRProcessEmpl]
 /***********************************************************
 * CREATED BY: 	GG  04/22/98
 * MODIFIED BY: GG 04/22/99  (SQL 7.0)
 *              LM 06/15/99  More SQL 7.0 - Added username to PRPE
 *              GG 07/05/99 - added routine procedure check
 *              GG 07/08/99 - handle Ohio School Distict Tax routine - moved from bspPRProcessLocal
 *              GG 01/06/00 - fix AP Vendor info update to bPRDT
 *              GG 04/10/00 - added special limit check to Rate of Net calcs
 *              DANF 08/15/00 - remove reference to system user id
 *              EN 9/14/00 - bPRDD cursor wasn't looking for PRGroup and PREndDate in bPRAF
 *	            GG 12/16/00 - use stanard rate for Rate of Net if not setup in bPRED - issue #11339
 *              GG 01/30/01 - skip calculations for both dedns and liabs if calculation basis = 0 (#11690)
 *              EN 9/12/01 - issue 13564 (EIC feature)
 *				MV 1/28/02 - issue 15711 - check for correct CalcCategory
 *				???			- issue 13977 - round @calcamt if RndToDollar flag is set.
 *              EN 2/22/02 - issue 16377 - insert bPRDS was missing field list
 *              DANF 03/18/02 - Added deduction/liability code to Missing routine message.
 *				EN 10/9/02 - issue 18877 change double quotes to single
 *				EN 3/24/03 - issue 11030 rate of earnings liability limit
 *				EN 1/27/04 - issue 18862 allocate garnishments when disposable limit is reached
 *				EN 7/28/04 - issue 24545  call new routine bspPRExemptRateOfGross
 *				EN 9/24/04 - issue 20562  change from using bPRCO_LiabDist to bPREC_IncldLiabDist to determine whether an earnings code is included in liab distribs
 *				GG 10/15/04 - #25661 - modified for new routine procedures (bspPRMedicalLiab##, bspPRPensionDeduct##)
 *				EN 4/8/05 - issue 28379  added @@error check to see if SQL error occured when routine was called
 *				GG 01/20/06 - #119961 - Trinidad Tax routine
 *				EN 8/10/09 - #133605 AUS Superannuation Guarantee
 *				EN 10/21/2009 #133605 fix code to correctly apply Superannuation limit
 *				mh 02/19/2010 #137971 - modified to allow date compares to use other then calendar year.
 *				CHS 10/28/2010 - #140541 - refactor
 *				MV 08/28/2012 - TK-17452 include Payback Amt in deduction amounts from PRDT
 *				CHS 10/15/2012 - D-06057 TK-18537 - extracted EFTs into its own procedure.
 *			 KK/EN 08/12/2013 - 54576 Added parameters PreTaxGroup and PreTaxCatchUpYN to bspPRProcessEmplDednLiabCalc
 *
 * USAGE:
 * Calculates Employee based deductions and liabilities for a select Employee and Pay Seq.
 * Generates Direct Deposit distibutions if Employee Pay Seq to be paid by EFT.
 * Called from main bspPRProcess procedure.
 *
 * INPUT PARAMETERS
 *   @prco	    PR Company
 *   @prgroup	PR Group
 *   @prenddate	PR Ending Date
 *   @employee	Employee to process
 *   @payseq	Payment Sequence #
 *   @ppds      # of pay periods in a year
 *   @limitmth  Pay Period limit month
 *   @stddays   standard # of days in Pay Period
 *   @bonus     indicates a Bonus Pay Sequence - Y or N
 *   @posttoall earnings posted to all days in Pay Period - Y or N
 *
 * OUTPUT PARAMETERS
 *   @errmsg  	Error message if something went wrong
 *
 * RETURN VALUE
 *   0   success
 *   1   fail
 *****************************************************/
@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
@ppds tinyint, @limitmth bMonth, @stddays tinyint, @bonus bYN,
@posttoall bYN, @errmsg varchar(255) output
 
 as
 set nocount on
 
 declare @rcode int, 
		 @calcamt bDollar, 
		 @amt bDollar
 
-- Standard deduction/liability variables
declare @dlcode bEDLCode
 
-- Direct Depost variables
declare @earns bDollar, @dedns bDollar, @netpay bDollar, @routingid varchar(10), @bankacct varchar(20), @seq tinyint,
@ddtype char(1), @ddmethod char(1), @ddpct bPct, @ddamt bDollar, @dsseq tinyint, @dsamt bDollar, @amtdist bDollar

-- cursor flags
declare @openEmplDL tinyint, @openDirDep tinyint
 
-- Garnishment Allocation variables
declare @maxprocseq tinyint, @maxpercent bRate, @garngroup bGroup, @allocmethod char(1), @disposable bDollar,
@procseq tinyint, @allocgarn bYN, @totalallocgarn bDollar, @dedncode bEDLCode, @dednamt bDollar, 
@allocpercent bRate, @allocamt bDollar, @numallocs tinyint, @allocgroup tinyint, @numrows int

declare @AllocDedns table(DednCode smallint, Amount numeric(12,2))

-- issue #133605 AUS Superannuation Guarantee
declare @workstate varchar(4)

--137971
declare @yearendmth tinyint, @accumbeginmth bMonth, @accumendmth bMonth

select @yearendmth = case h.DefaultCountry when 'AU' then 6 else 12 end
from dbo.bHQCO h with (nolock) 
where h.HQCo = @prco

exec vspPRGetMthsForAnnualCalcs @yearendmth, @limitmth, @accumbeginmth output, @accumendmth output, @errmsg output

select @rcode = 0

select @totalallocgarn = 0

-- clear Process Earnings
delete dbo.bPRPE where VPUserName = SUSER_SNAME()
 
 -- load Process Earnings with all earnings posted to this Employee and Pay Seq
 insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt) -- Timecards --issue 20562
 select SUSER_SNAME(), h.PostSeq, h.PostDate, h.EarnCode, e.Factor, e.IncldLiabDist, h.Hours, h.Rate, h.Amt --issue 20562
 from dbo.bPRTH h
 join dbo.bPREC e with (nolock) on e.PRCo = h.PRCo and e.EarnCode = h.EarnCode
 where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
 and h.Employee = @employee and h.PaySeq = @payseq
 
 insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt) -- Addons --issue 20562
 select SUSER_SNAME(), a.PostSeq, t.PostDate, a.EarnCode, e.Factor, e.IncldLiabDist, 0, a.Rate, a.Amt --issue 20562
 from dbo.bPRTA a
 join dbo.bPRTH t on t.PRCo = a.PRCo and t.PRGroup = a.PRGroup and t.PREndDate = a.PREndDate
 and t.Employee = a.Employee and t.PaySeq = a.PaySeq and t.PostSeq = a.PostSeq
 join dbo.bPREC e with (nolock) on e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
 where a.PRCo = @prco and a.PRGroup = @prgroup and a.PREndDate = @prenddate
 and a.Employee = @employee and a.PaySeq = @payseq
 
 -- issue 18862 get first garn alloc group
 select @allocgroup = min(e.CSAllocGroup) from dbo.bPRED e with (nolock)
 join dbo.bPRAF f with (nolock) on f.PRCo = e.PRCo and f.Frequency = e.Frequency
 where e.PRCo = @prco and e.Employee = @employee and e.CSAllocYN = 'Y' and
 	f.PRGroup = @prgroup and f.PREndDate = @prenddate
 
 -- issue 18862 verify that alloc groups and processing seqs are assigned in correct processing order
 if @allocgroup is not null
 	begin
 	select @numrows = count(*) from dbo.bPRED e with (nolock)
 	join dbo.bPRAF f with (nolock) on f.PRCo = e.PRCo and f.Frequency = e.Frequency
 	where e.PRCo = @prco and e.Employee = @employee and e.CSAllocYN = 'Y' and
 	 	f.PRGroup = @prgroup and f.PREndDate = @prenddate and e.CSAllocGroup is not null
 		and (select count(*) from dbo.bPRED ed with (nolock) 
 				join dbo.bPRAF af with (nolock) on af.PRCo = ed.PRCo and af.Frequency = ed.Frequency
 				where ed.PRCo = @prco and ed.Employee = @employee and ed.CSAllocYN = 'Y' and
 				 	af.PRGroup = @prgroup and af.PREndDate = @prenddate and 
					((ed.CSAllocGroup > e.CSAllocGroup and isnull(str(ed.ProcessSeq, 3), ' ') < isnull(str(e.ProcessSeq, 3), ' '))
					or (ed.CSAllocGroup < e.CSAllocGroup and isnull(str(ed.ProcessSeq,3), ' ') > isnull(str(e.ProcessSeq, 3), ' ')))
					) > 0

 	if @numrows > 0
 		begin
 		select @errmsg='Processing sequences and Garnishment Allocations Groups out of order for employee ' + convert(varchar(6),@employee), @rcode=1
 		goto bspexit
 		end
 	end
 
 -- issue 18862 get highest processing seq # of garnishments to be allocated
 select @maxprocseq = null
 if @allocgroup is not null
 	begin
 	select @maxprocseq = max(e.ProcessSeq) from dbo.bPRED e with (nolock)
 	join dbo.bPRAF f with (nolock) on f.PRCo = e.PRCo and f.Frequency = e.Frequency
 	where e.PRCo = @prco and e.Employee = @employee and e.CSAllocYN = 'Y' and
 	 	f.PRGroup = @prgroup and f.PREndDate = @prenddate and CSAllocGroup = @allocgroup
 	end
 
 -- issue 18862 get garnishment allocation info
 if @maxprocseq is not null
 	begin
 	select @maxpercent = CSLimit, @garngroup = CSGarnGroup, @allocmethod = CSAllocMethod 
 	from dbo.bPREH with (nolock)
 	where PRCo = @prco and Employee = @employee
 	end
 
 -- create cursor for active Employee DLs - ordered by Processing Seq#
 declare bcEmplDL cursor for
 -- get all Employee DLs that are not marked as Pre-Tax		
 select e.ProcessSeq, e.DLCode, e.CSAllocYN
 from dbo.bPRED e with (nolock)
	join dbo.bPRAF f with (nolock) on f.PRCo = e.PRCo and f.Frequency = e.Frequency
	join dbo.bPRDL d with (nolock) on d.PRCo = e.PRCo and d.DLCode = e.DLCode
 where e.PRCo = @prco 
	and e.Employee = @employee 
	and e.EmplBased = 'Y'
	and f.PRGroup = @prgroup 
	and f.PREndDate = @prenddate 
	and d.PreTax = 'N' -- we only want non-PreTax Dls as the PreTax DLs have already been calculated at this point.	
 order by e.ProcessSeq
 
 open bcEmplDL
 select @openEmplDL = 1
 
 -- loop through Employee DL cursor
 next_EmplDL:
	fetch next from bcEmplDL into @procseq, @dlcode, @allocgarn
	if @@fetch_status = -1 goto end_EmplDL
	if @@fetch_status <> 0 goto next_EmplDL

    -- get a specific Empployee Deduction/Liability acummulations
	exec @rcode = bspPRProcessEmplDednLiabCalc @prco, @dlcode, @prgroup, @prenddate, 
		@employee, @payseq, @ppds, @limitmth, @stddays, @bonus, @posttoall, 
		@accumbeginmth, @accumendmth, NULL, 'N', @calcamt output, @errmsg output

	if @rcode<> 0 goto bspexit


	-- issue 18862 tally up garnishments to be allocated and add to @AllocDedns
	IF @allocgarn = 'Y'
		BEGIN
		SELECT @totalallocgarn = @totalallocgarn + @calcamt
		INSERT @AllocDedns (DednCode, Amount) VALUES (@dlcode, @calcamt)
		END

	-- issue 18862 compute garnishment allocations IF disposable income exceeded
	IF @maxprocseq is not null -- maxprocseq is not null IF there are garnishments to allocate
		BEGIN
		IF @procseq = @maxprocseq -- do allocations after last garnishment to allocate has been processed
			BEGIN
			-- compute disposable income (one time only) for garnishment allocations based on garnishment group and max % allowed
			IF @disposable is null
				BEGIN
				IF @maxprocseq is not null
					BEGIN
					SELECT @disposable = 0

					SELECT @earns = isnull(sum(Amount),0.00)
					FROM dbo.bPRDT t WITH (NOLOCK)
						join dbo.bPRGI g WITH (NOLOCK) ON t.PRCo = g.PRCo and t.EDLType = g.EDType and t.EDLCode = g.EDCode
					WHERE t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
						and t.PaySeq = @payseq and t.EDLType = 'E' and g.GarnGroup = @garngroup

					SELECT @dedns = isnull(sum(case t.UseOver when 'Y' then t.OverAmt ELSE t.Amount	END ),0.00)
					FROM dbo.bPRDT t WITH (NOLOCK)
						join dbo.bPRGI g WITH (NOLOCK) ON t.PRCo = g.PRCo and t.EDLType = g.EDType and t.EDLCode = g.EDCode
					WHERE t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
						and t.PaySeq = @payseq and t.EDLType = 'D' and g.GarnGroup = @garngroup

					SELECT @disposable = (@earns - @dedns) * @maxpercent
					IF @disposable < 0 SELECT @disposable = 0 --handle negative disposable
					END
				END

			IF @totalallocgarn > @disposable
				BEGIN
				IF @allocmethod = 'P' -- prorate
					BEGIN
					DECLARE bcAlloc CURSOR FOR SELECT DednCode, Amount FROM @AllocDedns
					OPEN bcAlloc
					AllocLoopP: 
					FETCH NEXT FROM bcAlloc INTO @dedncode, @dednamt
					IF @@fetch_status = -1 GOTO endAllocLoopP

					-- UPDATE deductions with adjusted amounts
					UPDATE dbo.bPRDT
					SET Amount = (@dednamt / @totalallocgarn) * @disposable
					WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
						and PaySeq = @payseq and EDLType = 'D' and EDLCode = @dedncode

					GOTO AllocLoopP
					endAllocLoopP:
					CLOSE bcAlloc
					DEALLOCATE bcAlloc
					END

				IF @allocmethod = 'D' -- divide equally
					BEGIN
					SELECT @numallocs = count(*) FROM @AllocDedns WHERE Amount <> 0 -- get total number of dedns to allocate
					DECLARE bcAlloc CURSOR FOR SELECT DednCode, Amount FROM @AllocDedns ORDER BY Amount
					OPEN bcAlloc
					AllocLoopD: 
					FETCH NEXT FROM bcAlloc INTO @dedncode, @dednamt
						IF @@fetch_status = -1 GOTO endAllocLoopD
						IF @dednamt < @disposable / @numallocs
							SELECT @disposable = @disposable - @dednamt, @numallocs = @numallocs - 1
						ELSE
							BEGIN
							-- UPDATE deductions with adjusted amounts
							UPDATE dbo.bPRDT
							SET Amount = @disposable / @numallocs
							WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
								and PaySeq = @payseq and EDLType = 'D' and EDLCode = @dedncode
							END
						GOTO AllocLoopD
						endAllocLoopD:
						CLOSE bcAlloc
						DEALLOCATE bcAlloc
					END

				SELECT @disposable = 0 --disposable amount all used up
				END
			
			ELSE
				SELECT @disposable = @disposable - @totalallocgarn

			-- clear AllocDedns table variable
			DELETE FROM @AllocDedns

			-- clear total group allocation amount to prep for next group
			SELECT @totalallocgarn = 0
			
			-- get next garn alloc group
			SELECT @allocgroup = min(e.CSAllocGroup) FROM dbo.bPRED e WITH (NOLOCK)
				join dbo.bPRAF f WITH (NOLOCK) ON f.PRCo = e.PRCo and f.Frequency = e.Frequency
			WHERE e.PRCo = @prco and e.Employee = @employee and e.CSAllocYN = 'Y' and
		 		f.PRGroup = @prgroup and f.PREndDate = @prenddate and e.CSAllocGroup > @allocgroup
			
			-- get highest processing seq # of garnishments to be allocated in this alloc group
			SELECT @maxprocseq = null
			IF @allocgroup is not null
				BEGIN
				SELECT @maxprocseq = max(e.ProcessSeq) FROM dbo.bPRED e WITH (NOLOCK)
					join dbo.bPRAF f WITH (NOLOCK) ON f.PRCo = e.PRCo and f.Frequency = e.Frequency
				WHERE e.PRCo = @prco and e.Employee = @employee and e.CSAllocYN = 'Y' and
					f.PRGroup = @prgroup and f.PREndDate = @prenddate and CSAllocGroup = @allocgroup
				END
			END
		END

  
 goto next_EmplDL
 
 end_EmplDL:
 close bcEmplDL
 deallocate bcEmplDL
 select @openEmplDL = 0


 -- perform direct deposits
 EXEC @rcode = bspPRProcessEmplEFT @prco, @prgroup, @prenddate, @employee, @payseq, @errmsg OUTPUT		
			 
 
	 
 bspexit:
 -- clear Payroll Process entries
 delete dbo.bPRPE where VPUserName = SUSER_SNAME()
 
 if @openEmplDL = 1
	begin
	close bcEmplDL
	deallocate bcEmplDL
	end
 
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessEmpl] TO [public]
GO
