SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspFRXGLParts] (@glco as bCompany)
/******************************************** Created: JRE 7/26/05  Issues 28905 - new procedure
* Modified: JRE 11/14/05  Issues 30350  - account for 10 or more characters in length
*			GG 10/16/07 - #125791 - fix for DDDTShared
*			GG 02/29/08 - #127031 - fix for bFRXAcct
*
*
* This procedure retrives the GL part numbers and descriptions along with the length of the part 
*
* 
*************************************************/
as
set nocount on

declare @datatype as varchar(10)
declare @Mask varchar(30),@Len tinyint,@S tinyint,@L tinyint,
		@Seg tinyint,@L1 tinyint,@S1 char(1),@L2 tinyint,@S2 char(1),
		@L3 tinyint,@S3 char(1),@L4 tinyint,@S4 char(1),@L5 tinyint,
		@S5 char(1),@L6 tinyint,@S6 char(1)
  
set nocount on  

-- #127031 - if bFRXAcct datatype exists with a non-null mask use it for account parts
select @datatype = Datatype, @Mask = InputMask
from dbo.DDDTShared (nolock) where Datatype = 'bFRXAcct'  
if @@rowcount = 0 or @Mask is null
	begin
	select @datatype = Datatype, @Mask = InputMask 
	from dbo.DDDTShared with (nolock) where Datatype = 'bGLAcct' 
	end
	
select @Len=DataLength(@Mask)
select @L1=0,@L2=0,@L3=0,@L4=0,@L5=0,@L6=0,@S1='',@S2='',@S3='',@S4='',@S5='',@S6=''
--- segment 1
select @S=1,@Seg=1,@L=1
if substring(@Mask,@S+1,1) in ('0','1','2','3','4','5','6','7','8','9')  
	select @L=2
select @L1=convert(tinyint,substring(@Mask,@S,@L))
select @S1=case when substring(@Mask,@S+@L+1,1)='N' then 0 else 1 end
select @S=@S+@L+2
if @S>@Len 
	goto exitsp
--- segment 2
select @Seg=2,@L=1
if substring(@Mask,@S+1,1) in  ('0','1','2','3','4','5','6','7','8','9')  
select @L=2
select @L2=convert(tinyint,substring(@Mask,@S,@L))
select @S2=case when substring(@Mask,@S+@L+1,1)='N' then 0 else 1 end
select @S=@S+@L+2
if @S>@Len 
	goto exitsp
--- segment 3
select @Seg=3,@L=1
if substring(@Mask,@S+1,1) in  ('0','1','2','3','4','5','6','7','8','9')  
	select @L=2
select @L3=convert(tinyint,substring(@Mask,@S,@L))
select @S3=case when substring(@Mask,@S+@L+1,1)='N' then 0 else 1 end
select @S=@S+@L+2
if @S>@Len 
	goto exitsp
--- segment 4
select @Seg=2,@L=1
if substring(@Mask,@S+1,1) in  ('0','1','2','3','4','5','6','7','8','9')  
	select @L=2
select @L4=convert(tinyint,substring(@Mask,@S,@L))
select @S4=case when substring(@Mask,@S+@L+1,1)='N' then 0 else 1 end
select @S=@S+@L+2
if @S>@Len 
	goto exitsp
--- segment 5
select @Seg=2,@L=1
if substring(@Mask,@S+1,1) in ('0','1','2','3','4','5','6','7','8','9')  
	select @L=2
select @L5=convert(tinyint,substring(@Mask,@S,@L))
select @S5=case when substring(@Mask,@S+@L+1,1)='N' then 0 else 1 end
select @S=@S+@L+2
if @S>@Len 
	goto exitsp
--- segment 6
select @Seg=6,@L=1
if substring(@Mask,@S+1,1) in  ('0','1','2','3','4','5','6','7','8','9')  
	select @L=2
select @L6=convert(tinyint,substring(@Mask,@S,@L))
select @S6=case when substring(@Mask,@S+@L+1,1)='N' then 0 else 1 end

select @S=@S+@L+2
if @S>@Len 
	goto exitsp
	
exitsp:
 
set nocount off
select PartNo,Description=isnull(GLPD.Description,''),
   Length=case PartNo when 1 then @L1 when 2 then @L2 when 3 then @L3
                                      when 4 then @L4 when 5 then @L5 when 6 then @L6 end ,
   Seperator=case PartNo when 1 then @S1 when 2 then @S2 when 3 then @S3
                                      when 4 then @S4 when 5 then @S5 when 6 then @S6 end
from dbo.DDDTShared (nolock)
cross join GLPD 
where Datatype=@datatype and GLCo=@glco

GO
GRANT EXECUTE ON  [dbo].[bspFRXGLParts] TO [public]
GO