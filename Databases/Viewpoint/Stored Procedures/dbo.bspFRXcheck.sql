SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspFRXcheck] (@glco bCompany) as
 /******************************************************
* Created: JRE 4/16/02  
* Modified: JRE 9/2/04 - #25464 - added additional checks for GLPI, GLAC  
*			JRE 7/26/05 - #28905 - use FRXAcct if exists 
*			EN 10/11/06 - #120767  (see note labeled with issue # at added code)
*			GG 10/16/07 - #125791 - fix for DDDTShared
*			GG 02/29/08 - #127031 - fix for bFRXAcct
*
*
* bspFRXcheck is used to check for common errors with the data
* that will prevent FRX from functioning    
*
*********************************************************/
 
 declare @rowcount int, @cnt int, @OpenPeriod smallint, @Generic varchar(255)
 set nocount on
 
 
 create table #FRXProblems
 (Problem varchar(255))
  --- 
 --- get the parts to check on
 ---
 declare @p1 varchar(4), @p2 varchar(4), @p3 varchar(4),	@p4 varchar(4), @p5 varchar(4),
     @p6 varchar(4),	@s1 tinyint, @s2 tinyint, @s3 tinyint, @s4 tinyint, @s5 tinyint, @s6 tinyint,
     @start tinyint,
     @mask varchar(20), @i tinyint, @char char(1),@nextchar char(1), @pno tinyint, @inputtype tinyint
 declare @datatype varchar(10) --Issue 28905
 
 /* get mask for GL Account datatype */
-- if bFRXAcct type exists with a non-null mask use it for account parts
select @inputtype = InputType, @mask = InputMask
from dbo.DDDTShared (nolock) where Datatype = 'bFRXAcct'  -- #127031
if @@rowcount = 0 or @mask is null
	begin
	select @inputtype = InputType, @mask = InputMask 
	from dbo.DDDTShared with (nolock) where Datatype = 'bGLAcct' 
	end
 
if  @inputtype<>5
	begin
	insert into #FRXProblems
	select 'GLAcct in Data Dictionary is not a multi-part field.  GLAcct must be a multi-part field'
	end
if @inputtype<>5 
 	select @mask=@mask+'N'
 
