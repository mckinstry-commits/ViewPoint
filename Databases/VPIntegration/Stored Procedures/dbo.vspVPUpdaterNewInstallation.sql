SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[vspVPUpdaterNewInstallation]
/********************************
* Created: DANF 08/21/07
* Modified: DANF 11/12/07
*
* Used by the server update process to replace standard Data Dictionary and Report data.
*
* Input: 
*
* Output:
*	@msg		
*
* Return code:
*
*
*********************************/
(@sourcedb varchar(30) = null, @destdb varchar(30) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @tsql varchar(max), @quote char(1)
select @rcode = 0
set @quote = char(39)

--New Installations statements

-- populate datatype custom table.
begin try
	
	select @tsql = 'INSERT INTO ' + @destdb + 'dbo.vDDDTc (Datatype, InputMask, InputLength, Prec, Secure, DfltSecurityGroup, Label, InputType) '
	select @tsql = @tsql + ' select d.Datatype, d.InputMask, d.InputLength, d.Prec, ' + @quote + 'N' + @quote + ', null, null, d.InputType from ' + @sourcedb + '.dbo.vDDDT d (nolock) left join ' + @destdb + '.dbo.vDDDTc on c.Datatype = d.Datatype'
	select @tsql = @tsql + ' where c.Datatype is null)'

	exec(@tsql)
end try
begin catch
	select @msg = 'Error inserting custom data types into vDDDTc.', @rcode = 1
	exec dbo.vspV6ConvLogSQLErrors @msg 
end catch


-- correct logins
begin try
	
	select @tsql = ' use ' + @destdb + '; exec sp_change_users_login ' + @quote + 'AUTO_FIX' + @quote + ',' + @quote + 'viewpointcs' + @quote 
	exec(@tsql)
end try
begin catch
	select @msg = 'Error correcting viewpoint cs login', @rcode = 1
	exec dbo.vspV6ConvLogSQLErrors @msg 
end catch

begin try
	select @tsql = ' use ' + @destdb + '; GRANT VIEW DEFINITION TO [public]' 
	exec(@tsql)
end try
begin catch
	select @msg = 'Error granting view definition to public', @rcode = 1
	exec dbo.vspV6ConvLogSQLErrors @msg 
end catch

begin try
	select @tsql = ' use ' + @destdb + '; EXEC sp_dbcmptlevel ' + @quote + 'Viewpoint' + @quote + ', 90' 
	exec(@tsql)
end try
begin catch
	select @msg = 'Set Destination Compatability level', @rcode = 1
	exec dbo.vspV6ConvLogSQLErrors @msg 
end catch

begin try
	select @tsql = ' use ' + @destdb + ';exec sp_change_users_login '+ @quote + 'AUTO_FIX'+ @quote + ','+ @quote + 'VCSPortal'+ @quote 
	exec(@tsql)
end try
begin catch
	select @msg = 'fixing the vcsportal login', @rcode = 1
	exec dbo.vspV6ConvLogSQLErrors @msg 
end catch
---
begin try
	select @tsql = ' use ' + @destdb + ';exec sp_change_users_login '+ @quote + 'AUTO_FIX'+ @quote + ','+ @quote + 'vcspublic'+ @quote
	exec(@tsql)
end try
begin catch
	select @msg = 'fixing the vcspublic login', @rcode = 1
	exec dbo.vspV6ConvLogSQLErrors @msg 
end catch

begin try
	select @tsql = ' use ' + @destdb + ';exec sp_change_users_login '+ @quote + 'AUTO_FIX'+ @quote + ','+ @quote + 'newuser'+ @quote
	exec(@tsql)
end try
begin catch
	select @msg = 'error adding the newuser login', @rcode = 1
	exec dbo.vspV6ConvLogSQLErrors @msg 
end catch

-- 
begin try
	select @tsql = ' use ' + @destdb + ';if not exists (select top 1 1 from sys.syslogins where name = '+ @quote + 'VCSPortal'+ @quote + ') CREATE LOGIN [VCSPortal] WITH PASSWORD = '+ @quote + 'pass+word'+ @quote + ', CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;' 
	exec(@tsql)
end try
begin catch
	select @msg = 'error adding the viewpointcs login', @rcode = 1
	exec dbo.vspV6ConvLogSQLErrors @msg 
end catch
 
 
begin try
	select @tsql = 'exec sp_addrolemember N' + @quote + 'db_owner' + @quote + ', N'+ @quote + 'viewpointcs' + @quote
	exec(@tsql)
end try
begin catch
	select @msg = 'error adding the viewpointcs as dbo', @rcode = 1
	exec dbo.vspV6ConvLogSQLErrors @msg 
end catch
          
 
/*	no longer needed as we attach a copy of the production database instead of 
	running the update process.
INSERT Viewpoint.dbo.bHQGP (Grp, Description, Notes)
select Grp, Description, Notes from VPProdV6.dbo.bHQGP
where Grp not in (select Grp from Viewpoint.dbo.bHQGP)

INSERT Viewpoint.dbo.bHQST (State, Name, W2Name, Notes)
select State, Name, W2Name, Notes from VPProdV6.dbo.bHQST
where State not in (select State from Viewpoint.dbo.bHQST)

INSERT Viewpoint.dbo.bHQUM (UM, Description, Notes)
select UM, Description, Notes from VPProdV6.dbo.bHQUM
where UM not in (select UM from Viewpoint.dbo.bHQUM)

alter table Viewpoint.dbo.bHQWD disable trigger all
INSERT Viewpoint.dbo.bHQWD (TemplateName, Location, TemplateType, FileName, Active, UsedLast, UsedBy, Notes, WordTable, SuppressZeros, SuppressNotes, SubmitType, StdObject)
select TemplateName, Location, TemplateType, FileName, Active, UsedLast, UsedBy, Notes, WordTable, SuppressZeros, SuppressNotes, SubmitType, StdObject from VPProdV6.dbo.bHQWD
where TemplateName not in (select TemplateName from Viewpoint.dbo.bHQWD)
alter table Viewpoint.dbo.bHQWD enable trigger all

alter table Viewpoint.dbo.bHQWF disable trigger all
INSERT Viewpoint.dbo.bHQWF (TemplateName, Seq, DocObject, ColumnName, MergeFieldName, MergeOrder, WordTableYN, Format)
select TemplateName, Seq, DocObject, ColumnName, MergeFieldName, MergeOrder, WordTableYN, Format from VPProdV6.dbo.bHQWF
alter table Viewpoint.dbo.bHQWF enable trigger all

alter table Viewpoint.dbo.bHQWO disable trigger all
INSERT Viewpoint.dbo.bHQWO (TemplateType, DocObject, LinkedDocObject, ObjectTable, Required, JoinOrder, Alias, JoinClause, Notes, WordTable, StdObject)
select TemplateType, DocObject, LinkedDocObject, ObjectTable, Required, JoinOrder, Alias, JoinClause, Notes, WordTable, StdObject from VPProdV6.dbo.bHQWO
alter table Viewpoint.dbo.bHQWO enable trigger all

alter table Viewpoint.dbo.bHQWT disable trigger all
INSERT Viewpoint.dbo.bHQWT (TemplateType, Description, Notes, WordTable)
select TemplateType, Description, Notes, WordTable from VPProdV6.dbo.bHQWT
alter table Viewpoint.dbo.bHQWT enable trigger all

INSERT Viewpoint.dbo.bHRCT(Type, Description)
select Type, Description from VPProdV6.dbo.bHRCT
where Type not in (select Type from Viewpoint.dbo.bHRCT)

alter table Viewpoint.dbo.bIMTD disable trigger all
INSERT Viewpoint.dbo.bIMTD (ImportTemplate, RecordType, Seq, Identifier, DefaultValue, ColDesc, FormatInfo, Required, XRefName, RecColumn, BegPos, EndPos, BidtekDefault, Datatype, UserDefault, OverrideYN, UpdateKeyYN, UpdateValueYN, ImportPromptYN, XMLTag)
select ImportTemplate, RecordType, Seq, Identifier, DefaultValue, ColDesc, FormatInfo, Required, XRefName, RecColumn, BegPos, EndPos, BidtekDefault, Datatype, UserDefault, OverrideYN, UpdateKeyYN, UpdateValueYN, ImportPromptYN, XMLTag from VPProdV6.dbo.bIMTD
alter table Viewpoint.dbo.bIMTD enable trigger all

alter table Viewpoint.dbo.bIMTH disable trigger all
INSERT Viewpoint.dbo.bIMTH (ImportTemplate, Description, UploadRoutine, BidtekRoutine, Form, MultipleTable, FileType, Delimiter, OtherDelim, TextQualifier, LastImport, SampleFile, RecordTypeCol, BegPos, EndPos, ImportRoutine, UserRoutine, DirectType, XMLRowTag)
select ImportTemplate, Description, UploadRoutine, BidtekRoutine, Form, MultipleTable, FileType, Delimiter, OtherDelim, TextQualifier, LastImport, SampleFile, RecordTypeCol, BegPos, EndPos, ImportRoutine, UserRoutine, DirectType, XMLRowTag from VPProdV6.dbo.bIMTH
alter table Viewpoint.dbo.bIMTH enable trigger all

alter table Viewpoint.dbo.bIMTR disable trigger all
INSERT Viewpoint.dbo.bIMTR (ImportTemplate, RecordType, Form, Description, Skip)
select ImportTemplate, RecordType, Form, Description, Skip from VPProdV6.dbo.bIMTR
alter table Viewpoint.dbo.bIMTR enable trigger all

alter table Viewpoint.dbo.bIMXD enable trigger all
INSERT Viewpoint.dbo.bIMXD (ImportTemplate, XRefName, ImportValue, BidtekGroup, BidtekValue, RecordType)
select ImportTemplate, XRefName, ImportValue, BidtekGroup, BidtekValue, RecordType from VPProdV6.dbo.bIMXD
alter table Viewpoint.dbo.bIMTD enable trigger all

alter table Viewpoint.dbo.bIMXF enable trigger all
INSERT Viewpoint.dbo.bIMXF (ImportTemplate, XRefName, ImportField, RecordType)
select ImportTemplate, XRefName, ImportField, RecordType from VPProdV6.dbo.bIMXF
alter table Viewpoint.dbo.bIMXF enable trigger all

INSERT Viewpoint.dbo.bIMXH (ImportTemplate, XRefName, RecordType, Identifier, PMCrossReference, PMTemplate)
select ImportTemplate, XRefName, RecordType, Identifier, PMCrossReference, PMTemplate from VPProdV6.dbo.bIMXH

INSERT Viewpoint.dbo.bJBTM (JBCo, Template, Description, SortOrder, LaborRateOpt, LaborOverrideYN, EquipRateOpt, LaborCatYN, EquipCatYN, MatlCatYN, Notes, CopyInProgress, LaborEffectiveDate, EquipEffectiveDate, MatlEffectiveDate)
select JBCo, Template, Description, SortOrder, LaborRateOpt, LaborOverrideYN, EquipRateOpt, LaborCatYN, EquipCatYN, MatlCatYN, Notes, CopyInProgress, LaborEffectiveDate, EquipEffectiveDate, MatlEffectiveDate from VPProdV6.dbo.bJBTM

alter table Viewpoint.dbo.bJBTS disable trigger all
INSERT Viewpoint.dbo.bJBTS (JBCo, Template, Seq, Type, GroupNum, Description, APYN, EMYN, INYN, JCYN, MSYN, PRYN, Category, SummaryOpt, SortLevel, EarnLiabTypeOpt, LiabilityType, EarnType, CustGroup, MiscDistCode, PriceOpt, MarkupOpt, MarkupRate, FlatAmtOpt, AddonAmt, Notes, ContractItem)
select JBCo, Template, Seq, Type, GroupNum, Description, APYN, EMYN, INYN, JCYN, MSYN, PRYN, Category, SummaryOpt, SortLevel, EarnLiabTypeOpt, LiabilityType, EarnType, CustGroup, MiscDistCode, PriceOpt, MarkupOpt, MarkupRate, FlatAmtOpt, AddonAmt, Notes, ContractItem from VPProdV6.dbo.bJBTS
alter table Viewpoint.dbo.bJBTS enable trigger all

INSERT Viewpoint.dbo.bPMUI (ImportRoutine, Description, FileType, Delimiter, OtherDelim, TextQualifier, ScheduleOfValues, StandardItemCode, RecordTypeCol, BegRecTypePos, EndRecTypePos, XMLRowTag)
select ImportRoutine, Description, FileType, Delimiter, OtherDelim, TextQualifier, ScheduleOfValues, StandardItemCode, RecordTypeCol, BegRecTypePos, EndRecTypePos, XMLRowTag from VPProdV6.dbo.bPMUI

INSERT Viewpoint.dbo.bWDJB (JobName, Description, QueryName, Enable, WDCo, FirstRun, LastRun, Occurs, mDay, Freq, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday, DailyInt, HourMinute, StartTime, EndTime, StartDate, EndDate, EmailTo, EmailCC, EmailSubject, EmailBody, WeekTotal, BCC, Notes)
select JobName, Description, QueryName, Enable, WDCo, FirstRun, LastRun, Occurs, mDay, Freq, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday, DailyInt, HourMinute, StartTime, EndTime, StartDate, EndDate, EmailTo, EmailCC, EmailSubject, EmailBody, WeekTotal, BCC, Notes from VPProdV6.dbo.bWDJB

INSERT Viewpoint.dbo.bWDJP (JobName, Param, Description, InputValue, QueryName)
select JobName, Param, Description, InputValue, QueryName from VPProdV6.dbo.bWDJP

INSERT Viewpoint.dbo.vRPRL (Location, Path, LocType)
select Location, RTrim(Path), LocType from VPProdV6.dbo.vRPRL
*/

vsperror: -- problems with update
	select @msg = 'Error during new installation update, Check Log DDAL for details.'
	select @rcode = 1
		

vspexit:
	return
GO
GRANT EXECUTE ON  [dbo].[vspVPUpdaterNewInstallation] TO [public]
GO
