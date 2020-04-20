SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRInitPositionRatingGroups    Script Date: 2/4/2003 7:38:05 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspHRInitPositionRatingGroups    Script Date: 8/28/99 9:32:51 AM ******/
   CREATE  procedure [dbo].[bspHRInitPositionRatingGroups]
   /*************************************
   * Created by:  3/17/99 kb
   * Modified by:
   * Initializes the performance ratings group for this position
   *
   * Pass:
   *   HRCo          - Human Resources Company
   *   RatingGroup   - Group to be initialized
   *   PositionCode  - Position Code
   *   RefNum        - Reference Number
   *   RefDate  	  - Reference Date
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@HRCo bCompany = null, @RatingGroup varchar(10), @PositionCode varchar(10), @msg varchar(60) output)
   as
       set nocount on
       declare @rcode int
       declare @Seq int
       declare @KeyCode varchar(20)
       declare @Code varchar(20)
      	
   
   select @rcode = 0
   
   
   if @HRCo is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @RatingGroup is null
   	begin
   	select @msg = 'Missing Rating Group', @rcode = 1
   	goto bspexit
   	end
   
   if @PositionCode is not null
   begin
     select @KeyCode = min(Code) from HRRI
         where HRCo = @HRCo and RatingGroup = @RatingGroup
     while @KeyCode is not null
        begin
          select @Code = @KeyCode
          select @Seq = isnull(max(Seq),0)+1 from bHRPR
           where HRCo = @HRCo and PositionCode = @PositionCode
          insert HRPR (HRCo,PositionCode,Seq,Code)
          values(@HRCo,@PositionCode,@Seq,@Code)
          if @@rowcount = 0
           begin
             select @msg = 'Error inserting rating code.',@rcode=1
   
             goto bspexit
           end
          select @msg = convert(varchar(4),@Seq)
          print @msg
          select @KeyCode = min(Code) from HRRI
            where HRCo=@HRCo and RatingGroup = @RatingGroup and Code > @Code
          if @@rowcount=0 select @KeyCode = null
         end
   end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRInitPositionRatingGroups] TO [public]
GO
