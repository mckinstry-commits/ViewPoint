SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   procedure [dbo].[vspRPCopyReport] 
/********************************************************************************************
* Created: TRL 08/15/05
* Modified: AL 02/19/09 Issue #132336 - Removed company restriction from Security copy section
*			GG 03/5/09 - #127241 - avoid duplicates in vRPRMc and misc cleanup
*			Jacob Van Houten 6/18/09 - Fixed @formsassigned flag since it was copying when 'N'
*           HH 01/31/12 - TK-12099, extend RPRT.FileName from varchar(60) to varchar(255)
*           HH 06/04/12 - TK-15179, extend RPRT.Location from varchar(10) to varchar(50)
*    
*	Used to copy the header, parameters, module and form assignments, lookups, security, and user
*	printing preferences for a report
*
*********************************************************************************************/

(@reportid int, @newreportid int, @Title varchar(60) = Null, @Location varchar(50) = Null, 
 @FileName varchar(255) = Null, @ReportType varchar(10) = Null, @AppType varchar(30) = Null,  
 @ReportOwner varchar(60)= null, @ReportMemo varchar(256) = Null, @ReportDescription varchar(4000) = Null, 
 @ShowOnMenu varchar(1) = 'N', @IconKey varchar(20) = null, @formsassigned varchar (1) = 'N',  
 @rpmodules varchar (1) = 'N', @reportsecurity varchar (1) = 'N', @printpref varchar (1) = 'N',
 @currentcompany bCompany = 0, @msg varchar(256)= null output)

 as

set nocount on
	
declare @rcode int
select @rcode = 0

If IsNull(@reportid,0) = 0 
	Begin
	select @msg='Report ID:  ' + Convert(varchar,isnull(@reportid,0)) + ' invalid Report ID.',@rcode=1
	goto vspexit
	End

if IsNull(@newreportid,0) <=9999
	Begin
	select @msg='New Report ID:  ' + Convert(varchar,isnull(@newreportid,0)) + ' must be greater than 9,999.',@rcode=1
	goto vspexit
	End

If (select count(*) From dbo.RPRTc (nolock) Where ReportID = @newreportid) >= 1 
	Begin
	select @msg='New Report ID:  ' + Convert(varchar,isnull(@newreportid,0)) + ' already exists.',@rcode=1
	goto vspexit
	End

--Copy a standard Viewpoint Report (ReportID < 10000) to a new custom report (ReportID > 9999)
if  @reportid <= 9999 and @newreportid >= 10000 
	begin
	-- add a custom Report Title entry (vRPRTc)
	insert dbo.vRPRTc (ReportID, Title, Location, FileName, ReportType,  AppType,ShowOnMenu,ReportOwner, ReportMemo, ReportDesc,IconKey)
	select @newreportid, @Title, @Location, @FileName, @ReportType, @AppType, @ShowOnMenu, @ReportOwner, @ReportMemo, @ReportDescription,@IconKey 
	from dbo.vRPRT (nolock)
	where ReportID = @reportid
	if @@rowcount = 0 
		begin
		select @msg = 'Report Title entry could not be created for new Report ID:  ' + convert(varchar,@newreportid), @rcode = 1
		goto vspexit
		end
		
	-- add custom Report Parameter entries (vRPRPc)
	insert dbo.vRPRPc (ReportID,ParameterName,DisplaySeq,ReportDatatype,Datatype, ActiveLookup, LookupParams, LookupSeq, Description, ParameterDefault, InputType, InputMask, InputLength, Prec, ParamRequired)
	select @newreportid, ParameterName,DisplaySeq,ReportDatatype,Datatype, ActiveLookup, LookupParams, LookupSeq, Description, ParameterDefault, InputType, InputMask, InputLength, Prec, ParamRequired 
	from dbo.vRPRP (nolock)
	where ReportID = @reportid
		
	-- add custom Report Parameter Lookups (vRPPLc)
	insert dbo.vRPPLc (ReportID,ParameterName,Lookup,LookupParams,LoadSeq,Active)
	select @newreportid, ParameterName,Lookup,LookupParams,LoadSeq,'Y' 
	from dbo.vRPPL (nolock)
	where ReportID = @reportid
	 
	-- Copy Form Report assignments
	if @formsassigned = 'Y' 
		begin
		-- add custom Form Report entries (vRPFRc)
		insert dbo.vRPFRc (ReportID, Form,Active)
		select @newreportid, Form, 'Y' 
		from dbo.vRPFR (nolock)
		where ReportID = @reportid
			
		-- add custom Form Report Defaults (vRPFDc)
		insert dbo.vRPFDc (ReportID, Form, ParameterName, ParameterDefault)
		select @newreportid, Form, ParameterName, ParameterDefault 
		from dbo.vRPFD (nolock)
		where ReportID = @reportid
		end
			
	-- Copy custom Report Module assignments (vRPRMc)
	if @rpmodules  = 'Y' 
		begin
		-- add custom Report Module assignments (vRPRMc)
		insert dbo.vRPRMc (ReportID,Mod,MenuSeq,Active)
		select @newreportid, m.Mod, m.MenuSeq, 'Y' 
		from dbo.vRPRM m (nolock)
		where m.ReportID = @reportid and m.Mod <> 'DD'
			and not exists(select top 1 1 from dbo.vRPRMc c
			where c.ReportID = @newreportid and c.Mod = m.Mod) -- #127241 avoid existing entries in vRPRMc 
		end
	end

