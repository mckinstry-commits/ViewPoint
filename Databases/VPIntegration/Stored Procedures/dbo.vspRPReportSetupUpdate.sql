SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspRPReportSetupUpdate]
 /*****************************************************************************
   * Created By: TRL 03/16/06
   *
   * Used in RPViewpointTitles to copy VP standard report informatin to customer tables
   *
   * Pass:
   *  Report ID  ( 1 to 9999)
   *  Update Option   
   *  Report Setup Option
   *  Form
   *  ParameterName
   *  Mod
   *  Lookup
   *  DisplaySeq
   *  Description
   *  DefaultParameter
   *  LookupParams
   *  LoadSeq
   *  ActiveLookup
   *  Active
   *  MenuSeq
   *  msg
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   *******************************************************************************/
(@reportid int = 0, @reportsetupoption varchar(2) = null, 
@form varchar(30) = null, @parametername varchar(30)= null, @mod varchar(2)=null, @lookup varchar(30) =null,
@displayseq tinyint = null,@description varchar(256) = null,@parameterdefault varchar(60) = null,@lookupparams varchar(30) = null,
@lookupseq int = null, @loadseq int = null,@activelookup varchar(1)= 'Y',@active varchar (1) = 'Y', @menuseq int =null, @msg varchar(256) = null output)

as 

Declare @rcode int

Select @rcode = 0

if IsNull(@reportid ,0) = 0
	Begin
		Select @msg = 'Missing Report ID!', @rcode = 1
		goto vspexit	
	End 

If @reportid > 9999 
	Begin
		Select @msg = 'Report ID: ' + convert(varchar,Isnull(@reportid,0)) + ' is not a Viewpoint Standard Report!', @rcode = 1
		goto vspexit	
	End 

If IsNull(@reportsetupoption,'') =''
	Begin
		Select @msg = 'No Report Setup Item selected!', @rcode = 1
		goto vspexit	
	End 

If @reportsetupoption = 'P' or @reportsetupoption = 'L' 
	Begin
		If IsNull(@parametername,'') =''
			Begin
				Select @msg = 'Missing  Parameter Name!', @rcode = 1
				goto vspexit	
			End
	 End

If @reportsetupoption = 'L'
	Begin
		If IsNull(@lookup,'') =''
			Begin
				Select @msg = 'Missing Lookup!', @rcode = 1
				goto vspexit	
			End
	End

If @reportsetupoption = 'F' or @reportsetupoption = 'FD'
	Begin
		If IsNull(@form,'') =''
		Begin
			Select @msg = 'Missing Form!', @rcode = 1 
			goto vspexit	
		End
	End

If @reportsetupoption = 'M'
	Begin
		If IsNull(@mod,'') =''
			Begin
				Select @msg = 'Missing Module !', @rcode = 1
				goto vspexit	
			End
	  End

--RPRPc
If @reportsetupoption = 'P'
	Begin
		If (select count(*) from dbo.vRPRPc where ReportID=@reportid and ParameterName=@parametername)=0
			Begin
				--Insert
				Insert into dbo.RPRPc (ReportID, ParameterName,DisplaySeq, ReportDatatype,Description,ParameterDefault, LookupParams,LookupSeq,ActiveLookup)
				Select ReportID,ParameterName,IsNull(@displayseq,RPRP.DisplaySeq), RPRP.ReportDatatype,@description,@parameterdefault,
					@lookupparams,case when @lookupseq = 0 then null else @lookupseq end,IsNull(@activelookup,'N')
				From dbo.RPRP 
				Where ReportID = @reportid and ParameterName = @parametername
				If @@rowcount = 0 
				Begin
					select @msg = 'Report ID: ' + convert(varchar,Isnull(@reportid,0)) + ' and Parameter: ' + @parametername + ' did not insert!',@rcode = 1 
					goto vspexit
				End
			End
		Else
		--Delete record with no overrides
			If IsNull(@displayseq,0)=0 and @description = null and @parameterdefault = null and @lookupparams = null and 
			IsNull(@lookupseq,0)=0 and IsNull(@loadseq,0)=0 and @activelookup='N' 
				Begin
					Delete From RPRPc Where ReportID = @reportid and ParameterName=@parametername
					goto vspexit
				End
			Else
				--Update
				Begin
					Update dbo.RPRPc
					Set DisplaySeq=IsNull(@displayseq,RPRP.DisplaySeq), Description=@description,ParameterDefault=@parameterdefault,LookupParams=@lookupparams, 
					LookupSeq=case when @lookupseq = 0 then null else @lookupseq end, ActiveLookup=IsNull(@activelookup,RPRP.ActiveLookup)
					From dbo.RPRPc
					Left Join dbo.RPRP with(nolock) on RPRP.ReportID=RPRPc.ReportID and RPRP.ParameterName = RPRPc.ParameterName
					Where RPRPc.ReportID=@reportid and RPRPc.ParameterName=@parametername
					If @@rowcount = 0 
						Begin
							select @msg = 'Report ID: ' + convert(varchar,Isnull(@reportid,0)) + ' and Parameter: ' + @parametername + ' did not update!',@rcode = 1 
							goto vspexit
						End
				End
		End

