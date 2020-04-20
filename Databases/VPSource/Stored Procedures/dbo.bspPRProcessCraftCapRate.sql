SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRProcessCraftCapRate    Script Date: 8/28/99 9:35:36 AM ******/
       
CREATE       procedure [dbo].[bspPRProcessCraftCapRate]
/***********************************************************
* CREATED BY: 	GG  04/15/98
* MODIFIED BY:  GG  04/15/98
*				GG 11/16/01 - #15219 - fixed cap rate adjustment when using new rates and limits
*				GG 04/04/02 - #16860 - pull std liab rates for capped codes
*				GG 05/03/02 - #16862 - use actual addon rates when capping liabs
*				GG 08/13/02 - #18168 - correct capped rate, use only first occurence of posted earnings
*				GG 02/21/03 - #20364 - don't include liabilities in Capped Basis if not setup with Craft or Employee
*				EN 11/20/03 - issue 21846  do not include capped basis liabs in calculation where bPRED Frequency is not active for the Pay Period
*				EN 5/7/04 - 21846  while working on this issue found bug in issue 21846 fix where empl liab was always screened for correct frequency rather than only if empl liab is empl based as was intended
*				GG 07/07/04 - #25034 - fix capped basis rate total
*				CHS	02/21/2011	- #142620
*
* USAGE:
* Determines old and new rates for Craft based liabilities when adjusted
* for Capped Codes and Limits.
* Called from bspPRProcessCraft procedure.
*
* INPUT PARAMETERS
*   @prco              	PR Company
*   @craft             	Craft
*   @class             	Class
*   @template	        Craft Template
*   @dlcode            	Liability being processed
*	@employee			Employee
*   @effectdate        	Craft effective date
*   @oldcaplimit       	Cap limit prior to effective date
*   @newcaplimit       	Cap limit on or after effective date
*
* OUTPUT PARAMETERS
*   @oldrate           Rate prior to Craft effective date - adjusted for old limit
*   @newrate           Rate used on or after effective date - adjusted for new limit
*   @errmsg  			Error message if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
 	@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @craft bCraft = null, 
	@class bClass = null, @template smallint = null,
	@dlcode bEDLCode = null, @employee bEmployee = null, @effectdate bDate = null, @oldcaplimit bDollar = null,
	@newcaplimit bDollar = null, @oldrate bUnitCost output, @newrate bUnitCost output, @errmsg varchar(255) output
    
        
     as
     set nocount on
     
    declare @rcode int, @totaloldrate bUnitCost, @totalnewrate bUnitCost, @oldsaverate bUnitCost,
     	@newsaverate bUnitCost, @eltype char(1), @elcode bEDLCode, @adjustoldrateby bUnitCost,
    	@adjustnewrateby bUnitCost, @seq tinyint, @stdoldrate bUnitCost, @stdnewrate bUnitCost,
    	@adjoldrate bUnitCost, @adjnewrate bUnitCost, @hours bHrs, @oldposted tinyint, @newposted tinyint
    
     
     -- cursor flags
     declare @openBasis tinyint, @openCapSeq tinyint
     
    -- initialize accumulators and flags used to indicate whether posted earnings included in rate
    select @rcode = 0, @totaloldrate = 0.00, @totalnewrate = 0.00, @oldposted = 0, @newposted = 0
     
    -- save standard old and new rates passed into this procedure, these will be passed back
    -- if not reduced by cap limits.
    select @oldsaverate = @oldrate, @newsaverate = @newrate
    
    -- use cursor to cycle through all basis earnings and liabs to accumulate total rate
    declare bcBasis cursor for
    select ELType, ELCode from bPRCB where PRCo = @prco and Craft = @craft
     
    open bcBasis
    select @openBasis = 1
       
    -- loop through rows in Capped Code Basis cursor
    next_Basis:
    	fetch next from bcBasis into @eltype, @elcode
       	if @@fetch_status = -1 goto end_Basis
       	if @@fetch_status <> 0 goto next_Basis
       
    	-- reset rates 
        select @oldrate = 0.00, @newrate = 0.00
    
       	if @eltype = 'E'   -- Earnings
     		begin
    		select @hours = 0.00
       		-- get old rate 
       		-- CHS	02/15/2011	- #142620 deal with divide by zero 
       		-- select top 1 @oldrate = (Rate / Factor), @hours = Hours	-- STE of first occurence
       		select top 1 @oldrate = case when Factor = 0.00 then 0.00 else (Rate / Factor) end, @hours = Hours	-- STE of first occurence
     		from bPRPE
            where VPUserName = SUSER_SNAME() and EarnCode = @elcode and PostDate < @effectdate and Amt <> 0	-- #25034 skip 0.00 earnings
    		if @hours <> 0 and @oldposted = 1 select @oldrate = 0.00	-- posted earning already included	
    		if @hours <> 0 select @oldposted = 1	-- if hours, assume this is posted earnings and set flag
    		
            -- get new rate
    		select @hours = 0.00
    		-- CHS	02/15/2011	- #142620 deal with divide by zero 
    		-- select top 1 @newrate = (Rate / Factor), @hours = Hours	-- STE of first occurence
            select top 1 @newrate = case when Factor = 0.00 then 0.00 else (Rate / Factor) end, @hours = Hours	-- STE of first occurence
            from bPRPE
            where VPUserName = SUSER_SNAME() and EarnCode = @elcode and PostDate >= @effectdate and Amt <> 0	-- #25034 skip 0.00 earnings
            if @hours <> 0 and @newposted = 1 select @newrate = 0.00	-- posted earning already included	
    		if @hours <> 0 select @newposted = 1	-- if hours, assume this is posted earnings and set flag
            end
            
     	if @eltype = 'L'        -- Liability
       		begin
    		-- #20364 - skip liabilities not setup with Craft or Employee
    		if not exists(select 1 from bPRCI      -- Craft Items
             			where PRCo = @prco and Craft = @craft and EDLType = 'L' and EDLCode = @elcode)
    		and not exists(select 1 from bPRED		-- Employee 
            			where PRCo = @prco and Employee = @employee and DLCode = @elcode) goto next_Basis
    
    		select @oldrate = RateAmt1, @newrate = RateAmt1	
     		from bPRDL			-- DL master
     		where PRCo = @prco and DLCode = @elcode
       		select @oldrate = OldRate, @newrate = NewRate
            from bPRCI      -- Craft Items
            where PRCo = @prco and Craft = @craft and EDLType = 'L' and EDLCode = @elcode and Factor = 0.00
       		select @oldrate = OldRate, @newrate = NewRate
            from bPRCD      -- Class Dedns/Liabs
            where PRCo = @prco and Craft = @craft and Class = @class and DLCode = @elcode and Factor = 0.00
       		select @oldrate = OldRate, @newrate = NewRate
            from bPRTI      -- Template Items
            where PRCo = @prco and Craft = @craft and Template = @template and EDLType = 'L'
       			and EDLCode = @elcode and Factor = 0.00
       		select @oldrate = OldRate, @newrate = NewRate
            from bPRTD      -- Template Dedns/Liabs
            where PRCo = @prco and Craft = @craft and Class = @class and Template = @template
       			and DLCode = @elcode and Factor = 0.00
        		-- check for Employee override - use a single rate
    		select @oldrate = e.RateAmt, @newrate = e.RateAmt 
    		from bPRED e
    		where e.PRCo = @prco and e.Employee = @employee and e.DLCode = @elcode and 
    			e.OverCalcs = 'R' and 
    			(EmplBased='N' or (EmplBased='Y' and exists (select * from bPRAF a where a.PRCo=e.PRCo and a.PRGroup=@prgroup and 
    					a.PREndDate=@prenddate and a.Frequency=e.Frequency))) -- issue 21846 check for valid frequency
            end
       
     	/* accumulate total rate */
         select @totaloldrate = @totaloldrate + @oldrate
         select @totalnewrate = @totalnewrate + @newrate
    
       	goto next_Basis
       
       	end_Basis:
     	  	close bcBasis
     	  	deallocate bcBasis
     	  	select @openBasis = 0
       
     
     -- check for rate adjustment
     select @adjustoldrateby = @totaloldrate - @oldcaplimit
     if @adjustoldrateby < 0.00 select @adjustoldrateby = 0.00     -- under cap, no adjustment needed
     if @oldcaplimit = 0.00 select @adjustoldrateby = 0.00         -- no cap, no adjustment needed
     
     select @adjustnewrateby = @totalnewrate - @newcaplimit
     if @adjustnewrateby < 0.00 select @adjustnewrateby = 0.00     -- under cap, no adjustment needed
     if @newcaplimit = 0.00 select @adjustnewrateby = 0.00         -- no cap, no adjustment needed
     
     if @adjustoldrateby = 0.00 and @adjustnewrateby = 0.00
       	begin
       	select @oldrate = @oldsaverate, @newrate = @newsaverate     -- use saved rates
       	goto bspexit
       	end
       
     -- rates need adjustment - use a cursor to process Capped codes in Sequence order
     declare bcCapSeq cursor for
     select Seq, ELType, ELCode from bPRCS where PRCo = @prco and Craft = @craft
     order by Seq
     
     open bcCapSeq
     select @openCapSeq = 1
       
     next_CapSeq:
     	fetch next from bcCapSeq into @seq, @eltype, @elcode
       	if @@fetch_status = -1 goto end_CapSeq
       	if @@fetch_status <> 0 goto next_CapSeq
       
       	select @oldrate = 0.00, @newrate = 0.00
       
         if @eltype = 'E'    -- Earnings, must be an Addon
     		begin
    		-- #16862 - use actual addon rates when capping liabs
    		-- get old rate
    		set rowcount 1      -- use the first instance
    		-- CHS	02/15/2011	- #142620 deal with divide by zero 
    		-- select @oldrate = Rate / Factor
    		select @oldrate = case when Factor = 0.00 then 0.00 else Rate / Factor end
    		from bPRPE
    		where VPUserName = SUSER_SNAME() and EarnCode = @elcode and PostDate < @effectdate
    		-- get new rate
    		-- CHS	02/15/2011	- #142620 deal with divide by zero 
    		-- select @newrate = Rate / Factor
    		select @newrate = case when Factor = 0.00 then 0.00 else Rate / Factor end
    		from bPRPE
    		where VPUserName = SUSER_SNAME() and EarnCode = @elcode and PostDate >= @effectdate
    		set rowcount 0      -- reset row count limit
     		end
     	if @eltype = 'L'    -- Liability
             begin
     		select @oldrate = RateAmt1, @newrate = RateAmt1	
     		from bPRDL			-- DL master
       		select @oldrate = OldRate, @newrate = NewRate
             from bPRCI      -- Craft Items
             where PRCo = @prco and Craft = @craft and EDLType = 'L' and EDLCode = @elcode and Factor = 0.00
       		select @oldrate = OldRate, @newrate = NewRate
             from bPRCD      -- Class Dedns/Liabs
             where PRCo = @prco and Craft = @craft and Class = @class and DLCode = @elcode and Factor = 0.00
       	    select @oldrate = OldRate, @newrate = NewRate
             from bPRTI      -- Template Items
             where PRCo = @prco and Craft = @craft and Template = @template and EDLType = 'L'
       			and EDLCode = @elcode and Factor = 0.00
       		select @oldrate = OldRate, @newrate = NewRate
             from bPRTD      -- Template Dedns/Liabs
             where PRCo = @prco and Craft = @craft and Class = @class and Template = @template
       			and DLCode = @elcode and Factor = 0.00
       		-- check for Employee override - use a single rate
       		select @oldrate = RateAmt, @newrate = RateAmt
               from bPRED
               where PRCo = @prco and Employee = @employee and DLCode = @elcode and OverCalcs = 'R'
       		end
       
     	-- adjust capped code rate
       	select @stdoldrate = @oldrate, @stdnewrate = @newrate
       	select @adjoldrate = @stdoldrate - @adjustoldrateby
       	if @adjoldrate < 0.00 select @adjoldrate = 0.00
         select @adjnewrate = @stdnewrate - @adjustnewrateby
       	if @adjnewrate < 0.00 select @adjnewrate = 0.00
     
       	-- if the adjusted code equals our current Liability, we are done
       	if @eltype = 'L' and @elcode = @dlcode
       		begin
       		select @oldrate = @adjoldrate, @newrate = @adjnewrate
       		goto end_CapSeq
       		end
       
       	-- correct total rates and see if another capped code needs to be reduced
       	select @totaloldrate = @totaloldrate - @stdoldrate + @adjoldrate
       
       	select @adjustoldrateby = @totaloldrate - @oldcaplimit
           if @adjustoldrateby < 0.00 select @adjustoldrateby = 0.00     -- under cap, no adjustment needed
           if @oldcaplimit = 0.00 select @adjustoldrateby = 0.00         -- no cap, no adjustment needed
       
           select @totalnewrate = @totalnewrate - @stdnewrate + @adjnewrate
       	select @adjustnewrateby = @totalnewrate - @newcaplimit
           if @adjustnewrateby < 0.00 select @adjustnewrateby = 0.00     -- under cap, no adjustment needed
           if @newcaplimit = 0.00 select @adjustnewrateby = 0.00         -- no cap, no adjustment needed
       
       	if @adjustoldrateby > 0.00 or @adjustnewrateby > 0.00 goto next_CapSeq
       
         -- no more adjustments needed, use saved rates
     	select @oldrate = @oldsaverate, @newrate = @newsaverate
       
       	end_CapSeq:
       		close bcCapSeq
       		deallocate bcCapSeq
       		select @openCapSeq = 0
       
       bspexit:
           if @openBasis = 1
               begin
               close bcBasis
               deallocate bcBasis
               end
           if @openCapSeq = 1
               begin
               close bcCapSeq
       		deallocate bcCapSeq
               end
       
           return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessCraftCapRate] TO [public]
GO