--Copy a custom report to an new custom report
if  @reportid >= 10000 and @newreportid >= 10000 
	begin
	-- add a custom Report Title entry (vRPRTc)
	insert dbo.vRPRTc (ReportID, Title, Location, FileName, ReportType,  AppType,ShowOnMenu,ReportOwner, ReportMemo, ReportDesc,IconKey)
	select @newreportid, @Title, @Location, @FileName, @ReportType, @AppType, @ShowOnMenu, @ReportOwner, @ReportMemo, @ReportDescription, @IconKey
	from dbo.RPRTc (nolock)
	where ReportID = @reportid
	if @@rowcount = 0 
		begin
		select @msg = 'Report Title entry could not be created for new Report ID:  ' + convert(varchar,@newreportid), @rcode = 1
		goto vspexit
		end

	-- add custom Report Parameter entries (vRPRPc)
	insert dbo.vRPRPc (ReportID,ParameterName,DisplaySeq,ReportDatatype,Datatype, ActiveLookup, LookupParams, LookupSeq, Description, ParameterDefault, InputType, InputMask, InputLength, Prec, ParamRequired)
	select @newreportid, ParameterName,DisplaySeq,ReportDatatype,Datatype, ActiveLookup, LookupParams, LookupSeq, Description, ParameterDefault, InputType, InputMask, InputLength, Prec, ParamRequired
	from dbo.vRPRPc (nolock)
	where ReportID = @reportid
	
	-- add custom Report Parameter Lookups (vRPPLc)
	insert dbo.vRPPLc (ReportID,ParameterName,Lookup,LookupParams,LoadSeq,Active)
	select @newreportid, ParameterName,Lookup,LookupParams,LoadSeq,Active 
	from dbo.vRPPLc (nolock)
	where ReportID = @reportid
	
	-- Copy Form Report assignments
	if @formsassigned = 'Y' 
		begin
		-- add custom Form Report entries (vRPFRc)			
		insert dbo.vRPFRc (ReportID,Form,Active)
		select @newreportid, Form, Active
		from dbo.vRPFRc (nolock)
		where ReportID = @reportid
		
		-- add custom Form Report Defaults (vRPFDc)
		insert dbo.vRPFDc (ReportID,Form,ParameterName,ParameterDefault)
		select @newreportid, Form,ParameterName,ParameterDefault 
		from dbo.vRPFDc (nolock)
		where ReportID = @reportid
		end
			
	-- Copy custom Report Module assignments (vRPRMc)						
	If @rpmodules  = 'Y' 
		begin
		-- add custom Report Module assignments (vRPRMc)
		insert dbo.vRPRMc (ReportID,Mod,MenuSeq,Active)
		select @newreportid, m.Mod, m.MenuSeq, 'Y' 
		from dbo.vRPRMc m (nolock)
		where m.ReportID = @reportid and m.Mod <> 'DD'
			and not exists(select top 1 1 from dbo.vRPRMc c
			where c.ReportID = @newreportid and c.Mod = m.Mod) -- #127241 avoid existing entries in vRPRMc 
		end
	end		

--RPRS Report Security
If @reportsecurity = 'Y'  
	Begin
	--Delete any existing records (cleanup)
	Delete dbo.vRPRS Where ReportID = @newreportid --and Co = @currentcompany (removed for issue #132336) 

	Insert dbo.vRPRS (Co, ReportID, SecurityGroup, VPUserName, Access)      
	Select Co, @newreportid,SecurityGroup,VPUserName,Access  
	From dbo.vRPRS (nolock)
	Where ReportID = @reportid --and Co = @currentcompany (removed for issue #132336)  
	End

--RPUP, User Preferences
If @printpref = 'Y'
	Begin
	--Delete any existing records (cleanup)
	Delete dbo.vRPUP Where ReportID = @newreportid
	
	--Insert New Record
	Insert dbo.vRPUP (VPUserName, ReportID, PrinterName, PaperSource, PaperSize, Duplex, Orientation, LastAccessed)
	Select VPUserName, @newreportid, PrinterName, PaperSource, PaperSize, Duplex, Orientation, null
	From dbo.vRPUP (nolock) Where ReportID = @reportid
	End

vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspRPCopyReport] TO [public]
GO
