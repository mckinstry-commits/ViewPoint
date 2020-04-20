SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRRatingsFromPositions    Script Date: 2/4/2003 7:46:28 AM ******/
   /****** Object:  Stored Procedure dbo.bspHRRatingsFromPositions    Script Date: 8/28/99 9:32:53 AM ******/
   CREATE    procedure [dbo].[bspHRRatingsFromPositions]
   /*************************************
   * Created by: 3/17/99 kb
   * Modified by:
   * Initializes the performance ratings group for this position
   *
   * Pass:
   *   HRCo          - Human Resources Company
   *   PositionCode  - Position Code
   *   RefNum        - Reference Number
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@HRCo bCompany = null,@position varchar(10), @RefNum bHRRef, @ReviewDate bDate,
   	@msg varchar(60) output)
   as
       set nocount on
       declare @rcode int, @Seq int, @KeySeq int, @Code varchar(20)
   
   select @rcode = 0
   
   
   if @HRCo is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   
   if @RefNum is null
   	begin
   	select @msg = 'Missing Resource #', @rcode = 1
   	goto bspexit
   	end
   
   if @ReviewDate is null
   	begin
   	select @msg = 'Missing Review Date', @rcode = 1
   	goto bspexit
   	end
   
   if @position is null
   	begin
   	select @msg = 'Missing Position Code', @rcode = 1
   	goto bspexit
   	end
   
   
   
   declare RatingsPos_curs Cursor Local Fast_Forward for
   select r.Code
   from HRPR r with (nolock)
   where r.HRCo = @HRCo and r.PositionCode = @position and r.Code not in (
   select p.Code from HRRP p with (nolock) where p.HRCo = r.HRCo and p.Code = r.Code and p.HRRef = 1
   and p.ReviewDate = @ReviewDate)
   
   open RatingsPos_curs
   
   fetch next from RatingsPos_curs into @Code
   
   while @@fetch_status = 0
   begin
   
   	select @Seq = isnull(max(Seq),0)+1 from bHRRP
   	where HRCo = @HRCo and HRRef = @RefNum and ReviewDate = @ReviewDate
   
   	insert bHRRP (HRCo,HRRef,ReviewDate, Seq,Code, Rating)
   	values(@HRCo,@RefNum,@ReviewDate, @Seq,@Code,0)
   
   	fetch next from RatingsPos_curs into @Code
   
   end
   
   close RatingsPos_curs
   deallocate RatingsPos_curs
   
   /*
   select @KeySeq = min(Seq) from HRPR
         where HRCo = @HRCo and PositionCode = @position
     while @KeySeq is not null
        begin
        select @Code = Code from HRPR where HRCo = @HRCo and PositionCode = @position and Seq = @KeySeq
         select @Seq = isnull(max(Seq),0)+1 from bHRRP
   	where HRCo = @HRCo and HRRef = @RefNum and ReviewDate = @ReviewDate
   
          insert bHRRP (HRCo,HRRef,ReviewDate, Seq,Code, Rating)
          values(@HRCo,@RefNum,@ReviewDate, @Seq,@Code,0)
          if @@rowcount = 0
           begin
             select @msg = 'Error inserting rating code.',@rcode=1
             goto bspexit
           end
          select @KeySeq = min(Seq) from HRPR
            where HRCo=@HRCo and PositionCode = @position and Seq > @KeySeq
          if @@rowcount=0 select @KeySeq = null
         end
   */
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRRatingsFromPositions] TO [public]
GO
