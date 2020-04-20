SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMGetNextSubmittal    Script Date: 11/05/2003 2:44:29 PM ******/
   CREATE procedure [dbo].[bspPMGetNextSubmittal]
    /************************************************************************
    * CREATED:    DC 11/5/03  Issue 20658 - Allow the + feature to work at submittal number.    
    * MODIFIED:   
    *
    *
    * Purpose of Stored Procedure
    *
    *	Get the next submittal number: (max(submittal) + 1        
    *    
    *           
    * Notes about Stored Procedure
    * 
    * returns 0 if successfull 
    * returns 1 and error msg if failed
    *
    *************************************************************************/
   	(@pmco bCompany, @project bJob, @type bDocType, @subno int output, @errmsg varchar(255) output)   	
   
    as
    set nocount on
    
   	declare @rcode int, @autogen varchar(10)
   	select @rcode = 0
   
   --Validate parameters
   	IF @pmco = null
   	BEGIN
   		Select @errmsg = 'Missing PM Company.', @rcode = 1
   		goto bspexit
   	END
   
   	IF @project = null
   	BEGIN
   		Select @errmsg = 'Missing PM Project.', @rcode = 1
   		goto bspexit
   	END
   
   	IF @type = null
   	BEGIN
   		Select @errmsg = 'Missing PM Submittal Type.', @rcode = 1
   		goto bspexit
   	END
   
   
   --check to see if the auto generate option is set to Project or Project and Type
   	select @autogen = AutoGenSubNo
   	from dbo.bJCJM with (nolock)
   	where JCCo = @pmco and Job = @project
   
   	IF @autogen = 'P' 
   	BEGIN
   		select @subno = max(cast(Submittal as numeric) +1) 
   		from dbo.bPMSM with (nolock)
   		where PMCo = @pmco
   		and Project = @project
   		and isnumeric(Submittal) = 1
   	END
   	IF @autogen = 'T'
   	BEGIN
   		select @subno = max(cast(Submittal as numeric) +1) 
   		from dbo.bPMSM with (nolock)
   		where PMCo = @pmco
   		and Project = @project
   		and SubmittalType = @type
   		and isnumeric(Submittal) = 1
   	END
   
     IF @subno is null select @subno = 1
    
    bspexit:
    
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMGetNextSubmittal] TO [public]
GO
