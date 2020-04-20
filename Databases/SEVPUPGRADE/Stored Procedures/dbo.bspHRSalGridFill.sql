SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRSalGridFill    Script Date: 8/28/99 9:32:54 AM ******/
    CREATE    procedure [dbo].[bspHRSalGridFill]
    /*************************************
    *  Created by:  ??
    *  Modified by: CMW 05/09/02 issue # 16806 - changed sort order, put newest first.
    		kb 2/24/3 - issue #19095 changed to calculate percent increase 
   		mh 12/15/04 - Issue 25727.  Overflow error.  Changed convert to 16,4.
    
    * Initializes the performance ratings group for this position
    *
    * Pass:
    *   HRCo
    *   HRRef
    
    * Success returns:
    *	0
    *
    * Error returns:
    *	1 and error message
    **************************************/
   	(@HRCo bCompany, @HRRef bHRRef)
   as
   	set nocount on
   	declare @rcode int
    
   	select @rcode = 0
    
   	begin
   
   		select h.EffectiveDate, h.OldSalary, h.NewSalary, h.NewPositionCode,
   	 	h.NextDate, TotalPct = case when h.OldSalary = 0 then
   	  	0 else convert(numeric(16,4),(h.NewSalary/h.OldSalary) - 1) * 100 end
   		from HRSH h
   	    where h.HRCo = @HRCo and h.HRRef = @HRRef
   	    order by h.EffectiveDate DESC
    
   	end
    
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRSalGridFill] TO [public]
GO
