SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspFRXSegmentation    Script Date: 8/28/99 9:34:38 AM ******/
CREATE  proc [dbo].[bspFRXSegmentation]
/**************************************
* Created: JRE 7/7/98 
* Modified:	GG 10/16/07 - #125791 - fix for DDDTShared
*
* this proc retrieves the information needed for the OFSI segmentation
*
***************************************/
as
declare @cnt tinyint, @pos tinyint, @partno tinyint,@len tinyint, @descr varchar(30)

set nocount on

select @cnt=1,@pos=1

select @partno=min(PartNo)
from bGLPD where GLCo=1

create table #tmpGLPart
(SegNum tinyint not null,PartNo tinyint not null,SegDesc varchar(30) null,
 SegLen tinyint not null,StartPos tinyint not null)
 
while @partno is not null
	begin
	select @len=convert(tinyint,substring(InputMask,(PartNo-1)*3+1,1))+
		case when substring(InputMask,(PartNo-1)*3+3,1)='N' then 0 else 1 end,
		@descr=bGLPD.Description
	from dbo.DDDTShared, bGLPD
	where Datatype='bGLAcct' and GLCo=1 and PartNo=@partno
	
insert into #tmpGLPart
select @cnt,@partno,@descr,@len,@pos
-- add up the positions and cnt
select @cnt=@cnt+1,@pos=@pos+@len
select @partno=min(PartNo) from bGLPD where PartNo>@partno and GLCo=1
end

set nocount off
select * from #tmpGLPart

GO
GRANT EXECUTE ON  [dbo].[bspFRXSegmentation] TO [public]
GO
