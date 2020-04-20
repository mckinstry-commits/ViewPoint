SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMJobUseEstOutDateYN]
/***********************************************************
* CREATED BY: TRL Issue 129345 
* MODIFIED By :
*		
* USAGE: Warns customer that Equipment/JCCo/Job has Autotemplates that 
*use the Cat/Equip Auto Template option "Use Est Out Date" date option to calc revenue
*
* Auto Templates aren't required unless customer is calc usage/revenue for a Job
No need add validation at the time'
* INPUT PARAMETERS
*   EMCo   
*   JCCo
*   Job
*   Equipment
*
* OUTPUT PARAMETERS
*   @errmsg     
* RETURN VALUE
*   0,2   success
*   1   fails
*****************************************************/
@emco bCompany, @jcco bCompany = null, @job bJob = null,
@equipment bEquip = null, @msg varchar(max)output
   
as

set nocount on

declare @rcode int, @autotemplt_cat_cnt int, @autotemplt_equip_cnt int,
@autotemplate varchar(10),@autotemplatedesc bDesc,@category bCat

select @rcode =0, @category=''

if exists(select top 1 1 from dbo.EMJT with(nolock) where  EMCo=@emco and JCCo=@jcco and Job=@job)
begin
	if isnull(@equipment ,'')= ''
		begin
			select @autotemplate=min(h.AUTemplate),@autotemplatedesc=min(h.Description),	@autotemplt_cat_cnt=count (c.AUTemplate)
			from EMJT j with(nolock)
			inner join EMUH h with(nolock)on h.EMCo=j.EMCo and h.AUTemplate=j.AUTemplate
			Inner join EMUC c with(nolock)on c.EMCo=j.EMCo and c.AUTemplate=j.AUTemplate
			where j.EMCo=@emco and j.JCCo=@jcco and j.Job=@job and c.UseEstDateOutYN = 'Y'
			group by j.EMCo, j.JCCo,j.Job

			select  @autotemplate=min(j.AUTemplate),@autotemplatedesc=min(h.Description),@autotemplt_equip_cnt=count(e.AUTemplate) 
			from dbo.EMJT j with(nolock)
			inner join dbo.EMUH h with(nolock)on h.EMCo=j.EMCo and h.AUTemplate=j.AUTemplate
			inner join dbo.EMUE e  with(nolock)on e.EMCo=j.EMCo and e.AUTemplate=j.AUTemplate
			where j.EMCo=@emco and j.JCCo=@jcco and j.Job=@job and e.UseEstDateOutYN = 'Y'
			group by j.EMCo, j.JCCo,j.Job
			
			if @autotemplt_cat_cnt+@autotemplt_equip_cnt>0 
			BEGIN
				select @msg = 'Assigned Auto Template: '+ @autotemplate + ' "' +@autotemplatedesc +  
				'" has Category and/or Equipment template records that use "Estimate Out Date" option to calculate revenue.'	
				select @rcode = 2
			end
		end
	else
		begin
			--Equipment auto template record overrides Category auto template record
			--Equipment  template record can't exist at this time 08/09 unless a Category template records exists'
			select @autotemplate=min(j.AUTemplate),@autotemplatedesc=min(h.Description),@autotemplt_equip_cnt=count(e.AUTemplate) 
			from dbo.EMJT j with(nolock)
			inner join dbo.EMUH h with(nolock)on h.EMCo=j.EMCo and h.AUTemplate=j.AUTemplate
			inner join dbo.EMUE e  with(nolock)on e.EMCo=j.EMCo and e.AUTemplate=j.AUTemplate
			where j.EMCo=@emco and j.JCCo=@jcco and j.Job=@job
			and e.Equipment = @equipment and e.UseEstDateOutYN = 'Y'
			group by j.EMCo, j.JCCo,j.Job
						
			if @autotemplt_equip_cnt>0 
			BEGIN
				select @msg = 'Assigned Auto Template: '+ @autotemplate + ' "' +@autotemplatedesc +  '" has Equipment template record that uses "Estimate Out Date" option to calculate revenue.'	
				select @rcode = 2
				goto vspexit
			end
			
			--Get assigned Category to Equipment being transferred
			select @category =Category from dbo.EMEM with(nolock) where EMCo=@emco and Equipment =@equipment
						
			--If no Equipment Template Record exits, check Category template record
			select   @autotemplate=min(j.AUTemplate),@autotemplatedesc=min(h.Description),@autotemplt_cat_cnt=count (c.AUTemplate)
			from dbo.EMJT j with(nolock)
			inner join dbo.EMUH h with(nolock)on h.EMCo=j.EMCo and h.AUTemplate=j.AUTemplate
			Inner join dbo.EMUC c with(nolock)on c.EMCo=j.EMCo and c.AUTemplate=j.AUTemplate
			where j.EMCo=@emco and j.JCCo=@jcco and j.Job=@job 
			and c.Category = @category and c.UseEstDateOutYN = 'Y'
			group by j.EMCo, j.JCCo,j.Job
			
			if @autotemplt_cat_cnt > 0
			BEGIN
				select @msg = 'Assigned Auto Template: '+ @autotemplate + ' "' +@autotemplatedesc +  '" has Category ('+@category+') record that uses "Estimate Out Date" option to calculate revenue.'	
				select @rcode = 2
			end
		end
end

vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspEMJobUseEstOutDateYN] TO [public]
GO
