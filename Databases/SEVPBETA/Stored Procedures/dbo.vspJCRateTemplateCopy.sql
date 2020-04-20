SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[vspJCRateTemplateCopy]
/*******************************************************************
* CREATED BY:		DANF 02/19/07
* MODIFIED By:		CHS	06/16/2009	- issue #132119
*					CHS	09/29/2009	- issue #132119
*					CHS	10/22/2009	- issue #135997
*
* USAGE
* Pass in From and To rate template to copy one template
* to a new template.  It will copy JCRT and all JCRD entries.
* If to rate template exists or any detail then an 
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
   declare @rcode int, @i int, @company bCompany, @template smallint, @craft bCraft, @class bClass, @employee bEmployee, @detailseq smallint
   	 
   
   /* initialize counters and flags */
   select @rcode = 1, @errmsg='Undefined error copying rate template ' + isnull(convert(varchar(5),@fromtemplate),'') + ' to ' + isnull(convert(varchar(5),@totemplate),'') + '.'
   
   
   /* check for source JC company */
   if @fromcompany = 0
   	begin
   	select @errmsg = 'Missing source JC company!', @rcode = 1
   	goto bspexit
   	end
   
   /* check for existance of FromTemplate*/
   if not exists(select * from bJCRT with (nolock) where JCCo=@fromcompany and RateTemplate=@fromtemplate)
   	begin
   	select @errmsg = 'The rate template you are trying to copy from does not exits.', @rcode = 1
   	goto bspexit
   	end
   
   
   /* check to see if to InsTemplate exists in JCRateTemplate*/
   if exists(select * from bJCRT with (nolock) where JCCo=@tocompany and RateTemplate=@totemplate)
   	begin
   	select @errmsg = 'You cannot copy to an existing template. Enter a new template number.', @rcode = 1
   	goto bspexit
   	end
   
   /* check to see if to InsTemplate exists in JCRD*/
   if exists(select * from bJCRD with (nolock) where JCCo=@tocompany and RateTemplate=@totemplate)
   	begin
   	select @errmsg = 'The rate template you are copying already has detail set up.  You must choose a different template to copy to.', @rcode = 1
   	goto bspexit
   	end
   


	-- validate Craft, Class, and Employee in the To Company
	declare @ratedetailtable table (Seq int identity(1,1), Company bCompany, Template smallint, Craft bCraft null, Class bClass null, Employee bEmployee null, DetailSeq smallint null)
	insert into @ratedetailtable(Company, Template, Craft, Class, Employee, DetailSeq)
	select PRCo, RateTemplate, Craft, Class, Employee, Seq from bJCRD where JCCo = @fromcompany and RateTemplate = @fromtemplate



	-- Loop through each detail record
	set @i = 1
	while @i <= (select max(Seq) from @ratedetailtable)
		begin
		select @company = Company, @template = Template, @craft = Craft, @class = Class, @employee = Employee, @detailseq = DetailSeq from @ratedetailtable where Seq = @i

		-- #135997
		/* check to see if the Craft value is not provided while the Class value has been provided */
		if isnull(@craft, '') = '' and isnull(@class, '') <> ''
			begin 
				select @errmsg = 'Detail Sequence: ' + cast(isnull(@detailseq, 0) as varchar) + '  Craft code mssing where and Class is not Null.', @rcode = 1
				goto bspexit
			end 			

		/* check to see if Craft exists in From Company PRCM */
		if isnull(@craft, '') <> ''
			begin 
			select top 1 1 from bPRCM where @tocompany = PRCo and @craft = Craft
			if @@rowcount = 0
				begin 
				select @errmsg = 'The Craft: ' + cast(@craft as varchar) + ' is not set up in the To Company: ' + cast(@tocompany as varchar) + ' in PR Craft Master.', @rcode = 1
				goto bspexit
				end
			end 

		/* check to see if Class exists in PRCC */
		if isnull(@class, '') <> ''
			begin 
			select top 1 1 from bPRCC where @tocompany = PRCo and @craft = Craft and @class = Class
			if @@rowcount = 0
				begin 
				select @errmsg = 'The Craft: ' + cast(@craft as varchar) + ' and Class: ' + cast(@class as varchar) + ' is not set up in the To Company: ' + cast(@tocompany as varchar) + ' in PR Craft Classes.', @rcode = 1
				goto bspexit
				end
			end 


		/* check to see if Employee exists in PREH */
		if isnull(@employee, 0) <> 0
			begin 
			select top 1 1 from bPREH where @tocompany = PRCo and @employee = Employee
			if @@rowcount = 0
				begin 
				select @errmsg = 'The Employee: ' + cast(@employee as varchar) + ' is not set up in the To Company: ' + cast(@tocompany as varchar) + ' in PR Employees.', @rcode = 1
				goto bspexit
				end
			end


		set @i = @i+1
		end

   
   begin transaction
   /* Now copy JCRT information */
   insert into bJCRT(JCCo, RateTemplate, Description, EffectiveDate, Notes) 
					select @tocompany, @totemplate, @todesc, EffectiveDate, Notes 
					from bJCRT 
					where JCCo=@fromcompany and RateTemplate=@fromtemplate
   
   /* Now copy JCRD (detail) information */
   insert into bJCRD(JCCo, RateTemplate, Seq, PRCo, Craft, Class, Shift, EarnFactor, Employee, OldRate, NewRate)
				select @tocompany, @totemplate, Seq, PRCo, Craft, Class, Shift, EarnFactor, Employee, OldRate, NewRate 
				from bJCRD 
				where JCCo=@fromcompany and RateTemplate=@fromtemplate

   commit transaction
   
   
   select @rcode = 0, @errmsg='Rate template ' + isnull(convert(varchar(5),@fromtemplate),'') + ' copied to ' + isnull(convert(varchar(5),@totemplate),'') + '.'
   
   
   bspexit:
      
      return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCRateTemplateCopy] TO [public]
GO
