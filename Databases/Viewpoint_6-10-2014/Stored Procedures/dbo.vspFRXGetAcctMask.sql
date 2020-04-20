SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[vspFRXGetAcctMask]    Script Date: 10/10/2007 12:55:05 ******/
CREATE   proc [dbo].[vspFRXGetAcctMask]
/*****************************************
* Created By:	GF 01/21/2009 MR version of bsp except with output parameters
* Modified By:	GP 12/09/2009 - 136902 Segment length calculation fixed
*
*
* this procedure will return information to frx on the
* size of an account with and without the mask and the length of
* each segment and the seperator used for each segment 
* still needs the natural segment
*
************************************************/
(@LenWithMask tinyint = 0 output, @LenWithOutMask tinyint = 0 output, @NaturalSeg tinyint = 1 output,
 @L1 tinyint = 0 output, @L2 tinyint = 0 output, @L3 tinyint = 0 output, @L4 tinyint = 0 output,
 @L5 tinyint = 0 output, @L6 tinyint = 0 output, @S1 char(1) = null output, @S2 char(1) = null output,
 @S3 char(1) = null output, @S4 char(1) = null output, @S5 char(1) = null output,
 @S6 char(1) = null output, @SP1 tinyint = 0 output, @SP2 tinyint = 0 output, @SP3 tinyint = 0 output,
 @SP4 tinyint = 0 output, @SP5 tinyint = 0 output, @SP6 tinyint = 0 output)
as
set nocount on

declare @rcode int, @Mask varchar(30), @Len tinyint, @S tinyint, @L tinyint,
		@Seg tinyint, @Sep tinyint

set @rcode = 0
set @NaturalSeg = 1

---- #127031 - if bFRXAcct datatype exists with a non-null mask use it for account parts
select @Mask = InputMask
from dbo.DDDTShared (nolock) where Datatype = 'bFRXAcct'  
if @@rowcount = 0 or @Mask is null
	begin
	select @Mask = InputMask 
	from dbo.DDDTShared with (nolock) where Datatype = 'bGLAcct' 
	end
 
 select @Len=DataLength(@Mask)
 select @L1=0,@L2=0,@L3=0,@L4=0,@L5=0,@L6=0,@S1='',@S2='',@S3='',@S4='',@S5='',@S6=''
 select @SP1=0, @SP2=0, @SP3=0, @SP4=0, @SP5=0, @SP6=0, @Sep=0
 --- segment 1
 select @S=1,@Seg=1,@L=1
 if substring(@Mask,@S+1,1) in  ('0','1','2','3','4','5','6','7','8','9') 
 	select @L=2
 select @L1=convert(tinyint,substring(@Mask,@S,@L))
 select @S1=substring(@Mask,@S+@L+1,1)
 select @Sep = case when substring(@Mask,@S+@L+1,1)='N' then 0 else 1 end
 SELECT @SP1 = 1
 select @S=@S+@L+2
 if @S>@Len 
 	goto exitsp

 --- segment 2
 select @Seg=2,@L=1
 if substring(@Mask,@S+1,1) in  ('0','1','2','3','4','5','6','7','8','9') 
 	select @L=2
 select @L2=convert(tinyint,substring(@Mask,@S,@L))
 select @S2=substring(@Mask,@S+@L+1,1)
 select @SP2 = @Sep + @L1
 select @S=@S+@L+2
 if @S>@Len 
 	goto exitsp

 --- segment 3
 select @Seg=3,@L=1
 if substring(@Mask,@S+1,1) in  ('0','1','2','3','4','5','6','7','8','9') 
 	select @L=2
 select @L3=convert(tinyint,substring(@Mask,@S,@L))
 select @S3=substring(@Mask,@S+@L+1,1)
 select @Sep = case when substring(@Mask,@S+@L+1,1)='N' then 0 else 1 end
 select @SP3 = @SP2 + @L2 --- + @Sep
 select @S=@S+@L+2
 if @S>@Len 
 	goto exitsp

 --- segment 4
 select @Seg=4,@L=1
 if substring(@Mask,@S+1,1) in  ('0','1','2','3','4','5','6','7','8','9') 
 	select @L=2
 select @L4=convert(tinyint,substring(@Mask,@S,@L))
 select @S4=substring(@Mask,@S+@L+1,1)
 select @Sep = case when substring(@Mask,@S+@L+1,1)='N' then 0 else 1 end
 select @SP4 = @SP3 + @L3 --- + @Sep
 select @S=@S+@L+2
 if @S>@Len 
 	goto exitsp
 --- segment 5
 select @Seg=5,@L=1
 if substring(@Mask,@S+1,1) in  ('0','1','2','3','4','5','6','7','8','9') 
 	select @L=2
 select @L5=convert(tinyint,substring(@Mask,@S,@L))
 select @S5=substring(@Mask,@S+@L+1,1)
 select @Sep = case when substring(@Mask,@S+@L+1,1)='N' then 0 else 1 end
 select @SP5 = @SP4 + @L5 + @Sep
 select @S=@S+@L+2
 if @S>@Len 
 	goto exitsp
 --- segment 6
 select @Seg=6,@L=1
 if substring(@Mask,@S+1,1) in  ('0','1','2','3','4','5','6','7','8','9') 
 	select @L=2
 select @L6=convert(tinyint,substring(@Mask,@S,@L))
 select @S6=substring(@Mask,@S+@L+1,1)
 select @Sep = case when substring(@Mask,@S+@L+1,1)='N' then 0 else 1 end
 select @SP6 = @SP5 + @L6 + @Sep
 select @S=@S+@L+2
 if @S>@Len 
 	goto exitsp


 exitsp:
 
 select @LenWithOutMask=@L1+@L2+@L3+@L4+@L5+@L6
 select @LenWithMask=@LenWithOutMask
 +case when @S1 in (null,'','N') then 0 else 1 end
 +case when @S2 in (null,'','N') then 0 else 1 end
 +case when @S3 in (null,'','N') then 0 else 1 end
 +case when @S4 in (null,'','N') then 0 else 1 end
 +case when @S5 in (null,'','N') then 0 else 1 end
 +case when @S6 in (null,'','N') then 0 else 1 end

	return @rcode

-- set nocount off
-- select LenWithMask=@LenWithMask,LenWithOutMask=@LenWithOutMask,NaturalSeg=1,
-- Len1=@L1,Len2=@L2,Len3=@L3,Len4=@L4,Len5=@L5,Len6=@L6,
-- Sep1=@S1,Sep2=@S2,Sep3=@S3,Sep4=@S4,Sep5=@S5,Sep6=@S6

GO
GRANT EXECUTE ON  [dbo].[vspFRXGetAcctMask] TO [public]
GO
