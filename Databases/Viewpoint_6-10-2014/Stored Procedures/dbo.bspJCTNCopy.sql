SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCTNCopy    Script Date: 8/28/99 9:35:07 AM ******/
/****** Object:  Stored Procedure dbo.bspJCTNCopy    Script Date: 2/12/97 3:25:08 PM ******/
CREATE    procedure [dbo].[bspJCTNCopy]
/*******************************************************************
* CREATED BY:	SE	10/15/1996
* MODIFIED By:	SE	10/15/1996
*				TV				- 23061 added isnulls
*				danf			- Update Message for Dick
*				CHS	06/16/2009	- issue #132119
*				CHS	09/29/2009	- issue #132119
*				CHS	01/18/2009	- issue #137531
*
* USAGE
* Pass in From and To Insurance template to copy one template
* to a new template.  It will copy JCTN and all JCTI entries.
* If to insurance template exists or any detail then an 
* Error will occur and nothing will be copied.
* PASS IN
*    From Company	Company to be doing copy from
*    To Company		Company to be doing copy to
*    FromTemplate	Template to copy from     
*    ToTemplate		Template to copy to
*
* returns 0 and message reporting successful copy              
* Returns 1 and error message if unable to process.
********************************************************************/
(@fromcompany bCompany = 0, @tocompany bCompany = 0, @fromtemplate smallint, 
	@totemplate smallint, @todesc varchar(60), @errmsg varchar(255) output)

   as
   set nocount on

   declare @rcode int, @i int, @phasegroup bGroup, @phase bPhase, @company bCompany, 
	@template smallint, @inscode bInsCode, 
	@validphasechars tinyint, @validpartofphase bPhase, @phaseerror varchar(max) -- issue #137531
   	 
   /* initialize counters and flags */
   select @rcode = 1, @errmsg='Undefined error copying insurance template ' + isnull(convert(varchar(5),@fromtemplate),'') + ' to ' + isnull(convert(varchar(5),@totemplate),'') + '.'
   
   
   /* check for source JC company */
   if @fromcompany = 0
   	begin
   	select @errmsg = 'Missing source JC company!', @rcode = 1
   	goto bspexit
   	end
   
   /* check for existance of FromTemplate*/
   if not exists(select * from bJCTN with (nolock) where JCCo=@fromcompany and InsTemplate=@fromtemplate)
   	begin
   	select @errmsg = 'The insurance template you are trying to copy from does not exits.', @rcode = 1
   	goto bspexit
   	end
   
   
   /* check to see if to InsTemplate exists in JCTN*/
   if exists(select * from bJCTN with (nolock) where JCCo=@tocompany and InsTemplate=@totemplate)
   	begin
   	select @errmsg = 'You cannot copy to an existing template. Enter a new template number.', @rcode = 1
   	goto bspexit
   	end
   
   /* check to see if to InsTemplate exists in JCTI*/
   if exists(select * from bJCTI with (nolock) where JCCo=@tocompany and InsTemplate=@totemplate)
		begin
			select @errmsg = 'The insurance template you are copying already has phases set up.  You must choose a different template to copy to.', @rcode = 1
			goto bspexit
		end


	/* check to see if that Phase Groups match */
	if not exists (select top 1 1 from bHQCO t with (nolock) left join bHQCO f with (nolock) on f.HQCo = @fromcompany
						where t.HQCo = @tocompany and f.HQCo = @fromcompany and t.PhaseGroup = f.PhaseGroup)
		begin
   			select @errmsg = 'Phase groups do not match! The company you are copying From must match the company you are copying To.', @rcode = 1
   			goto bspexit
		end
  


	-- validate Phase 
	declare @insurancetemplatetable table (Seq int identity(1,1), Company bCompany, Template smallint, PhaseGroup bGroup, Phase bPhase, InsCode bInsCode)

	-- get valid part of phase from bJCCO
	select  @validphasechars = ValidPhaseChars from bJCCO with (nolock) where bJCCO.JCCo = @company -- issue #137531

	insert into @insurancetemplatetable(Company, Template, PhaseGroup, Phase, InsCode)
	select JCCo, InsTemplate, PhaseGroup, Phase, InsCode from bJCTI where JCCo = @fromcompany and InsTemplate = @fromtemplate
	
	select @validphasechars = ValidPhaseChars from bJCCO where bJCCO.JCCo = @fromcompany -- issue #137531
	select @phaseerror = '' -- issue #137531

	-- Loop through each bJCTI record
	set @i = 1
	while @i <= (select max(Seq) from @insurancetemplatetable)
		begin
		select @company = Company, @phasegroup = PhaseGroup, @phase = Phase, @inscode = InsCode from @insurancetemplatetable where Seq = @i
		
		select @validpartofphase = substring(@phase, 1, @validphasechars) + '%' -- issue #137531

		/* check to see if Phase exists in JCPM */
		select top 1 1 from bJCPM where @phasegroup = PhaseGroup and Phase like @validpartofphase -- issue #137531
		if @@rowcount = 0
			begin 
			delete from @insurancetemplatetable where Seq = @i
			select @phaseerror = @phaseerror + @phase + ', ', @rcode = 1
			goto nextloop
			end

		/* check to see if Insurance Code exists in HQIC */
		select top 1 1 from bHQIC where @inscode = InsCode

		if @@rowcount = 0
			begin 
			select @errmsg = 'The Insurance Code: ' + cast(@inscode as varchar) + ' is not set up in HQ Insurance Codes.', @rcode = 1
			goto bspexit
			end

		nextloop: -- issue #137531

		set @i = @i+1
		end


   begin transaction
   /* Now copy JCTN information */
   insert into bJCTN(JCCo, InsTemplate, Description) select @tocompany, @totemplate, @todesc from bJCTN 
          where JCCo=@fromcompany and InsTemplate=@fromtemplate
          
          
   
	/* Now copy JCTI (phase) information */
	insert into bJCTI(JCCo, InsTemplate, PhaseGroup, Phase, InsCode)
		select @tocompany, @totemplate, PhaseGroup, Phase, InsCode 
		from @insurancetemplatetable

   
   commit transaction
   
   
   select @rcode = 0, @errmsg='Insurance template ' + isnull(convert(varchar(5),@fromtemplate),'') + ' copied to ' + isnull(convert(varchar(5),@totemplate),'')
   
   -- issue #137531
   if @phaseerror <> '' 
		begin
		select @errmsg = @errmsg + '. The following Phases  ' + @phaseerror + ' did not pass validation and were not copied.'
		end
   
   bspexit:
      
      return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCTNCopy] TO [public]
GO
