SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRClaimsGrid    Script Date: 8/28/99 9:32:49 AM ******/
   CREATE  procedure [dbo].[bspHRClaimsGrid]
   /*************************************
   *
   * Pass:
   *   HRCo          
   *   Accident
   
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@HRCo bCompany, @Accident varchar(10))
   as
       set nocount on
       declare @rcode int
   
   
   select @rcode = 0
   
   begin          
   	select h.ClaimSeq, h.ClaimDate, ResourceName = (select p.Name from HRCC p 
            where p.HRCo = h.HRCo and p.ClaimContact = h.ClaimContact), h.Notes, h.Cost, h.Deductible, h.PaidAmt, h.FiledYN, h.PaidYN
           from HRAC h 
           where h.HRCo = @HRCo and h.Accident = @Accident
   end 
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRClaimsGrid] TO [public]
GO
