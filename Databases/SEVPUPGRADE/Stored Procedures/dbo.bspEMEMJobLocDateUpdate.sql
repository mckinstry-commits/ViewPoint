SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      Proc [dbo].[bspEMEMJobLocDateUpdate] 
    /*********************************************************
    *	Created by TV 04/12/04
    *	Altered by TV 11/08/04 26051 - Updating JCCo when it should not.
    *		   TV 12/14/04 26522 -UpdateYN flag keeps getting set to N and never back to Y
    *	Created to update the EMEM Job, JobDate and DateLastUsed.
    *
    *	inputs:
    *	@EMCo - bCompnay
    *	@Equipment - bEquip
    *	@jcco bCompany
    *	@Job - bJob
    *	@JobDate - bDate
    *	@LastUsedDate - bDate
    *
    *	Outputs:
    *	@rcode - int
    *	@errmsg - varchar(255)
    *********************************************************/
    (@emco bCompany, @equip bEquip, @jcco bCompany, @job bJob, @jobdate bDate, @lastuseddate bDate, 
     @errmsg varchar(255) output)
    
    as
    set nocount on
    
    declare @rcode int, @joblocationupdate char
    
    select @rcode = 0
    
   
    if isnull(@emco,'') = ''
    	begin
    	select @errmsg = 'EMCo must not be null.', @rcode = 1
    	goto bspexit
    	end
    
    if isnull(@equip,'') = ''
    	begin
    	select @errmsg = 'Equipment must not be null.', @rcode = 1
    	goto bspexit
    	end
    
    select @joblocationupdate = JobLocationUpdate from bEMCO e where e.EMCo = @emco
    
   
    update bEMEM 
    set JCCo = case when @joblocationupdate  <> 'N' and isnull(e.JobDate,'') <= isnull(@jobdate,'') then @jcco else e.JCCo end,--@jcco, 26051 - Updating JCCo when it should not.  
    Job = case when @joblocationupdate  <> 'N' and isnull(e.JobDate,'') <= isnull(@jobdate,'') then @job else e.Job end,
    Location = case when(@joblocationupdate = 'U' and isnull(e.Job,'') <> isnull(@job,'')) then null else Location end, 
    JobDate = case when @joblocationupdate  <> 'N'and isnull(e.Job,'') <> isnull(@job,'')  and 
    		  isnull(e.JobDate,'') < isnull(@jobdate,'') then @jobdate else JobDate end,
    LastUsedDate = case when isnull(LastUsedDate,'') < isnull(@lastuseddate,'') then @lastuseddate else LastUsedDate end,
    UpdateYN = 'N' -- avoid HQMA auditing
    from dbo.bEMEM e with (nolock) 
    join dbo.bJCJM j  with (nolock) on @jcco = j.JCCo and @job = j.Job       -- must be an existing Job
    where EMCo = @emco and Equipment = @equip and (@jobdate >= e.JobDate or e.JobDate is null) --issue 21505
    
    -- issue 16023 fix for rejection - change bEMEM UpdateYN values back to 'Y'
    update dbo.bEMEM
    set UpdateYN = 'Y'
    from dbo.bEMEM e with (nolock) --TV 12/14/04 26522 -UpdateYN flag keeps getting set to N and never back to Y
    where EMCo = @emco and Equipment = @equip and e.UpdateYN = 'N'--e.JobDate = @jobdate --issue 21505
    
    
    
    bspexit:
    
    if @rcode <> 0 Select @errmsg = @errmsg		--+ ' -bspEMEMJobLocDateUpdate'
    	
    
    return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEMJobLocDateUpdate] TO [public]
GO
