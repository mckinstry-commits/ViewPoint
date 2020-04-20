SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCTHCopy    Script Date: 8/28/99 9:35:07 AM ******/
/****** Object:  Stored Procedure dbo.bspJCTHCopy    Script Date: 3/19/97 3:25:08 PM ******/
CREATE    procedure [dbo].[bspJCTHCopy]
/*******************************************************************
* CREATED BY:	CJW	3/19/1997
* MODIFIED By:	GG  6/17/1998
*               JRE 9/30/1998	- added JCTE entries
*				TV				- 23061 added isnulls
*				CHS 06/11/2009	- issue #132119
*				CHS	09/29/2009	- issue #132119
*
* USAGE
* Pass in From and To Liability template to copy one template
* to a new template.  It will copy JCTH and all JCTL & JCTE entries.
* If to Liability template exists or any detail then an
* Error will occur and nothing will be copied.
* PASS IN
*    Company      Company to be doing copy in
*    FromTemplate Template to copy from
*    ToTemplate   Template to copy to
*
* returns 0 and message reporting successful copy
* Returns 1 and error message if unable to process.
********************************************************************/
(@fromcompany bCompany = 0, @tocompany bCompany = 0, @fromtemplate smallint, 
	@totemplate smallint, @todesc varchar(60), @errmsg varchar(255) output)

   as
   set nocount on

declare @rcode int, @i int, @company bCompany, @template smallint, @phasegroup bGroup, @phase bPhase, @earncode bEDLCode

/* initialize counters and flags */
select @rcode = 1, @errmsg='Undefined error copying Liability template ' + isnull(convert(varchar(5),@fromtemplate),'') + ' to ' + isnull(convert(varchar(5),@totemplate),'') + '.'

/* check for source JC company */
if @fromcompany = 0
	begin
		select @errmsg = 'Missing source JC company!', @rcode = 1
		goto bspexit
	end

/* check for source JC company */
if @tocompany = 0
	begin
		select @errmsg = 'Missing destination JC company!', @rcode = 1
		goto bspexit
	end

/* check for existance of FromTemplate*/
if not exists(select * from bJCTH where JCCo=@fromcompany and LiabTemplate=@fromtemplate)   
	begin
		select @errmsg = 'The Liability template you are trying to copy from does not exits.', @rcode = 1
		goto bspexit
	end

/* check to see if to LiabTemplate exists in JCTH*/
if exists(select * from bJCTH where JCCo=@tocompany and LiabTemplate=@totemplate)
	begin
		select @errmsg = 'You cannot copy to an existing template. Enter a new template number.', @rcode = 1
		goto bspexit
	end


/* check to see if to LiabTemplate exists in JCTL*/
if exists(select * from bJCTL where JCCo=@tocompany and LiabTemplate=@totemplate)
	begin
		select @errmsg = 'The Liability template you are copying already has types set up.  You must choose a different template to copy to.', @rcode = 1
		goto bspexit
	end


/* check to see if that Phase Groups match */
if not exists (select top 1 1 from bHQCO t with (nolock) left join bHQCO f with (nolock) on f.HQCo = @fromcompany
					where t.HQCo = @tocompany and f.HQCo = @fromcompany and t.PhaseGroup = f.PhaseGroup)
	begin
   		select @errmsg = 'Phase groups do not match! The company you are copying From must match the company you are copying To.', @rcode = 1
   		goto bspexit
	end




	select @company = JCCo, @template = LiabTemplate, @phasegroup = PhaseGroup, @phase = Phase from bJCTH where JCCo = @fromcompany and LiabTemplate = @fromtemplate

	/* allow a null Phase as valid */
	if isnull(@phase, '') <> ''
		begin 
		/* check to see if Phase exists in JCPM */
		select top 1 1 from bJCPM where @phasegroup = PhaseGroup and @phase = Phase
		if @@rowcount = 0
			begin 
			select @errmsg = 'The Phase: ' + @phase + ' is not set up in JC Phase Master.', @rcode = 1
			goto bspexit
			end
		end 



-- validate Phases assigned to Liability Types in the To Company
declare @liabtypestemplatetable table (Seq int identity(1,1), Company bCompany, PhaseGroup bGroup, Phase bPhase null, Template smallint)


insert into @liabtypestemplatetable(Company, PhaseGroup, Phase, Template)
select JCCo, PhaseGroup, Phase, LiabTemplate from bJCTL where JCCo = @fromcompany and LiabTemplate = @fromtemplate




-- Loop through each bJCTL record
set @i = 1
while @i <= (select max(Seq) from @liabtypestemplatetable)
	begin
	select @company = Company, @phasegroup = PhaseGroup, @phase = Phase, @template = Template from @liabtypestemplatetable where Seq = @i

	/* allow a null Phase as valid */
	if isnull(@phase, '') <> ''
		begin 

		/* check to see if Phase exists in JCPM */
		select top 1 1 from bJCPM where @phasegroup = PhaseGroup and @phase = Phase
		if @@rowcount = 0
			begin 
			select @errmsg = 'The Phase: ' + @phase + '  for Liability Types is not set up in JC Phase Master.', @rcode = 1
			goto bspexit
			end
		end

	set @i = @i+1
	end


-- validate Earnings Codes in the To Company
declare @earningstemplatetable table (Seq int identity(1,1), Company bCompany, Template smallint, EarnCode bEDLCode)

insert into @earningstemplatetable(Company, Template, EarnCode)
select JCCo, LiabTemplate, EarnCode from bJCTE where JCCo = @fromcompany and LiabTemplate = @fromtemplate

-- Loop through each bJCTE record
set @i = 1
while @i <= (select max(Seq) from @earningstemplatetable)
	begin
	select @tocompany = Company, @template = Template, @earncode = EarnCode from @earningstemplatetable where Seq = @i

	/* check to see if Earnings Code exists in PRCE */
	select top 1 1 from bPREC where @company = PRCo and @earncode = EarnCode
	if @@rowcount = 0
		begin 
		select @errmsg = 'The Earnings Code: ' + cast(@earncode as varchar) + ' is not set up in the To Company: ' + cast(@company as varchar) + ' in PR Earnings Codes.', @rcode = 1
		goto bspexit
		end

	set @i = @i+1
	end



/* Now copy JCTH information */
insert into bJCTH(JCCo, LiabTemplate, Description, PhaseGroup, Phase, CostType)
select @tocompany, @totemplate, @todesc, PhaseGroup, Phase, CostType
from bJCTH
   where JCCo=@fromcompany and LiabTemplate=@fromtemplate

/* Now copy JCTL (Type) information */
insert into bJCTL(JCCo, LiabTemplate, LiabType, PhaseGroup, Phase, CostType, CalcMethod, LiabilityRate)
select @tocompany, @totemplate, LiabType, PhaseGroup, Phase, CostType, CalcMethod, LiabilityRate
from bJCTL
   where JCCo=@fromcompany and LiabTemplate=@fromtemplate

/* Now copy JCTE (Type) information */
insert into bJCTE(JCCo, LiabTemplate, LiabType, EarnCode)
select @tocompany, @totemplate, LiabType, EarnCode
from bJCTE
   where JCCo=@fromcompany and LiabTemplate=@fromtemplate
select @rcode = 0, @errmsg='Liability template ' + isnull(convert(varchar(5),@fromtemplate),'') + ' copied to ' + isnull(convert(varchar(5),@totemplate),'') + '.'

bspexit:
  return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJCTHCopy] TO [public]
GO
