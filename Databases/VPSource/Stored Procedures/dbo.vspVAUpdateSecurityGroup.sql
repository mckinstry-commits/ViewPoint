SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

    
	/****** Object:  Stored Procedure dbo.vspVAUpdateSecurityGroup    Script Date: 8/28/99 9:35:48 AM ******/
	CREATE                     proc [dbo].[vspVAUpdateSecurityGroup]
	/**************************************************************
	*	Object:  Stored Procedure dbo.vspVAUpdateSecurityGroup
	**************************************************************
	*	This is used by VA Secure Data Types and Tables to update
	*	the Security Group for data types other than bJob or bContract, 
	*	when data security is turned on/off or the default security group 
	*	is changed.
	*	
	*	History:
	*		JonathanP 05/03/07 - Created and adapted from bpVAUpdateSecurityGroup
	*		JonathanP 08/21/07 - Added the Employee datatype.
	*		DC 4/21/10 - #132526 - Remove RQ to PO
	*		GF 09/23/2011 - TK-08517 added bSMCO to valid data types
	*
	**************************************************************/           
     (@Status varchar(10)=null, @Datatype varchar(30)=null, @DefaultSecurityGroup int, 
      @OldDefaultSecurityGroup int, @msg varchar(255) output) 
     
     as
     
     set nocount on
     
     begin
     	declare @rcode int
     	select @rcode = 0
     
     
     if @Status is null or @Status = ''
     	begin
     	select @msg = 'Status of Update or Clear', @rcode = 1
     	goto bspexit
     	END
     ----TK-08517
     if @Datatype is null or @Datatype not in ('APCo', 'ARCo', 'CMCo', 'EMCo', 'GLCo', 'HQCo', 
											   'INCo', 'JCCo', 'MSCo', 'POCo', 'PRCo', 'SLCo',  
											   'CMAcct', 'Loc','HRRef','JBCo', 'HRCo', 'PMCo',
											   'Employee', 'SMCo')
     	begin
     	select @msg = 'Missing valid data type.', @rcode = 1
     	goto bspexit
     	end
     
     if @Status = 'Update' and (@DefaultSecurityGroup is null or @OldDefaultSecurityGroup is null)
     	begin
     	select @msg = 'Missing Default Security Group', @rcode = 1
     	goto bspexit
     	end
     
     If @Status = 'Update' 
     begin
     
     	If @Datatype = 'APCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bAPCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bAPCo', i.APCo, i.APCo, @DefaultSecurityGroup
     			from dbo.bAPCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bAPCo' and s.Qualifier = i.APCo and s.Instance = i.APCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	If @Datatype = 'ARCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bARCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bARCo', i.ARCo, i.ARCo, @DefaultSecurityGroup
     			from dbo.bARCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bARCo' and s.Qualifier = i.ARCo and s.Instance = i.ARCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	If @Datatype = 'CMCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bCMCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bCMCo', i.CMCo, i.CMCo, @DefaultSecurityGroup
     			from dbo.bCMCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bCMCo' and s.Qualifier = i.CMCo and s.Instance = i.CMCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	If @Datatype = 'EMCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bEMCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bEMCo', i.EMCo, i.EMCo, @DefaultSecurityGroup
     			from dbo.bEMCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bEMCo' and s.Qualifier = i.EMCo and s.Instance = i.EMCo
     								and s.SecurityGroup = @DefaultSecurityGroup)    
     		end
     	
     	If @Datatype = 'GLCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bGLCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bGLCo', i.GLCo, i.GLCo, @DefaultSecurityGroup
     			from dbo.bGLCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bGLCo' and s.Qualifier = i.GLCo and s.Instance = i.GLCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	If @Datatype = 'HQCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bHQCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bHQCo', i.HQCo, i.HQCo, @DefaultSecurityGroup
     			from dbo.bHQCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bHQCo' and s.Qualifier = i.HQCo and s.Instance = i.HQCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	If @Datatype = 'INCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bINCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bINCo', i.INCo, i.INCo, @DefaultSecurityGroup
     			from dbo.bINCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bINCo' and s.Qualifier = i.INCo and s.Instance = i.INCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	If @Datatype = 'JCCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bJCCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bJCCo', i.JCCo, i.JCCo, @DefaultSecurityGroup
     			from dbo.bJCCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bJCCo' and s.Qualifier = i.JCCo and s.Instance = i.JCCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	If @Datatype = 'MSCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bMSCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bMSCo', i.MSCo, i.MSCo, @DefaultSecurityGroup
     			from dbo.bMSCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bMSCo' and s.Qualifier = i.MSCo and s.Instance = i.MSCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	If @Datatype = 'POCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bPOCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bPOCo', i.POCo, i.POCo, @DefaultSecurityGroup
     			from dbo.bPOCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bPOCo' and s.Qualifier = i.POCo and s.Instance = i.POCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	If @Datatype = 'PRCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bPRCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bPRCo', i.PRCo, i.PRCo, @DefaultSecurityGroup
     			from dbo.bPRCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bPRCo' and s.Qualifier = i.PRCo and s.Instance = i.PRCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	If @Datatype = 'SLCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bSLCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bSLCo', i.SLCo, i.SLCo, @DefaultSecurityGroup
     			from dbo.bSLCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bSLCo' and s.Qualifier = i.SLCo and s.Instance = i.SLCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		END
     	
     	----TK-08517
     	If @Datatype = 'SMCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bSMCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bSMCo', i.SLCo, i.SLCo, @DefaultSecurityGroup
     			from dbo.bSLCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bSMCo' and s.Qualifier = i.SLCo and s.Instance = i.SLCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		END
     	
     	If @Datatype = 'CMAcct'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bCMAcct' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bCMAcct', i.CMCo, i.CMAcct, @DefaultSecurityGroup
     			from dbo.bCMAC i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bCMAcct' and s.Qualifier = i.CMCo and s.Instance = i.CMAcct
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	
     	If @Datatype = 'Loc'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bLoc' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bLoc', i.INCo, i.Loc, @DefaultSecurityGroup
     			from dbo.bINLM i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bLoc' and s.Qualifier = i.INCo and s.Instance = i.Loc
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	
     	If @Datatype = 'HRRef'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bHRRef' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bHRRef', i.HRCo, i.HRRef, @DefaultSecurityGroup
     			from dbo.bHRRM i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bHRRef' and s.Qualifier = i.HRCo and s.Instance = i.HRRef
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	If @Datatype = 'JBCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bJBCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bJBCo', i.JBCo, i.JBCo, @DefaultSecurityGroup
     			from dbo.bJBCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bJBCo' and s.Qualifier = i.JBCo and s.Instance = i.JBCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	If @Datatype = 'HRCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bHRCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bHRCo', i.HRCo, i.HRCo, @DefaultSecurityGroup
   
     			from dbo.bHRCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'bHRCo' and s.Qualifier = i.HRCo and s.Instance = i.HRCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
     	
     	
     	If @Datatype = 'PMCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bPMCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bPMCo', i.PMCo, i.PMCo, @DefaultSecurityGroup
     			from dbo.bPMCO i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'PMCo' and s.Qualifier = i.PMCo and s.Instance = i.PMCo
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end
   
		--DC #132526
     	--If @Datatype = 'RQCo'
     	--	begin
     	--		if isnull(@OldDefaultSecurityGroup,-1)<> -1
     	--		delete dbo.vDDDS
     	--		where Datatype='bRQCo' and SecurityGroup = @OldDefaultSecurityGroup
     		
     	--		if isnull(@DefaultSecurityGroup,-1)<>-1
     	--		Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     	--		select 'bRQCo', i.RQCo, i.RQCo, @DefaultSecurityGroup
     	--		from dbo.bRQCO i with (nolock)
     	--		where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     	--							where Datatype = 'RQCo' and s.Qualifier = i.RQCo and s.Instance = i.RQCo
     	--							and s.SecurityGroup = @DefaultSecurityGroup)
     	--	end

		If @Datatype = 'Employee'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bEmployee' and SecurityGroup = @OldDefaultSecurityGroup
     		
     			if isnull(@DefaultSecurityGroup,-1)<>-1
     			Insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
     			select 'bEmployee', i.PRCo, i.Employee, @DefaultSecurityGroup
     			from dbo.bPREH i with (nolock)
     			where not exists 	(select 1 from dbo.vDDDS s with (nolock) 
     								where Datatype = 'Employee' and s.Qualifier = i.PRCo and s.Instance = convert(char(30),i.Employee)
     								and s.SecurityGroup = @DefaultSecurityGroup)
     		end    		
     end
     
     If @Status = 'Clear' 
     begin
     	If @Datatype = 'APCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bAPCo'     		
     		end
     	
     	If @Datatype = 'ARCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bARCo'      		
     		end
     	
     	If @Datatype = 'CMCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bCMCo'      		
     		end
     	
     	If @Datatype = 'EMCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bEMCo'      		
     		end
     	
     	If @Datatype = 'GLCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bGLCo'      		
     		end
     	
     	If @Datatype = 'HQCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bHQCo'      		
     		end
     	
     	If @Datatype = 'INCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bINCo'      		
     		end
     	
     	If @Datatype = 'JCCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bJCCo'     		
     		end
     	
     	If @Datatype = 'MSCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bMSCo'     		
     		end
     	
     	If @Datatype = 'POCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bPOCo'     		
     		end
     	
     	If @Datatype = 'PRCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bPRCo'      		
     		end
     	
     	If @Datatype = 'SLCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bSLCo'      		
     		END
     		
     	 ----TK-08517
         If @Datatype = 'SMCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bSMCo'      		
     		END
     		
     	If @Datatype = 'CMAcct'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bCMAcct'      		
     		end
     	     	
     	If @Datatype = 'Loc'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bLoc'      		
     		end
     	     	
     	If @Datatype = 'HRRef'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bHRRef'     		
     		end
     	
     	If @Datatype = 'JBCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bJBCo'      		
     		end
     	
     	If @Datatype = 'HRCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bHRCo'      		
     		end
     	     	
     	If @Datatype = 'PMCo'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bPMCo'      		
     		end
   
		--DC #132526
     	--If @Datatype = 'RQCo'
     	--	begin
     	--		if isnull(@OldDefaultSecurityGroup,-1)<> -1
     	--		delete dbo.vDDDS
     	--		where Datatype='bRQCo'      		
     	--	end

     	If @Datatype = 'Employee'
     		begin
     			if isnull(@OldDefaultSecurityGroup,-1)<> -1
     			delete dbo.vDDDS
     			where Datatype='bEmployee'      		
     		end
     end
          
     bspexit:     
     	return @rcode
     end
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    
   
   
   
  
 



GO
GRANT EXECUTE ON  [dbo].[vspVAUpdateSecurityGroup] TO [public]
GO