--RPPLc
If @reportsetupoption = 'L'
	Begin
		If (select count(*) from dbo.vRPPLc where ReportID=@reportid and ParameterName=@parametername and Lookup = @lookup)=0
			Begin
				--Insert
				Insert into dbo.RPPLc (ReportID, ParameterName, Lookup, LookupParams,LoadSeq,Active)
				Select ReportID,ParameterName, @lookup, @lookupparams, case when @loadseq = 0 then null else @loadseq end ,IsNull(@active,'N')
				From dbo.RPPL 
				Where ReportID = @reportid and ParameterName = @parametername and Lookup=@lookup
				If @@rowcount = 0 
					Begin
						select @msg = 'Report ID: ' + convert(varchar,Isnull(@reportid,0)) + ' and Parameter: ' + @parametername + ' Lookup:  '+ @lookup + ' did not insert!',@rcode = 1 
						goto vspexit
					End
			End
		Else
			--Delete record with no overrides
			If @lookup is null and  @lookupparams is null and  IsNull(@loadseq,0)=0 and IsNull(@active,'N') = 'N'
				Begin
					Delete from RPPLc Where RPPLc.ReportID=@reportid and RPPLc.ParameterName=@parametername and RPPLc.Lookup = @lookup
					goto vspexit
				End 
			else
				--Update
				Begin
					Update dbo.RPPLc
					Set Lookup=@lookup, LookupParams=@lookupparams, LoadSeq=case when @loadseq = 0 then null else @loadseq end ,Active=IsNull (@active,'N')
					From dbo.RPPLc
					Where RPPLc.ReportID=@reportid and RPPLc.ParameterName=@parametername and RPPLc.Lookup = @lookup
					If @@rowcount = 0 
						Begin
							select @msg = 'Report ID: ' + convert(varchar,Isnull(@reportid,0)) + ' and Parameter: ' + @parametername + ' Lookup:  '+ @lookup + ' did not update!',@rcode = 1 
							goto vspexit
						End
				End
	End
	
--RPFRc
If @reportsetupoption = 'F'
	Begin
		If (select count(*) from dbo.vRPFRc where ReportID=@reportid and Form=@form)=0 
			Begin
				--Insert
				Insert into dbo.RPFRc (ReportID,Form,Active)
				Select ReportID,Form, @active
				From dbo.RPFR 
				Where ReportID= @reportid and Form = @form
				If @@rowcount = 0 
					Begin
						select @msg = 'Report ID: ' + convert(varchar,Isnull(@reportid,0)) + ' and Form: ' + @form + ' did not insert!',@rcode = 1 
						goto vspexit
					End
			End
		else
			Begin
				--Update
				Update dbo.RPFRc
				Set Active = IsNull(@active,'N')
				From dbo.RPFRc
				Where RPFRc.ReportID=@reportid and RPFRc.Form=@form
				If @@rowcount = 0 
					Begin
						select @msg = 'Report ID: ' + convert(varchar,Isnull(@reportid,0)) + ' and Form: ' + @form + ' did not update!',@rcode = 1 
						goto vspexit
					End
				End
		End

--RPFDc
If @reportsetupoption = 'FD'
	Begin
		--Insert
		If @parameterdefault is not null and (select count(*) from dbo.vRPFDc where ReportID=@reportid and Form=@form and ParameterName = @parametername)=0  
			Begin
				Insert into dbo.RPFDc (ReportID,Form,ParameterName,ParameterDefault) 
				Select ReportID,Form,ParameterName,@parameterdefault 
				From dbo.RPFD 
				Where ReportID = @reportid and Form=@form and ParameterName = @parametername 
				If @@rowcount = 0 
					Begin
						select @msg = 'Report ID: ' + convert(varchar,Isnull(@reportid,0)) + ' and Form: ' + @form +' and Parameter: ' + @parametername + ' did not insert!',@rcode = 1 
						goto vspexit
					End
			End
	    Else
			--Delete records with no parameter values
			If @parameterdefault is null 		
				Begin
					Delete From RPFDc	Where RPFDc.ReportID=@reportid and RPFDc.Form=@form and RPFDc.ParameterName = @parametername
					goto vspexit
				End
			else
				--Update
				Begin
					Update dbo.vRPFDc
					Set ParameterDefault = @parameterdefault
					From dbo.RPFDc
					Where RPFDc.ReportID=@reportid and RPFDc.Form=@form and RPFDc.ParameterName = @parametername
					If @@rowcount = 0 
						Begin
							select @msg = 'Report ID: ' + convert(varchar,Isnull(@reportid,0)) + ' and Form: ' + @form +' and Parameter: ' + @parametername + ' did not update!',@rcode = 1 
							goto vspexit
						End
				End
		End

--RPRMc
If @reportsetupoption = 'M'
	Begin
		If (select count(*) from dbo.vRPRMc where ReportID=@reportid and Mod=@mod )=0
			Begin
				--Insert
				Insert into dbo.RPRMc (ReportID,Mod, MenuSeq,Active)
				Select ReportID,Mod, case when @menuseq = 0 then null else @menuseq end, @active 
				From dbo.RPRM 
				Where ReportID=@reportid and Mod=@mod
				If @@rowcount = 0 
					Begin
						select @msg = 'Report ID: ' + convert(varchar,Isnull(@reportid,0)) + ' and Module: ' + @mod + ' did not update!', @rcode = 1 
						goto vspexit
					End
			End
		Else 
			--Update
			Begin
				Update dbo.vRPRMc
				Set MenuSeq=case when @menuseq=0 then null else @menuseq end, Active=IsNull(@active,'N')
				From dbo.RPRMc
				Where RPRMc.ReportID=@reportid and RPRMc.Mod=@mod 
				If @@rowcount = 0 
					Begin
						select @msg = 'Report ID: ' + convert(varchar,Isnull(@reportid,0)) + ' and Module: ' + @mod + ' did not update!', @rcode = 1 
						goto vspexit
					End
		 	End
	End

vspexit:
	if @rcode <> 0 
	select @msg = @msg +char(13) +char(10) + '[vspRPReportSetupUpdate]'
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspRPReportSetupUpdate] TO [public]
GO
