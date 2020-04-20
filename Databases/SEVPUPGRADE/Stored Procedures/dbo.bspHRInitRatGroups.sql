SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRInitRatGroups    Script Date: 5/6/2003 11:22:31 AM ******/
    
    
    /****** Object:  Stored Procedure dbo.bspHRInitRatGroups    Script Date: 2/4/2003 7:39:19 AM ******/
    /****** Object:  Stored Procedure dbo.bspHRInitRatGroups    Script Date: 8/28/99 9:32:51 AM ******/
    CREATE   procedure [dbo].[bspHRInitRatGroups]
    /*************************************
    * Created by: ae
    * Modified by: 3/17/99 kb
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
    (@HRCo bCompany = null, @RatingGroup varchar(10), @PositionCode varchar(10), @RefNum bHRRef, @RefDate bDate, @msg varchar(60) output)
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
    
      select @KeyCode = min(Code) from HRRI
          where HRCo = @HRCo and RatingGroup = @RatingGroup
      while @KeyCode is not null
         begin
           select @Code = @KeyCode
           select @Seq = isnull(max(Seq),0)+1 from bHRRP
            where HRCo = @HRCo and HRRef = @RefNum and ReviewDate = @RefDate
           insert HRRP (HRCo,HRRef,ReviewDate,Seq,Code,Rating)
           values(@HRCo,@RefNum,@RefDate,@Seq,@Code,0)
           if @@rowcount = 0
            begin
              select @msg = 'Error inserting rating code.',@rcode=1
              goto bspexit
            end
           select @msg = convert(varchar(4),@Seq)
           --print @msg
           select @KeyCode = min(Code) from HRRI
             where HRCo=@HRCo and RatingGroup = @RatingGroup and Code > @Code
           if @@rowcount=0 select @KeyCode = null
          end
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRInitRatGroups] TO [public]
GO
