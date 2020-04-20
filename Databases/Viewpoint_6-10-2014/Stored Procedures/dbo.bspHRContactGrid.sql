SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRContactGrid    Script Date: 8/28/99 9:32:50 AM ******/
   CREATE  procedure [dbo].[bspHRContactGrid]
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
   	select h.ContactSeq, h.Date, h.ClaimContact, ResourceName = (select p.Name from HRCC p 
            where p.HRCo = h.HRCo and p.ClaimContact = h.ClaimContact), h.Notes, h.ClaimSeq
           from HRCL h 
           where h.HRCo = @HRCo and h.Accident = @Accident
   end 
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRContactGrid] TO [public]
GO
