SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRPRUpdateFlags    Script Date: 9/13/2001 2:24:48 PM ******/
   
   /****** Object:  Stored Procedure dbo.bspHRPRUpdateFlags    Script Date: 9/13/2001 9:41:05 AM ******/
   
   CREATE     procedure [dbo].[bspHRPRUpdateFlags]
   /************************************************************************
   * CREATED: MH 9/11/01   
   * MODIFIED:  mh 7/23/03 Issue 18913
   *
   * Purpose of Stored Procedure
   *
   *   Get the cross update flags from HRCO.  Used in both 
   *	HR and PR.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   	(@co bCompany, @updatenameyn varchar(5) output, @updateaddressyn varchar(5) output,
   	@updatehiredateyn varchar(5) output, @updateactiveyn varchar(5) output,
   	@updateprgroupyn varchar(5) output, @updatetimecardyn varchar(5) output,
   	@updatew4yn varchar(5) output, @updateoccupyn varchar(5) output, @updatessnYN varchar(5) output)
   
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	--Get the update flags from HRCO.  Transforming them into True/False 
   	--values as they are being held in boolean variables in VB.
   	select @updatenameyn = case UpdateNameYN when 'Y' then 'True' else 'False' end,
   	@updateaddressyn = case UpdateAddressYN when 'Y' then 'True' else 'False' end, 
   	@updatehiredateyn = case UpdateHireDateYN when 'Y' then 'True' else 'False' end, 
   	@updateactiveyn = case UpdateActiveYN when 'Y' then 'True' else 'False' end,
       @updateprgroupyn = case UpdatePRGroupYN when 'Y' then 'True' else 'False' end, 
   	@updatetimecardyn = case UpdateTimecardYN when 'Y' then 'True' else 'False' end, 
   	@updatew4yn = case UpdateW4YN  when 'Y' then 'True' else 'False' end,
   	@updateoccupyn = case UpdateOccupCatYN when 'Y' then 'True' else 'False' end,
   	@updatessnYN = case UpdateSSNYN when 'Y' then 'True' else 'False' end
   	from HRCO 
   	where HRCo = @co
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRPRUpdateFlags] TO [public]
GO