select @i = 1, @pno = 1, @s1 = 0, @s2 = 0, @s3 = 0, @s4 = 0, @s5 = 0
 	/* parse GL Account input mask - get each parts # of chars and flag if separator used */
 	while @i <= datalength(@mask)
 		begin
 		select @char = substring(@mask,@i,1)
 		if @char like '[0-9]'
 		begin
 				if @pno = 1  select @p1 = @p1 + @char
 				if @pno = 2  select @p2 = @p2 + @char
 				if @pno = 3  select @p3 = @p3 + @char
 				if @pno = 4  select @p4 = @p4 + @char
 				if @pno = 5  select @p5 = @p5 + @char
 				if @pno = 6  select @p6 = @p6 + @char
 		end
 		else
 		begin
 
 		if @char not like '[0-9,L,R,F]'
 		begin
 			if @pno=1 select @s1 = 1
 			if @pno=2 select @s2 = @s1  + convert(tinyint,@p1) + case when @nextchar<>'N' then 1 else 0 end
 			if @pno=3 select @s3 = @s2  + convert(tinyint,@p2) + case when @nextchar<>'N' then 1 else 0 end
 			if @pno=4 select @s4 = @s3  + convert(tinyint,@p3) + case when @nextchar<>'N' then 1 else 0 end
 			if @pno=5 select @s5 = @s4  + convert(tinyint,@p4) + case when @nextchar<>'N' then 1 else 0 end
 			if @pno=6 select @s6 = @s5  + convert(tinyint,@p5) + case when @nextchar<>'N' then 1 else 0 end
 			select @pno = @pno + 1
     		select @nextchar=@char
 		end
 	end
 select @i = @i + 1
 
 	end
 
 
 ---
 -- Check if company is set up
 --
 
 SELECT @rowcount=count(*) FROM GLCO WHERE GLCo= @glco
 if  @rowcount=0
 begin
 insert into #FRXProblems
 select 'There is no Company set up for GLCo # ' + convert(varchar(3),@glco)  + ' in GLCO'
 end
 ---
 -- Check if budget code is set up
 ---
 /*
 -- Budget Codes are no longer required 
 select @rowcount=count(*) from GLBC where GLCo = @glco
 if (select @rowcount)=0
 begin
 insert into #FRXProblems
 select 'There are no Budget Codes set up for GLCo # ' + convert(varchar(3),@glco)  + '. At least one budget code must be set up in GL Budget Codes'
 end
 */
 
 ---
 -- check if there is records for the current month
 ---
 
 select @rowcount=count(*) 
         from GLFY 
         join GLFP on GLFY.GLCo=GLFP.GLCo and FYEMO=GLFP.Mth
 	left join GLFP CP on GLFY.GLCo=CP.GLCo and CP.Mth>=GLFY.BeginMth 
 	and CP.Mth<=GLFY.FYEMO and CP.Mth= (convert(char(2),CP.Mth,1) + '/1/' 
 	+ convert(char(4),CP.FiscalYr))
 	where GLFY.GLCo = @glco and BeginMth <= getdate()  and  getdate()< dateadd(mm,1,FYEMO)
 
 	if (select @rowcount)=0
 	begin
 		insert into #FRXProblems
 		select 'Fiscal year in GLFY is not set up. '
 	end
 
 	select @OpenPeriod=IsNull(CP.FiscalPd,0) 
 	from GLFY join GLFP on GLFY.GLCo=GLFP.GLCo and FYEMO=GLFP.Mth
 	left join GLFP CP on GLFY.GLCo=CP.GLCo and CP.Mth>=GLFY.BeginMth 
 	and CP.Mth<=GLFY.FYEMO and CP.Mth= (convert(char(2),CP.Mth,1) + '/1/' 
 	+ convert(char(4),CP.FiscalYr))
 	where GLFY.GLCo = @glco
 	if isnull(@OpenPeriod,0)=0
 	begin
 		insert into #FRXProblems
 		select 'There is no open period setup for GLCo # ' + convert(varchar(3),@glco) + ' in GL Fiscal Periods'
 	end
 ---
 
 
 ---
 --- check for accounts with no description
 --- 
 insert into #FRXProblems 
 Select top 50 'GLAcct ' + GLAcct + ' has no description in GL Accounts'
       from GLAC where GLCo=@glco and Description is null 
 
 -- check for GLPD  Issue 25464
 if not exists (select * from GLPD where GLCo=@glco and PartNo=1)
 begin 
 	insert into #FRXProblems 
 	Select 'Part 1 has not been setup in GL Account Parts Description (GLPD)'
 end
 
 -- check for GLPI
 insert into #FRXProblems 
 Select top 50 'Part ' + convert(varchar(3),PartNo) + ' '+Instance + ' has no description in GL Account Parts'
       from GLPI where GLCo=@glco and Description is null 
 
 ---
 --check each account part
 --  Issue 25464
 insert into #FRXProblems 
 select  distinct top 50 GLAcct+': AllParts is null or blank ... call Viewpoint.'
     From GLAC
 	Where (AllParts is null or AllParts='') and GLAC.GLCo = @glco 
 
 insert into #FRXProblems 
 select  distinct top 50 GLAcct+': Part1 is null or blank ... call Viewpoint.'
     From GLAC
 	Where (Part1 is null or Part1='') and GLAC.GLCo = @glco 
 
 insert into #FRXProblems 
 select  distinct top 50 'GL Account Part1 '+GLAC.Part1+' is not setup in GL Acct Parts.'
     From GLAC
 	left join GLPI on GLPI.GLCo=GLAC.GLCo and GLPI.PartNo=1 and GLPI.Instance=Part1
 	Where  GLAC.GLCo = @glco  and GLPI.Instance is null
 
 insert into #FRXProblems 
 select  distinct top 50 'GL Account Part1 '+GLAC.Part1+' is not set up in GL Accounts. Call Viewpoint.'
     From GLAC
     join dbo.DDDTShared d (nolock) on d.Datatype='GLAcct'
 	Where (GLAC.Part1 Is Null or GLAC.Part1<>substring(GLAcct,@s1,convert(tinyint,@p1))) and GLAC.GLCo = @glco 
     and @p1 is not null
 
 insert into #FRXProblems 
 select  distinct top 50 'GL Account Part2 '+GLAC.Part2+' is not setup in GL Acct Parts.'
     From GLAC
 	left join GLPI on GLPI.GLCo=GLAC.GLCo and GLPI.PartNo=2 and GLPI.Instance=Part2
 	Where isnull(GLAC.Part2,'')<>'' and GLPI.Instance is null and GLAC.GLCo = @glco 
 
 insert into #FRXProblems 
 select  distinct top 50 'GL Account Part2 '+GLAC.Part2+' is not set up in GL Accounts. Call Viewpoint.'
     From GLAC
     join dbo.DDDTShared d (nolock) on d.Datatype='GLAcct'
 	Where (GLAC.Part2 Is Null or GLAC.Part2<>substring(GLAcct,@s2,convert(tinyint,@p2))) and GLAC.GLCo = @glco 
     and @p2 is not null
 
 insert into #FRXProblems 
 select  distinct top 50 'GL Account Part3 '+GLAC.Part3+' is not setup in GL Acct Parts.'
     From GLAC
 	left join GLPI on GLPI.GLCo=GLAC.GLCo and GLPI.PartNo=3 and GLPI.Instance=Part3
 	Where isnull(GLAC.Part3,'')<>'' and GLPI.Instance is null and GLAC.GLCo = @glco 
 
 insert into #FRXProblems 
 select  distinct top 50 'GL Account Part3 '+GLAC.Part3+' is not set up GL Accounts. Call Viewpoint'
     From GLAC
     join dbo.DDDTShared d (nolock) on d.Datatype='GLAcct'
 	Where (GLAC.Part3 Is Null or GLAC.Part3<>substring(GLAcct,@s3,convert(tinyint,@p3))) and GLAC.GLCo = @glco 
     and @p3 is not null
 
 insert into #FRXProblems 
 select  distinct top 50 'GL Account Part4 '+GLAC.Part4+' is not setup in GL Acct Parts.'
     From GLAC
 	left join GLPI on GLPI.GLCo=GLAC.GLCo and GLPI.PartNo=4 and GLPI.Instance=Part4
 	Where isnull(GLAC.Part4,'')<>'' and GLPI.Instance is null and GLAC.GLCo = @glco 
 
 insert into #FRXProblems 
 select  distinct top 50 'GL Account Part4 '+GLAC.Part4+' is not set up in GL Accounts. Call Viewpoint'
     From GLAC
     join dbo.DDDTShared d (nolock) on d.Datatype='GLAcct'
 	Where (GLAC.Part4 Is Null or GLAC.Part4<>substring(GLAcct,@s4,convert(tinyint,@p4))) and GLAC.GLCo = @glco 
     and @p4 is not null
 
 insert into #FRXProblems 
 select  distinct top 50 'GL Account Part5 '+GLAC.Part5+' is not setup in GL Acct Parts.'
     From GLAC
 	left join GLPI on GLPI.GLCo=GLAC.GLCo and GLPI.PartNo=5 and GLPI.Instance=Part5
 	Where isnull(GLAC.Part5,'')<>'' and GLPI.Instance is null and GLAC.GLCo = @glco 
 
 insert into #FRXProblems 
 select  distinct top 50 'GL Account Part5 '+GLAC.Part5+' is not set up in GL Accounts. Call Viewpoint'
     From GLAC
     join dbo.DDDTShared d (nolock) on d.Datatype='GLAcct'
 	Where (GLAC.Part5 Is Null or GLAC.Part5<>substring(GLAcct,@s5,convert(tinyint,@p5))) and GLAC.GLCo = @glco 
     and @p5 is not null
 
 insert into #FRXProblems 
 select  distinct top 50 'GL Account Part6 '+GLAC.Part6+' is not setup in GL Acct Parts.'
     From GLAC
 	left join GLPI on GLPI.GLCo=GLAC.GLCo and GLPI.PartNo=6 and GLPI.Instance=Part6
 	Where isnull(GLAC.Part6,'')<>''and GLPI.Instance is null and GLAC.GLCo = @glco 
 
 insert into #FRXProblems 
 select  distinct top 50 'GL Account Part6 '+GLAC.Part6+' is not set up in GL Accounts. Call Viewpoint'
     From GLAC
     join dbo.DDDTShared d (nolock) on d.Datatype='GLAcct'
 	Where (GLAC.Part6 Is Null or GLAC.Part6<>substring(GLAcct,@s6,convert(tinyint,@p6))) and GLAC.GLCo = @glco 
     and @p6 is not null
 
 ---
 insert into #FRXProblems 
 select 'Cannot have more than 1 fiscal period  ... call Viewpoint Support.  Company '+
       convert(varchar(3),@glco)  + ' FiscalPd:'+ convert(varchar(3),FiscalPd) + ' FiscalYr:'+ convert(varchar(6),FiscalYr) 
      from GLFP where GLCo = @glco
      group by FiscalPd, FiscalYr 
      having count(*)>1
 
 --issue 120767 (Add check to catch bad beginning balances)
 insert into #FRXProblems 
 select  distinct top 50 'GL Account '+rtrim(GLAC.GLAcct)+' Budget Code: '+rtrim(GLBR.BudgetCode)
	+' Fiscal Year: '+convert(varchar(10),GLBR.FYEMO,101)+' should not have a beginning balance.  Revenue and Expense Accounts do not have beginning balances.'+
	' Remove Begin Balance using GL Monthly Budgets.'
    From GLAC
    join GLBR on GLBR.GLCo=GLAC.GLCo and GLBR.GLAcct=GLAC.GLAcct 
   	Where GLAC.AcctType in ('I','E')

 set nocount on
 select * from #FRXProblems

GO
GRANT EXECUTE ON  [dbo].[bspFRXcheck] TO [public]
GO
